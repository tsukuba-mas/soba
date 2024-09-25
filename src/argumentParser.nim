import types
import strutils
import sequtils
import parsetoml
import intbrg
import os

proc optionsFromToml(tomlPath: string): CommandLineArgs =
  let toml = parseFile(tomlPath)
  CommandLineArgs(
    seed: toml["seed"].getInt(),
    dir: toml["dir"].getStr(),
    n: toml["agents"].getInt(),
    follow: toml["follow"].getInt(),
    tick: toml["tick"].getInt(),
    filter: parseEnum[FilterStrategy](toml["filter"].getStr()),
    update: toml["updating"].getElems().mapIt(parseEnum[UpdatingStrategy](it.getStr())),
    rewriting: parseEnum[RewritingStrategy](toml["rewriting"].getStr()),
    verbose: toml["verbose"].getBool(),
    mu: toml["mu"].getFloat(),
    alpha: toml["alpha"].getFloat(),
    unfollowProb: toml["unfollow"].getFloat(),
    repostProb: toml["repost"].getFloat(),
    activationProb: toml["activation"].getFloat(),
    values: toml["values"].getElems().mapIt(it.getFloat()),
    epsilon: toml["epsilon"].getFloat(),
    delta: toml["delta"].getInt(),
    atomicProps: 3,
    topic: toml["topic"].getStr().toFormula,
  )

proc parseArguments*(): CommandLineArgs =
  let params = commandLineParams()
  assert(params.len > 0, "Empty parameter")
  let toml = params[0]
  if not fileExists(toml):
    assert(false, toml & " does not exist")
  optionsFromToml(toml)