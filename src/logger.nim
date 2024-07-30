import strutils
import types
import sequtils
import intbrg
import os
import sets
import strformat

let beliefHist = "belhist.csv"
let ophist = "ophist.csv"
let verbose = "verbose.txt"
var dirname = ""
var isVerbose = false

proc getBeliefHistPath(): string = dirname & "/" & beliefHist

proc getOpinionHistPath(): string = dirname & "/" & ophist

proc initLogger*(outputTo: string, isVerboseMode: bool) = 
  dirname = outputTo
  isVerbose = isVerboseMode
  if getBeliefHistPath().fileExists():
    removeFile(getBeliefHistPath())
  if getOpinionHistPath().fileExists():
    removeFile(getOpinionHistPath())
  if dirExists(dirname):
    removeDir(dirname)
  createDir(dirname)

proc appendToFile(path: string, content: string) =
  var f = open(path, fmAppend)
  defer:
    f.close()
  f.write(content & "\n")

proc graphLogger(simulator: Simulator, tick: int) =
  let saveTo = dirname & "/" & "graph.csv"
  var content: seq[string] = @[]
  for agent in simulator.agents:
    for next in agent.neighbors:
      content.add($tick & "," & $agent.id & "," & $next)
  saveTo.appendToFile(content.join("\n"))

proc verboseLogger*(content: string, tick: int) = 
  if isVerbose:
    appendToFile(
      dirname & "/" & verbose,
      $tick & "," & content
    )

proc saveAsToml*(options: CommandLineArgs, topic: Formulae) =
  let toml = fmt"""
seed = {options.seed}
dir = "{options.dir}"
agents = {options.n}
follow = {options.follow}
tick = {options.tick}
filter = "{options.filter}"
updating = "{options.update}"
rewriting = "{options.rewriting}"
verbose = {options.verbose}
mu = {options.mu}
alpha = {options.alpha}
unfollow = {options.unfollowProb}
repost = {options.repostProb}
values = [{options.values.mapIt($it).join(",")}]
epsilon = {options.epsilon}
delta = {options.delta}
screen = {options.screenSize}

# The simulator will ignore following content when this file is passed to it
topic = "{topic}"
"""
  var f = open(dirname & "/input.toml", fmWrite)
  defer:
    f.close()
  f.write(toml)

proc log*(simulator: Simulator, tick: int) =
  let beliefs = simulator.agents.mapIt($(it.belief)).join(",")
  let opinions = simulator.agents.mapIt($(it.opinion)).join(",")
  getBeliefHistPath().appendToFile($tick & "," & beliefs)
  getOpinionHistPath().appendToFile($tick & "," & opinions)
  if tick mod 1000 == 0:
    simulator.graphLogger(tick)