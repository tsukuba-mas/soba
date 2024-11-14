import types
import strutils
import sequtils
import json
import intbrg
import os
import therapist
import tables
import sets

let spec = (
  seed: newIntArg(@["--seed"], "seed", defaultVal=42),
  dir: newStringArg(@["-d", "--dir"], "directory to output files", defaultVal="results/tmp"),
  nbAgent: newIntArg(@["-n", "--nbAgent"], "number of agents", defaultVal=100),
  tick: newIntArg(@["--tick"], "number of ticks (iterations)", defaultVal=100),
  filter: newStringArg(@["--filter"], "filtering strategy", defaultVal="all"),
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
  network: newStringArg(@["--network"], "initial network"),
  values: newStringArg(@["--values"], "cultural values", defaultVal="0.0,0.143,0.286,0.429,0.571,0.714,0.857,1.0"),
  beliefs: newStringArg(@["--beliefs"], "initial beliefs"),
  opinions: newStringArg(@["--opinions"], "initial opinions"),
  topics: newStringArg(@["--topics"], "topics"),
  help: newHelpArg(@["-h", "--help"], "print help message"),
)
spec.parseOrQuit()

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

proc parseBeliefJson(rawJson: string, agents: int): Table[Id, Formulae] =
  parseJson(rawJson, agents, proc (x: JsonNode): Formulae = x.getStr().toFormula)

proc parseOpinionJson(rawJson: string, agents: int, topics: seq[Formulae]): Table[Id, Table[Formulae, Opinion]] =
  let convert = proc (ops: JsonNode): Table[Formulae, Opinion] =
    zip(topics, ops.getElems()).mapIt((it[0], it[1].getFloat)).toTable
  
  parseJson(rawJson, agents, convert)

proc parseValuesJson(rawJson: string, agents: int): Table[Id, seq[float]] =
  parseJson(rawJson, agents, proc (x: JsonNode): seq[float] = x.getElems().mapIt(it.getFloat))

proc parseNetworkJson(rawJson: string, agents: int): Table[Id, HashSet[Id]] =
  let json = parseJson(rawJson)
  result = initTable[Id, HashSet[Id]]()
  for i in 0..<agents:
    result[i.toId] =  json[intToStr(i)].getElems().mapIt(it.getInt.toId).toHashSet

proc parseArguments*(): CommandLineArgs =
  ## Parse command line argument.
  let n = spec.nbAgent.value
  let topics = spec.topics.value.split(",").map(toFormula)
  CommandLineArgs(
    seed: spec.seed.value,
    dir: spec.dir.value,
    n: n,
    tick: spec.tick.value,
    filter: parseEnum[FilterStrategy](spec.filter.value),
    update: spec.update.value.split(",").mapIt(parseEnum[UpdatingStrategy](it)),
    rewriting: parseEnum[RewritingStrategy](spec.rewrite.value),
    prehoc: spec.prehoc.value.split(",").mapIt(parseEnum[UpdatingStrategy](it)),
    verbose: spec.verbose.seen,
    mu: spec.mu.value,
    alpha: spec.alpha.value,
    unfollowProb: spec.pUnfollow.value,
    activationProb: spec.pActive.value,
    values: spec.values.value.parseValuesJson(n),
    epsilon: spec.epsilon.value,
    delta: spec.delta.value,
    topics: topics,
    opinions: spec.opinions.value.parseOpinionJson(n, topics),
    beliefs: spec.beliefs.value.parseBeliefJson(n),
    network: spec.network.value.parseNetworkJson(n),
  )