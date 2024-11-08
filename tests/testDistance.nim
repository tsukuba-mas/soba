import unittest

import distance
import intbrg
import types

suite "Distances":
  test "between opinions":
    check distance(0.3, 0.8) == 0.5
  
  test "between beliefs":
    check distance(toFormula("11110000"), toFormula("11101000")) == 2

suite "Similar Opinions/Beliefs":
  let agent = Agent(opinion: 0.5, belief: toFormula("11110000"), epsilon: 0.1, delta: 2)

  test "similar opinions":
    check agent.hasSimilarOpinion(Message(opinion: 0.5))
    check agent.hasSimilarOpinion(Message(opinion: 0.55))
    check agent.hasSimilarOpinion(Message(opinion: 0.45))
    check agent.hasSimilarOpinion(Message(opinion: 0.4))
    check agent.hasSimilarOpinion(Message(opinion: 0.6))
    check not agent.hasSimilarOpinion(Message(opinion: 0.35))
    check not agent.hasSimilarOpinion(Message(opinion: 0.65))

  test "similar beliefs":
    check agent.hasSimilarBelief(Message(belief: toFormula("11110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("11110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("10010000")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("00001111")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("10001000")))