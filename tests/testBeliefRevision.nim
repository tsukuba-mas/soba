import unittest

import interactions/brg
import intbrg
import types 

suite "Belief Revision":
  test "Beliefs are not updated with no other beliefs":
    let beliefs = toFormula("11110000")
    let agent = Agent(belief: beliefs)
    check agent.beliefRevisionGames(@[], 0).belief == beliefs

  test "Beliefs revision based on BRG R3 with Hamming distance and summention":
    let b1 = toFormula("11110000")
    let b2 = toFormula("00001111")
    let agent = Agent(belief: b1)
    let expected = toFormula("11111111")
    check agent.beliefRevisionGames(@[Message(belief: b2)], 0).belief == expected