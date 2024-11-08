import unittest

import distance
import intbrg
import types
import tables

suite "Distances":
  test "between opinions":
    let t1 = toFormula("1")
    check distance(@[(t1, 0.3)].toTable, @[(t1, 0.8)].toTable) == 0.5
  
  test "between beliefs":
    check distance(toFormula("11110000"), toFormula("11101000")) == 2

suite "Similar Opinions/Beliefs":
  let topic = toFormula("00000001")
  let agent = Agent(
    opinions: @[(topic, 0.5)].toTable, 
    belief: toFormula("11110000"), 
    epsilon: 0.1, 
    delta: 2
  )

  test "similar opinions":
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, 0.5)].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, 0.55)].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, 0.45)].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, 0.4)].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, 0.6)].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, 0.35)].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, 0.65)].toTable))

  test "similar beliefs":
    check agent.hasSimilarBelief(Message(belief: toFormula("11110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("11110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("10010000")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("00001111")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("10001000")))