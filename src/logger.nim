import strutils
import types
import sequtils
import intbrg
import os

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

proc appendToFile(path: string, content: string) =
  var f = open(path, fmAppend)
  defer:
    f.close()
  f.write(content & "\n")

proc log*(simulator: Simulator) =
  let beliefs = simulator.agents.mapIt($(it.belief)).join(",")
  let opinions = simulator.agents.mapIt($(it.opinion)).join(",")
  getBeliefHistPath().appendToFile(beliefs)
  getOpinionHistPath().appendToFile(opinions)