import strutils
import types
import sequtils
import intbrg
import os
import sets
import strformat

let beliefHist = "belhist.csv"
let ophist = "ophist.csv"
let graphHist = "grhist.csv"
let verbose = "verbose.txt"
var dirname = ""
var isVerbose = false

proc getBeliefHistPath(): string = dirname & "/" & beliefHist

proc getOpinionHistPath(): string = dirname & "/" & ophist

proc getGraphHistPath(): string = dirname & "/" & graphHist

proc initLogger*(outputTo: string, isVerboseMode: bool) = 
  ## Initialize logger. This procedure should be called before 
  ## logger procedures are called.
  dirname = outputTo
  isVerbose = isVerboseMode
  if getBeliefHistPath().fileExists():
    removeFile(getBeliefHistPath())
  if getOpinionHistPath().fileExists():
    removeFile(getOpinionHistPath())
  if getGraphHistPath().fileExists():
    removeFile(getGraphHistPath())
  if dirExists(dirname):
    removeDir(dirname)
  createDir(dirname)

proc appendToFile(path: string, content: string) =
  ## Append `content` to the file on `path`.
  var f = open(path, fmAppend)
  defer:
    f.close()
  f.write(content & "\n")

proc graphLogger(simulator: Simulator, tick: int) =
  ## Output network structure.
  let saveTo = getGraphHistPath()
  if tick == 0:
    saveTo.appendToFile($tick & "," & simulator.followFrom.join(","))
  var content: seq[string] = @[]
  var idx = 0
  for agent in simulator.agents:
    for next in agent.neighbors:
      assert(simulator.followFrom[idx] == agent.id)
      content.add($next)
      idx += 1
  saveTo.appendToFile($tick & "," & content.join(","))

proc verboseLogger*(content: string, tick: int) = 
  ## If simulator is running in verbose mode, output additional information.
  ## Otherwise, do nothing.
  if isVerbose:
    appendToFile(
      dirname & "/" & verbose,
      $tick & "," & content
    )

proc saveAsToml*(options: CommandLineArgs, topics: seq[Formulae]) =
  ## Output the parsed options as TOML file.
  let updatingStrategyInTomlList = "\"" & options.update.mapIt($it).join("\", \"") & "\""
  let toml = fmt"""
seed = {options.seed}
dir = "{options.dir}"
agents = {options.n}
follow = {options.follow}
tick = {options.tick}
filter = "{options.filter}"
updating = [{updatingStrategyInTomlList}]
rewriting = "{options.rewriting}"
verbose = {options.verbose}
mu = {options.mu}
alpha = {options.alpha}
unfollow = {options.unfollowProb}
activation = {options.activationProb}
values = [{options.values.mapIt($it).join(",")}]
epsilon = {options.epsilon}
delta = {options.delta}
topics = "{topics}"
"""
  var f = open(dirname & "/input.toml", fmWrite)
  defer:
    f.close()
  f.write(toml)

proc log*(simulator: Simulator, tick: int) =
  ## Output current opinions, beliefs and network structure.
  let beliefs = simulator.agents.mapIt($(it.belief)).join(",")
  let opinions = simulator.agents.mapIt($(it.opinions)).join(",")
  getBeliefHistPath().appendToFile($tick & "," & beliefs)
  getOpinionHistPath().appendToFile($tick & "," & opinions)
  simulator.graphLogger(tick)