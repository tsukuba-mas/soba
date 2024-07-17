import strutils
import types
import sequtils
import intbrg
import os
import sets

let beliefHist = "belhist.csv"
let ophist = "ophist.csv"
var dirname = ""

proc getBeliefHistPath(): string = dirname & "/" & beliefHist

proc getOpinionHistPath(): string = dirname & "/" & ophist

proc initLogger*(outputTo: string) = 
  dirname = outputTo
  if getBeliefHistPath().fileExists():
    removeFile(getBeliefHistPath())
  if getOpinionHistPath().fileExists():
    removeFile(getOpinionHistPath())
  if dirExists(dirname):
    removeDir(dirname)
  createDir(dirname)

proc appendToFile(path: string, content: string, tick: int) =
  var f = open(path, fmAppend)
  defer:
    f.close()
  f.write($tick & "," & content & "\n")

proc graphLogger(simulator: Simulator, tick: int) =
  let saveTo = dirname & "/" & "graph.csv"
  for agent in simulator.agents:
    for next in agent.neighbors:
      saveTo.appendToFile($agent.id & "," & $next, tick)

proc log*(simulator: Simulator, tick: int) =
  let beliefs = simulator.agents.mapIt($(it.belief)).join(",")
  let opinions = simulator.agents.mapIt($(it.opinion)).join(",")
  getBeliefHistPath().appendToFile(beliefs, tick)
  getOpinionHistPath().appendToFile(opinions, tick)
  if tick mod 1000 == 0:
    simulator.graphLogger(tick)