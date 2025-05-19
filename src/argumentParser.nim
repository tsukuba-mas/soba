import types
import strutils
import sequtils
import json
import intbrg
import os
import therapist
import tables
import sets
import randomUtils
import bigints
import options

const prolog = "SOBA: Simulator for Opinions-Beliefs interactions between Agents"
let spec = (
  seed: newIntArg(@["--seed"], "seed", defaultVal=42),
  dir: newStringArg(@["-d", "--dir"], "directory to output files", defaultVal="results/tmp"),
  nbAgent: newIntArg(@["-n", "--nbAgent"], "number of agents", defaultVal=100),
  tick: newIntArg(@["--tick"], "number of ticks (iterations)", defaultVal=100),  
  atoms: newIntArg(@["--atoms"], "number of atomic propositions", defaultVal=3),
  update: newStringArg(@["--update"], "updating strategy", defaultVal="oddw"),
  rewrite: newStringArg(@["--rewrite"], "rewriting strategy", defaultVal="none"),
  prehoc: newStringArg(@["--prehoc"], "prehoc procedures", defaultVal=""),
  verbose: newFlagArg(@["--verbose"], "verbose mode"),
  mu: newStringArg(@["--mu"], "mixture ratio in oddw", defaultVal="0.5"),
  alpha: newStringArg(@["--alpha"], "mixture ratio in of", defaultVal="0.5"),
  pUnfollow: newStringArg(@["--pUnfollow"], "probability to remove edge", defaultVal="0.5"),
  pActive: newStringArg(@["--pActive"], "probability to act", defaultVal="0.5"),
  epsilon: newStringArg(@["--epsilon"], "threshold for opinions", defaultVal="0.5"),
  delta: newIntArg(@["--delta"], "threshold for beliefs", defaultVal=4),
  network: newStringArg(@["--network"], "initial network", optional=true),
  values: newStringArg(@["--values"], "cultural values", optional=true),
  beliefs: newStringArg(@["--beliefs"], "initial beliefs", optional=true),
  opinions: newStringArg(@["--opinions"], "initial opinions", optional=true),
  topics: newStringArg(@["--topics"], "topics", optional=true),
  precise: newIntArg(@["--precise"], "The number of digits of opinions", defaultVal=10),
  activatedAgents: newIntArg(@["--nbActivatedAgents"], "number of activated agents", optional=true),
  help: newHelpArg(@["-h", "--help"], "print help message"),
  maximalOpinionChange: newStringArg(@["--maximalOpinionChange"], "threshold for opinions stability", defaultVal="0.00001"),
  edges: newIntArg(@["--nbEdges"], "number of edges", defaultVal=400),
  networkInitAlgo: newStringArg(@["--networkInitAlgo"], "algorithm to initialize network", defaultVal="random"),
  opDistWeight: newStringArg(@["--opDistWeight"], "weight for opinion distance", defaultVal="0.5"),
  acceptanceDescision: newStringArg(@["--acceptanceDescision"], "algorithm to decide whether messages are accepted", defaultVal="each"),
)
spec.parseOrQuit(prolog)

proc generateBeliefRandomly(atoms: int): Formulae =
  let models = 1 shl atoms
  rand(1, (1 shl models) - 1).toBin(models).toFormula

proc generateOpinionRandomly(ub: int = 10000): Opinion =
  let num = rand(0, ub)
  newDecimal(num) / newDecimal(ub)

proc parseJson[T](rawJson: string, agents: int, convert: proc(x: JsonNode): T): Table[Id, T] =
  let json = parseJson(rawJson)
  const wildcard = "-1"
  # -1 is "for all agents..."
  if json.hasKey(wildcard):
    for id in 0..<agents:
      result[Id(id)] = json[wildcard].convert()
  
  for id in json.keys:
    if id == wildcard:
      continue
    result[Id(parseInt(id))] = json[id].convert()

proc parseBeliefJson(rawJson: string, agents: int, atoms: int): Table[Id, Formulae] =
  if rawJson == "":
    # Initialize randomly if nothing is given
    (0..<agents).toSeq.mapIt((Id(it), generateBeliefRandomly(atoms))).toTable
  else:
    parseJson(rawJson, agents, proc (x: JsonNode): Formulae = x.getStr().toFormula)

proc parseOpinionJson(rawJson: string, agents: int, topics: seq[Formulae]): Table[Id, Table[Formulae, Opinion]] =
  if rawJson == "":
    # Initialize randomly if nothing is given
    let initializeOpinions = proc (): Table[Formulae, Opinion] =
      topics.mapIt((it, generateOpinionRandomly())).toTable

    (0..<agents).toSeq.mapIt((Id(it), initializeOpinions())).toTable
  else:
    let convert = proc (ops: JsonNode): Table[Formulae, Opinion] =
      zip(topics, ops.getElems()).mapIt((it[0], it[1].getStr().parseDecimal)).toTable
    
    parseJson(rawJson, agents, convert)

proc parseValuesJson(rawJson: string, agents: int, atoms: int): Table[Id, CulturalValues] =
  if rawJson == "":
    # Initialize randomly if nothing is given
    let models = 1 shl atoms
    let ub = 100000
    let values = (0..<models).toSeq.mapIt(rand(0, ub) // ub)
    (0..<agents).toSeq.mapIt((Id(it), values)).toTable
  else:
    parseJson(rawJson, agents, proc (x: JsonNode): CulturalValues = x.getElems().mapIt(it.getStr.parseRational))

proc generateRandomGraph(agents: int, edges: int): Table[Id, HashSet[Id]] = 
  result = initTable[Id, HashSet[Id]]()

  # Add edges (a, b) for all agent a
  for i in 0..<agents:
    while true:
      let next = rand(0, agents - 1)
      if next == i:
        continue
      result[Id(i)] = [Id(next)].toHashSet
      break
  
  # Add the rest of the edges
  var existingEdges = agents
  while existingEdges < edges:
    let u = Id(rand(0, agents - 1))
    let v = Id(rand(0, agents - 1))
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
    let u = Id(rand(0, agents - 1))
    let v = Id(rand(0, agents - 1))
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
    let removed = agentWithMaxNeighbors.choose(result[agentWithMaxNeighbors].toSeq).get()
    let candidates = (0..<agents).toSeq.filterIt(Id(it) != agentWithNoNeighbors)
    let added = Id(agentWithNoNeighbors.choose(candidates).get())
    result[agentWithMaxNeighbors].excl(removed)
    result[agentWithNoNeighbors].incl(added)
  
proc generateInitialGraph(agents: int, edges: int, networkType: InitNetworkConfig): Table[Id, HashSet[Id]] =
  case networkType
  of InitNetworkConfig.random:
    return generateRandomGraph(agents, edges)
  of InitNetworkConfig.randomLowerMOD:
    return generateRandomGraphWithLowerMaxOutDegree(agents, edges)

proc parseNetworkJson(rawJson: string, agents: int, edges: int, networkType: InitNetworkConfig): Table[Id, HashSet[Id]] =
  result = initTable[Id, HashSet[Id]]()
  if rawJson == "":
    return generateInitialGraph(agents, edges, networkType)
  else:
    let json = parseJson(rawJson)
    for i in 0..<agents:
      result[i.toId] =  json[intToStr(i)].getElems().mapIt(it.getInt.toId).toHashSet

proc parseTopics(val: string, atoms: int): seq[Formulae] =
  if val == "":
    # Initialize randomly if nothing is given
    @[generateBeliefRandomly(atoms)]
  else:
    val.split(",").map(toFormula)

proc parseAsSeqOfEnum[T: enum](raw: string): seq[T] =
  if raw == "":
    @[]
  else:
    raw.split(",").mapIt(parseEnum[T](it.strip))

proc parseArguments*(): CommandLineArgs =
  ## Parse command line argument.
  let n = spec.nbAgent.value
  initRand(spec.seed.value, n)

  let atoms = spec.atoms.value
  let topics = spec.topics.value.parseTopics(atoms)
  let edges = spec.edges.value
  let networkType = parseEnum[InitNetworkConfig](spec.networkInitAlgo.value.strip)
  CommandLineArgs(
    seed: spec.seed.value,
    dir: spec.dir.value,
    n: n,
    atoms: atoms,
    tick: spec.tick.value,
    update: parseAsSeqOfEnum[UpdatingStrategy](spec.update.value),
    rewriting: parseEnum[RewritingStrategy](spec.rewrite.value.strip),
    prehoc: parseAsSeqOfEnum[UpdatingStrategy](spec.prehoc.value),
    verbose: spec.verbose.seen,
    mu: spec.mu.value.newDecimal,
    alpha: spec.alpha.value.newDecimal,
    unfollowProb: spec.pUnfollow.value.parseFloat,
    activationProb: spec.pActive.value.parseFloat,
    values: spec.values.value.parseValuesJson(n, atoms),
    epsilon: spec.epsilon.value.newDecimal,
    delta: spec.delta.value,
    topics: topics,
    opinions: spec.opinions.value.parseOpinionJson(n, topics),
    beliefs: spec.beliefs.value.parseBeliefJson(n, atoms),
    network: spec.network.value.parseNetworkJson(n, edges, networkType),
    prec: spec.precise.value,
    activatedAgents: spec.activatedAgents.value,
    maximalOpinionChange: spec.maximalOpinionChange.value.newDecimal,
    opDistWeight: spec.opDistWeight.value.newDecimal,
    acceptanceDescision: parseEnum[AcceptanceDescision](spec.acceptanceDescision.value.strip),
  )
