import strutils
import types
import sequtils
import intbrg
import os
import sets
import tables
import strformat

let beliefHist = "belhist.csv"
let graphHist = "grhist.csv"
let verbose = "verbose.txt"
var dirname = ""
var isVerbose = false

var belhistContent = ""
var grhistContent = ""
var ophistContent = initTable[int, string]()

proc getBeliefHistPath(): string = dirname & "/" & beliefHist

proc getOpinionHistPath(idx: int): string = dirname & "/" & "ophist" & $idx & ".csv"

proc getGraphHistPath(): string = dirname & "/" & graphHist

proc appendToFile(path: string, content: string) =
  ## Append `content` to the file on `path`.
  var f = open(path, fmWrite)
  defer:
    f.close()
  f.write(content.strip()) # remove the last \n

proc flushToFiles*() =
  appendToFile(getGraphHistPath(), grhistContent)
  appendToFile(getBeliefHistPath(), belhistContent)
  let cpy = dirname
  for idx in ophistContent.keys:
    appendToFile(getOpinionHistPath(idx), ophistContent[idx])
    dirname = cpy

proc initLogger*(outputTo: string, isVerboseMode: bool, topics: int) = 
  ## Initialize logger. This procedure should be called before 
  ## logger procedures are called.
  dirname = outputTo
  isVerbose = isVerboseMode
  if getBeliefHistPath().fileExists():
    removeFile(getBeliefHistPath())
  for i in 0..<topics:
    if getOpinionHistPath(i).fileExists():
      removeFile(getOpinionHistPath(i))
  if getGraphHistPath().fileExists():
    removeFile(getGraphHistPath())
  if dirExists(dirname):
    removeDir(dirname)
  createDir(dirname)
  for i in 0..<topics:
    ophistContent[i] = ""

proc graphLogger(simulator: Simulator, tick: int) =
  ## Output network structure.
  let saveTo = getGraphHistPath()
  if tick == 0:
    grhistContent.add($tick & "," & simulator.followFrom.join(",") & "\n")
  var content: seq[string] = @[]
  var idx = 0
  for agent in simulator.agents:
    for next in agent.neighbors:
      if simulator.followFrom[idx] != agent.id:
        raise newException(
          SOBADefect,
          fmt"The number of agent {agent.id}'s neighbors has changed"
        )
      content.add($next)
      idx += 1
  # saveTo.appendToFile($tick & "," & content.join(","))
  grhistContent.add($tick & "," & content.join(",") & "\n")

proc verboseLogger*(content: string, tick: int) = 
  ## If simulator is running in verbose mode, output additional information.
  ## Otherwise, do nothing.
  if isVerbose:
    appendToFile(
      dirname & "/" & verbose,
      $tick & "," & content & "\n"
    )

proc log*(simulator: Simulator, tick: int) =
  ## Output current opinions, beliefs and network structure.
  let beliefs = simulator.agents.mapIt($(it.belief)).join(",")
  # getBeliefHistPath().appendToFile($tick & "," & beliefs)
  belhistContent.add($tick & "," & beliefs & "\n")
  for idx, topic in simulator.topics:
    let opinions = simulator.agents.mapIt($(it.opinions[topic])).join(",")
    # getOpinionHistPath(idx).appendToFile($tick & "," & opinions)
    ophistContent[idx].add($tick & "," & simulator.agents.mapIt($(it.opinions[topic])).join(",") & "\n")
  simulator.graphLogger(tick)