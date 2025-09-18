import types
import sets
import intbrg
import strformat
import sequtils
import tables
import strutils
import options
import deques
from randomUtils import InitRNGs, Rand
from interactions/chooseTargets import chooseTargetsRNGinitializer
from interactions/recommendation import recommendationRNGinitializer
from interactions/relaxDissonance import relaxDissonanceRNGinitializer

InitRNGs()
# var rngs: seq[Rand]  # To avoid compile error

let rngAccessor = Agent(id: Id(0))

proc generateBeliefRandomly(atoms: int): Formulae =
  let models = 1 shl atoms
  rngAccessor.rand(1, (1 shl models) - 1).toBin(models).toFormula

proc generateOpinionRandomly(ub: int = 10000): Opinion =
  let num = rngAccessor.rand(0, ub)
  newDecimal(num) / newDecimal(ub)

proc generateValuesRandomly(agents: int, atoms: int): Table[Id, CulturalValues] =
  let models = 1 shl atoms
  let ub = 100000
  let values = (0..<models).toSeq.mapIt(rngAccessor.rand(0, ub) // ub)
  (0..<agents).toSeq.mapIt((Id(it), values)).toTable

proc getWCCs(network: Table[Id, HashSet[Id]]): seq[HashSet[Id]] =
  ## Return weakly connected components.

  # Make the network underected one at first.
  var undirected = network
  for u in network.keys:
    for v in network[u]:
      undirected[v].incl(u)
  
  var nodes = network.keys.toSeq.toHashSet
  var components: seq[HashSet[Id]]
  
  while nodes.len > 0:
    # Search weakly connected component
    var startFrom = nodes.toSeq.min
    var component = @[startFrom].toHashSet
    var q = @[startFrom].toDeque
    nodes.excl(startFrom)

    while q.len > 0:
      let now = q.popFirst
      component.incl(now)
      for next in undirected[now]:
        if nodes.contains(next):
          q.addLast(next)
          nodes.excl(next)

    components.add(component)

  return components

proc makeNetworkConnected(network: Table[Id, HashSet[Id]], components: seq[HashSet[Id]]): Table[Id, HashSet[Id]] =
  ## Make the given network connected.
  ## This can be achieved by 1) finding the node(s) with maximal out-degrees, 2) removing one edge from the node,
  ## 3) and add it to another node in different component.
  var connected = network
  var mergedTo = newSeqWith(components.len, false)
  let largestComponentMembers = (0..<components.len).toSeq.mapIt(components[it].len).max
  let largestComponentIdx = (0..<components.len).toSeq.filterIt(components[it].len == largestComponentMembers)[0]
  mergedTo[largestComponentIdx] = true

  for idx, component in components:
    if idx == largestCOmponentIdx:
      continue
    let maxOutDeg = components[largestComponentIdx].toSeq.mapIt(connected[it].len).max
    let maxOutDegNodes = components[largestComponentIdx].toSeq.filterIt(connected[it].len == maxOutDeg)
    block addConnection:
      for u in maxOutDegNodes:
        for removed in network[u].toSeq.filterIt(not components[largestComponentIdx].contains(it)):
          connected[u].excl(removed)
          let added = rngAccessor.choose(component.toSeq)
          connected[u].incl(added.get)
          break addConnection
  return connected

proc generateRandomGraph(agents: int, edges: int, connected: bool): Table[Id, HashSet[Id]] = 
  var network = initTable[Id, HashSet[Id]]()

  # Add edges (a, b) for all agent a
  for i in 0..<agents:
    while true:
      let next = rngAccessor.rand(0, agents - 1)
      if next == i:
        continue
      network[Id(i)] = [Id(next)].toHashSet
      break
  
  # Add the rest of the edges
  var existingEdges = agents
  while existingEdges < edges:
    let u = Id(rngAccessor.rand(0, agents - 1))
    let v = Id(rngAccessor.rand(0, agents - 1))
    if u == v:
      continue
    if network[u].contains(v):
      continue
    existingEdges += 1
    network[u].incl(v)

  if connected:
    let components = getWCCs(network)
    if components.len == 1:
      return network
    else:
      return makeNetworkConnected(network, components)
  else:
    return network

proc findAgentWithNoNeighbors(network: Table[Id, HashSet[Id]]): Option[Id] =
  for agent in network.keys:
    if network[agent].len == 0:
      return some(agent)
  return none(Id)

proc findAgentWithMaxNeighbors(network: Table[Id, HashSet[Id]]): Id =
  var maxNeighbors = 0
  for agent in network.keys:
    if network[agent].len > maxNeighbors:
      result = agent
      maxNeighbors = network[agent].len

proc generateRandomGraphWithLowerMaxOutDegree(agents: int, edges: int, connected: bool): Table[Id, HashSet[Id]] =
  var count = 0
  var network = initTable[Id, HashSet[Id]]()

  for a in 0..<agents:
    network[Id(a)] = initHashSet[Id]()
  
  # Generate all edges randomly
  while count < edges:
    let u = Id(rngAccessor.rand(0, agents - 1))
    let v = Id(rngAccessor.rand(0, agents - 1))
    if u == v:
      continue
    if network[u].contains(v):
      continue
    network[u].incl(v)
    count += 1
  
  # Choose one edge with maximal neighbors, remove one, and 
  # add one neighbor to agents with no neighbors
  # until all agents have at least one neighbor
  while true:
    let agentWithNoNeighborsOption = network.findAgentWithNoNeighbors()
    if agentWithNoNeighborsOption.isNone():
      break

    let agentWithNoNeighbors = agentWithNoNeighborsOption.get()
    let agentWithMaxNeighbors = network.findAgentWithMaxNeighbors()
    let removed = rngAccessor.choose(network[agentWithMaxNeighbors].toSeq).get()
    let candidates = (0..<agents).toSeq.filterIt(Id(it) != agentWithNoNeighbors)
    let added = Id(rngAccessor.choose(candidates).get())
    network[agentWithMaxNeighbors].excl(removed)
    network[agentWithNoNeighbors].incl(added)

  if connected:
    let components = getWCCs(network)
    if components.len == 1:
      return network
    else:
      return makeNetworkConnected(network, components)
  else:
    return network

proc generateInitialGraph(agents: int, edges: int, networkType: InitNetworkConfig, connected: bool): Table[Id, HashSet[Id]] =
  case networkType
  of InitNetworkConfig.random:
    return generateRandomGraph(agents, edges, connected)
  of InitNetworkConfig.randomLowerMOD:
    return generateRandomGraphWithLowerMaxOutDegree(agents, edges, connected)

proc generateFollowFrom(agents: seq[Agent]): seq[Id] =
  ## Returns sequence of the agents corresponding to the network they form.
  ## It is sorted in ascending order by agents' id.
  ## If an agent follow N other agents, its id appears N times.
  ## 
  ## For example, let $G=(V,E)$ where $V=\{1,2,3\}$ and 
  ## $E=\{(1,2),(1,3),(2,3)\}$. Then, this procedure returns the sequence
  ## `@[1,1,2]` because agent 1 follows two other agents, etc.
  result = @[]
  var idx = 0
  for agent in agents:
    if agent.neighbors.len == 0:
      raise newException(
        SOBADefect,
        fmt"Agent {agent.id} has no neighbors (should have at least one)"
      )
    for neighbor in agent.neighbors:
      result.add(agent.id)
      idx += 1
  if not result.allIt(it.int >= 0):
    raise newException(
      SOBADefect,
      fmt"Agent id should be non-negative"
    )

proc fillOptions(options: CommandLineArgs): CommandLineArgs =
  result = options
  let allAgents = (0..<options.n).toSeq.mapIt(Id(it))

  # To allow users to perform pairwise experiments,
  # initial attributes (e.g., opinions) are always generated randomly.
  # If the command line args specify (some of) them,
  # randomly-generated ones are simply ignored.

  # Beliefs
  for a in allAgents:
    let candidate = generateBeliefRandomly(options.atoms)
    discard result.beliefs.hasKeyOrPut(a, candidate)

  # Opinions
  for a in allAgents:
    let ops = options.topics.mapIt(generateOpinionRandomly())
    let candidate = zip(options.topics, ops).toSeq.toTable
    discard result.opinions.hasKeyOrPut(a, candidate)

  # Values
  let candidate = generateValuesRandomly(options.n, options.atoms)
  for a in allAgents:
    discard result.values.hasKeyOrPut(a, candidate[a])

  # Initial network
  let network = generateInitialGraph(options.n, options.edges, options.networkType, options.forceConnectedNetwork)
  let agentsWithNoNeighbors = allAgents.mapIt(if options.network.hasKey(it): 0 else: 1).sum
  if agentsWithNoNeighbors == options.n:
    result.network = network
  elif 0 < agentsWithNoNeighbors and agentsWithNoNeighbors < options.n:
    raise newException(
      SOBADefect,
      fmt"{agentsWithNoNeighbors} out of {options.n} agents have no neighbors following your specification"
    )

proc generateSeeds(n: int): seq[int] =
  (0..<n).toSeq.mapIt(rngAccessor.rand(0, high(int)))
  
proc initilizeSimulator*(rawOptions: CommandLineArgs): Simulator =
  ## Returns simulator initialized with `options`.
  rngInitializer(@[rawOptions.seed])
  let options = rawOptions.fillOptions()
  let agents = options.n
  let atoms = options.atoms
  let allIds = (0..<agents).toSeq.map(toId)

  chooseTargetsRNGinitializer(generateSeeds(agents))
  recommendationRNGinitializer(generateSeeds(agents))
  relaxDissonanceRNGinitializer(generateSeeds(agents))

  # Verify everything is specified correctly
  let models = 1 shl atoms
  if not options.topics.allIt(($(it)).len == models):
    raise newException(
      SOBADefect,
      fmt"Topics are specified wrongly: expected #atoms is {atoms}, given topics is {options.topics}"
    )
  for id in allIds:
    if not ($(options.beliefs[id])).len == models:
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s beliefs are specified wrongly: expected #atoms is {atoms} but {options.beliefs[id]}"
      ) 
    if not options.opinions[id].len == options.topics.len:
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s opinions are specified wrongly: there are {options.topics.len} topics and {options.opinions[id].len} opinions"
      )
    if not options.topics.allIt(options.opinions[id].contains(it)):
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s opinions are specified wrongly: topics are {options.topics} but opinions are toward {options.opinions[id].keys.toSeq}"
      )
    if not options.values[id].len == models:
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s values are specified wrongly: values are length of {options.values[id].len} but expected length is {models}"
      )

  # initialize agents
  let allAgents = allIds.mapIt(
    Agent(
      id: it, 
      belief: options.beliefs[it], 
      opinions: options.opinions[it],
      neighbors: options.network[it],
      rewritingStrategy: options.rewriting,
      mu: options.mu,
      alpha: options.alpha,
      unfollowProb: options.unfollowProb,
      activationProb: options.activationProb,
      values: options.values[it],
      epsilon: options.epsilon,
      delta: options.delta,
      gamma: options.gamma,
      agentOrder: options.agentOrder,
    )
  )
  Simulator(
    agents: allAgents, 
    topics: options.topics,
    verbose: options.verbose,
    followFrom: allAgents.generateFollowFrom(),
    updatingProcesses: options.update,
    numberOfActivatedAgents: options.activatedAgents,
  )
