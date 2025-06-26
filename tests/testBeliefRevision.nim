import unittest

import interactions/brg
import intbrg
import types 

suite "Belief Revision":
  test "Beliefs are not updated with no other beliefs":
    let beliefs = toFormula("11110000")
    var agent = Agent(belief: beliefs)
    agent.beliefRevisionGames(@[], 0)
    check agent.belief == beliefs

  test "Beliefs revision based on BRG R3 with Hamming distance and summention":
    let b1 = toFormula("11110000")
    let b2 = toFormula("00001111")
    var agent = Agent(belief: b1)
    let expected = toFormula("11111111")
    agent.beliefRevisionGames(@[Message(belief: b2)], 0)
    check agent.belief == expected
