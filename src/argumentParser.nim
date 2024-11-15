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
  mu: newFloatArg(@["--mu"], "mixture ratio in oddw", defaultVal=0.5),
  alpha: newFloatArg(@["--alpha"], "mixture ratio in of", defaultVal=0.5),
  pUnfollow: newFloatArg(@["--pUnfollow"], "probability to remove edge", defaultVal=0.5),
  pActive: newFloatArg(@["--pActive"], "probability to act", defaultVal=0.5),
  epsilon: newFloatArg(@["--epsilon"], "threshold for opinions", defaultVal=0.5),
  delta: newIntArg(@["--delta"], "threshold for beliefs", defaultVal=4),
  network: newStringArg(@["--network"], "initial network", optional=true),
  values: newStringArg(@["--values"], "cultural values", optional=true),
  beliefs: newStringArg(@["--beliefs"], "initial beliefs", optional=true),
  opinions: newStringArg(@["--opinions"], "initial opinions", optional=true),
  topics: newStringArg(@["--topics"], "topics", optional=true),
  help: newHelpArg(@["-h", "--help"], "print help message"),
)
spec.parseOrQuit()

proc generateBeliefRandomly(atoms: int): Formulae =
  let models = 1 shl atoms
  rand(1, (1 shl models) - 1).toBin(models).toFormula

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
      topics.mapIt((it, rand(0.0, 1.0))).toTable

    (0..<agents).toSeq.mapIt((Id(it), initializeOpinions())).toTable
  else:
    let convert = proc (ops: JsonNode): Table[Formulae, Opinion] =
      zip(topics, ops.getElems()).mapIt((it[0], it[1].getFloat)).toTable
    
    parseJson(rawJson, agents, convert)

proc parseValuesJson(rawJson: string, agents: int, atoms: int): Table[Id, seq[float]] =
  if rawJson == "":
    # Initialize randomly if nothing is given
    let models = 1 shl atoms
    let values = (0..<models).toSeq.mapIt(rand(0.0, 1.0))
    (0..<agents).toSeq.mapIt((Id(it), values)).toTable
  else:
    parseJson(rawJson, agents, proc (x: JsonNode): seq[float] = x.getElems().mapIt(it.getFloat))

proc parseNetworkJson(rawJson: string, agents: int): Table[Id, HashSet[Id]] =
  result = initTable[Id, HashSet[Id]]()
  if rawJson == "":
    # Initialize as the complete graph if nothing is given
    let allIds = (0..<agents).toSeq.mapIt(Id(it)).toHashSet
    for id in allIds:
      result[id] = allIds - [id].toHashSet
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

proc parseArguments*(): CommandLineArgs =
  ## Parse command line argument.
  initRand(spec.seed.value)
  let n = spec.nbAgent.value
  let atoms = spec.atoms.value
  let topics = spec.topics.value.parseTopics(atoms)
  CommandLineArgs(
    seed: spec.seed.value,
    dir: spec.dir.value,
    n: n,
    tick: spec.tick.value,
    update: spec.update.value.split(",").mapIt(parseEnum[UpdatingStrategy](it.strip)),
    rewriting: parseEnum[RewritingStrategy](spec.rewrite.value.strip),
    prehoc: spec.prehoc.value.split(",").mapIt(parseEnum[UpdatingStrategy](it.strip)),
    verbose: spec.verbose.seen,
    mu: spec.mu.value,
    alpha: spec.alpha.value,
    unfollowProb: spec.pUnfollow.value,
    activationProb: spec.pActive.value,
    values: spec.values.value.parseValuesJson(n, atoms),
    epsilon: spec.epsilon.value,
    delta: spec.delta.value,
    topics: topics,
    opinions: spec.opinions.value.parseOpinionJson(n, topics),
    beliefs: spec.beliefs.value.parseBeliefJson(n, atoms),
    network: spec.network.value.parseNetworkJson(n),
  )