import types
import sets
import intbrg
import strformat
import sequtils
import tables
import strutils
import options
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

proc generateRandomGraph(agents: int, edges: int): Table[Id, HashSet[Id]] = 
  result = initTable[Id, HashSet[Id]]()

  # Add edges (a, b) for all agent a
  for i in 0..<agents:
    while true:
      let next = rngAccessor.rand(0, agents - 1)
      if next == i:
        continue
      result[Id(i)] = [Id(next)].toHashSet
      break
  
  # Add the rest of the edges
  var existingEdges = agents
  while existingEdges < edges:
    let u = Id(rngAccessor.rand(0, agents - 1))
    let v = Id(rngAccessor.rand(0, agents - 1))
    if u == v:
      continue
    if result[u].contains(v):
      continue
    existingEdges += 1
    result[u].incl(v)

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

proc generateRandomGraphWithLowerMaxOutDegree(agents: int, edges: int): Table[Id, HashSet[Id]] =
  var count = 0
  for a in 0..<agents:
    result[Id(a)] = initHashSet[Id]()
  
  # Generate all edges randomly
  while count < edges:
    let u = Id(rngAccessor.rand(0, agents - 1))
    let v = Id(rngAccessor.rand(0, agents - 1))
    if u == v:
      continue
    if result[u].contains(v):
      continue
    result[u].incl(v)
    count += 1
  
  # Choose one edge with maximal neighbors, remove one, and 
  # add one neighbor to agents with no neighbors
  # until all agents have at least one neighbor
  while true:
    let agentWithNoNeighborsOption = result.findAgentWithNoNeighbors()
    if agentWithNoNeighborsOption.isNone():
      break

    let agentWithNoNeighbors = agentWithNoNeighborsOption.get()
    let agentWithMaxNeighbors = result.findAgentWithMaxNeighbors()
    let removed = rngAccessor.choose(result[agentWithMaxNeighbors].toSeq).get()
    let candidates = (0..<agents).toSeq.filterIt(Id(it) != agentWithNoNeighbors)
    let added = Id(rngAccessor.choose(candidates).get())
    result[agentWithMaxNeighbors].excl(removed)
    result[agentWithNoNeighbors].incl(added)

proc generateInitialGraph(agents: int, edges: int, networkType: InitNetworkConfig): Table[Id, HashSet[Id]] =
  case networkType
  of InitNetworkConfig.random:
    return generateRandomGraph(agents, edges)
  of InitNetworkConfig.randomLowerMOD:
    return generateRandomGraphWithLowerMaxOutDegree(agents, edges)

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
  let network = generateInitialGraph(options.n, options.edges, options.networkType)
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
