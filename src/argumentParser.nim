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
import nimice
import strformat

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
  mu: newStringArg(@["--mu"], "mixture ratio in oddw", defaultVal="1/2"),
  alpha: newStringArg(@["--alpha"], "mixture ratio in of", defaultVal="1/2"),
  pUnfollow: newStringArg(@["--pUnfollow"], "probability to remove edge", defaultVal="1/2"),
  pActive: newStringArg(@["--pActive"], "probability to act", defaultVal="1/2"),
  epsilon: newStringArg(@["--epsilon"], "threshold for opinions", defaultVal="1/2"),
  delta: newIntArg(@["--delta"], "threshold for beliefs", defaultVal=4),
  network: newStringArg(@["--network"], "initial network", optional=true),
  values: newStringArg(@["--values"], "cultural values", optional=true),
  beliefs: newStringArg(@["--beliefs"], "initial beliefs", optional=true),
  opinions: newStringArg(@["--opinions"], "initial opinions", optional=true),
  topics: newStringArg(@["--topics"], "topics", optional=true),
  help: newHelpArg(@["-h", "--help"], "print help message"),
)
spec.parseOrQuit(prolog)

proc generateBeliefRandomly(atoms: int): Formulae =
  let models = 1 shl atoms
  rand(1, (1 shl models) - 1).toBin(models).toFormula

proc generateOpinionRandomly(ub: int = 10000): Opinion =
  toRational(rand(0, ub), ub).reduce

proc parseRationals(rawData: string): Opinion =
  ## Parse rational number (e.g., 2/3) and return as a value with type `Opinion`.
  let splited = rawData.split("/")
  assert splited.len == 2, fmt"Unknown format of rational number, {rawData} is given"
  let num = splited[0].strip.parseInt
  let den = splited[1].strip.parseInt
  toRational(num, den).reduce

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
      zip(topics, ops.getElems()).mapIt((it[0], parseRationals(it[1].getStr()))).toTable
    
    parseJson(rawJson, agents, convert)

proc parseValuesJson(rawJson: string, agents: int, atoms: int): Table[Id, CulturalValues] =
  if rawJson == "":
    # Initialize randomly if nothing is given
    let models = 1 shl atoms
    let ub = 100000
    let values = (0..<models).toSeq.mapIt(toRational(rand(0, ub), ub))
    (0..<agents).toSeq.mapIt((Id(it), values)).toTable
  else:
    parseJson(rawJson, agents, proc (x: JsonNode): CulturalValues = x.getElems().mapIt(it.getStr.parseRationals))

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

proc parseAsSeqOfEnum[T: enum](raw: string): seq[T] =
  if raw == "":
    @[]
  else:
    raw.split(",").mapIt(parseEnum[T](it.strip))

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
    atoms: atoms,
    tick: spec.tick.value,
    update: parseAsSeqOfEnum[UpdatingStrategy](spec.update.value),
    rewriting: parseEnum[RewritingStrategy](spec.rewrite.value.strip),
    prehoc: parseAsSeqOfEnum[UpdatingStrategy](spec.prehoc.value),
    verbose: spec.verbose.seen,
    mu: spec.mu.value.parseRationals,
    alpha: spec.alpha.value.parseRationals,
    unfollowProb: spec.pUnfollow.value.parseFloat,
    activationProb: spec.pActive.value.parseFloat,
    values: spec.values.value.parseValuesJson(n, atoms),
    epsilon: spec.epsilon.value.parseRationals,
    delta: spec.delta.value,
    topics: topics,
    opinions: spec.opinions.value.parseOpinionJson(n, topics),
    beliefs: spec.beliefs.value.parseBeliefJson(n, atoms),
    network: spec.network.value.parseNetworkJson(n),
  )