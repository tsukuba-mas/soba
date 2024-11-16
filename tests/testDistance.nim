import unittest

import distance
import intbrg
import types
import tables
import nimice

suite "Distances":
  test "between opinions":
    let t1 = toFormula("1")
    check distance(@[(t1, toRational(3, 10))].toTable, @[(t1, toRational(4, 5))].toTable) == toRational(1, 2)
  
  test "between beliefs":
    check distance(toFormula("11110000"), toFormula("11101000")) == 2

suite "Similar Opinions/Beliefs":
  let topic = toFormula("00000001")
  let agent = Agent(
    opinions: @[(topic, toRational(1, 2))].toTable, 
    belief: toFormula("11110000"), 
    epsilon: toRational(1, 10), 
    delta: 2
  )

  test "similar opinions":
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, toRational(1, 2))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, toRational(55, 100).reduce)].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, toRational(45, 100).reduce)].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, toRational(2, 5))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, toRational(3, 5))].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, toRational(35, 100).reduce)].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, toRational(65, 100).reduce)].toTable))

  test "similar beliefs":
    check agent.hasSimilarBelief(Message(belief: toFormula("11110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("11110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("10010000")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("00001111")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("10001000")))