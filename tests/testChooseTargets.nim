import unittest

import interactions/chooseTargets
import types
import randomUtils
import sequtils

suite "Choose targets":
  initRand(42)
  let n = 10
  let allIds = (0..<n).toSeq.mapIt(Id(it))

  test "The number of activated agents should be constant if the second argument is positive":
    let agents = (0..<n).toSeq.mapIt(Agent(id: Id(it), activationProb: 1.0))
    let expected = 2
    for _ in 0..<100:
      check agents.chooseTargets(expected).len == expected

  test "All agents are selected if activation prob == 1.0":
    let agents = (0..<n).toSeq.mapIt(Agent(id: Id(it), activationProb: 1.0))
    check agents.chooseTargets(0) == allIds
  
  # test "No agents are selected if activation prob == 0.0":
  #   try:
  #     discard (0..<n).toSeq.mapIt(Agent(id: Id(it), activationProb: 0.0)).chooseTargets(0)
  #   except Exception as e:
  #     # Should reach call depth limit; should be rewritten in more sophisticated way
  #     check e.msg.contains("Error: call depth limit reached")
  
  test "Some agents are selected if 0 < activation prob < 1":
    let agents = (0..<n).toSeq.mapIt(Agent(id: Id(it), activationProb: 0.5))
    let selected = agents.chooseTargets(0)
    check 0 < selected.len
    check selected.len < n
    check selected.allIt(allIds.contains(it))