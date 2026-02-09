import types
import strutils
import sequtils
import json
import intbrg
import os
import therapist
import tables
import sets
import bigints
import options

const gitHash {.strdefine.} = "unknown"

const prolog = "SOBA: Simulator for Opinions-Beliefs interactions between Agents (" & gitHash & ")"
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
  epsilon: newStringArg(@["--epsilon"], "threshold for opinions", defaultVal="1.0"),
  delta: newIntArg(@["--delta"], "threshold for beliefs", defaultVal=8),
  gamma: newStringArg(@["--gamma"], "threshold for unifeid synchronization", defaultVal="0.5"),
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
  agentOrder: newStringArg(@["--agentOrder"], "order between agents", defaultVal="opinion"),
  forceConnectedNetwork: newFlagArg(@["--forceConnectedNetwork"], "force the initial network to be connected"),
  reevaluateCatBeforeRewiring: newFlagArg(@["--reevaluateCatBeforeRewiring"], "Reevaluate concordant neighbors before rewiring"),
)
spec.parseOrQuit(prolog)

proc parseJson[T](rawJson: string, agents: int, convert: proc(x: JsonNode): T): Table[Id, T] =
  let json = parseJson(if rawJson.len > 0: rawJson else: "{}")
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
  parseJson(rawJson, agents, proc (x: JsonNode): Formulae = x.getStr().toFormula)

proc parseOpinionJson(rawJson: string, agents: int, topics: seq[Formulae]): Table[Id, Table[Formulae, Opinion]] =
    let convert = proc (ops: JsonNode): Table[Formulae, Opinion] =
      zip(topics, ops.getElems()).mapIt((it[0], it[1].getStr().parseDecimal)).toTable
    
    parseJson(rawJson, agents, convert)

proc parseValuesJson(rawJson: string, agents: int, atoms: int): Table[Id, CulturalValues] =
  parseJson(rawJson, agents, proc (x: JsonNode): CulturalValues = x.getElems().mapIt(it.getStr.parseRational))

proc parseNetworkJson(rawJson: string, agents: int, edges: int, networkType: InitNetworkConfig): Table[Id, HashSet[Id]] =
  result = initTable[Id, HashSet[Id]]()
  if rawJson.len > 0:
    let json = parseJson(rawJson)
    for i in 0..<agents:
      result[i.toId] =  json[intToStr(i)].getElems().mapIt(it.getInt.toId).toHashSet

proc parseTopics(val: string, atoms: int): seq[Formulae] =
  if val.len == 0:
    return @[]
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

  let atoms = spec.atoms.value
  let topics = spec.topics.value.parseTopics(atoms)
  let edges = spec.edges.value
  let networkType = parseEnum[InitNetworkConfig](spec.networkInitAlgo.value.strip)
  CommandLineArgs(
    seed: spec.seed.value,
    dir: spec.dir.value,
    n: n,
    edges: edges,
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
    gamma: spec.gamma.value.parseFloat,
    topics: topics,
    opinions: spec.opinions.value.parseOpinionJson(n, topics),
    beliefs: spec.beliefs.value.parseBeliefJson(n, atoms),
    network: spec.network.value.parseNetworkJson(n, edges, networkType),
    prec: spec.precise.value,
    activatedAgents: spec.activatedAgents.value,
    maximalOpinionChange: spec.maximalOpinionChange.value.newDecimal,
    agentOrder: parseEnum[AgentOrder](spec.agentOrder.value.strip),
    forceConnectedNetwork: spec.forceConnectedNetwork.seen,
    reevaluateBeforeRewiring: spec.reevaluateCatBeforeRewiring.seen,
  )
