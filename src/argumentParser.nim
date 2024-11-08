import types
import strutils
import sequtils
import parsetoml
import intbrg
import os

proc parseToSeqOfUpdatingStrategy(toml: TomlValueRef): seq[UpdatingStrategy] =
  toml.getElems().mapIt(parseEnum[UpdatingStrategy](it.getStr()))

proc optionsFromToml(tomlPath: string): CommandLineArgs =
  ## Parse given toml file and return the result.
  let toml = parseFile(tomlPath)
  CommandLineArgs(
    seed: toml["seed"].getInt(),
    dir: toml["dir"].getStr(),
    n: toml["agents"].getInt(),
    follow: toml["follow"].getInt(),
    tick: toml["tick"].getInt(),
    filter: parseEnum[FilterStrategy](toml["filter"].getStr()),
    update: toml["updating"].parseToSeqOfUpdatingStrategy(),
    rewriting: parseEnum[RewritingStrategy](toml["rewriting"].getStr()),
    prehoc: toml["prehoc"].parseToSeqOfUpdatingStrategy(),
    verbose: toml["verbose"].getBool(),
    mu: toml["mu"].getFloat(),
    alpha: toml["alpha"].getFloat(),
    unfollowProb: toml["unfollow"].getFloat(),
    activationProb: toml["activation"].getFloat(),
    values: toml["values"].getElems().mapIt(it.getFloat()),
    epsilon: toml["epsilon"].getFloat(),
    delta: toml["delta"].getInt(),
    topic: toml["topic"].getStr().toFormula,
  )

proc parseArguments*(): CommandLineArgs =
  ## Parse command line argument (path to a TOML file).
  let params = commandLineParams()
  assert(params.len > 0, "Empty parameter")
  let toml = params[0]
  if not fileExists(toml):
    assert(false, toml & " does not exist")
  optionsFromToml(toml)