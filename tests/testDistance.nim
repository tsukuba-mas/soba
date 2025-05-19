import unittest

import distance
import intbrg
import types
import tables
import sequtils

suite "Distances":
  test "between opinions":
    let t1 = toFormula("1")
    check distance(@[(t1, newDecimal("0.3"))].toTable, @[(t1, newDecimal("0.8"))].toTable) == newDecimal("0.5")
  
  test "between beliefs":
    check distance(toFormula("11110000"), toFormula("11101000")) == 2

suite "Similar Opinions/Beliefs":
  let topic = toFormula("00000001")
  let agent = Agent(
    opinions: @[(topic, newDecimal("0.5"))].toTable, 
    belief: toFormula("11110000"), 
    epsilon: newDecimal("0.1"), 
    delta: 2,
    acceptanceDescision: AcceptanceDescision.each,
  )

  test "similar opinions":
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.5"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.55"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.45"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.4"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.6"))].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.35"))].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.65"))].toTable))

  test "similar beliefs":
    check agent.hasSimilarBelief(Message(belief: toFormula("11110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("11110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("10010000")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("00001111")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("10001000")))

suite "configure descision algorithm":
  let topic = toFormula("11110000")
  let messages = @[
    Message(opinions: @[(topic, newDecimal("0.5"))].toTable, belief: toFormula("11000000")),
    Message(opinions: @[(topic, newDecimal("0.9"))].toTable, belief: toFormula("11000000")),
    Message(opinions: @[(topic, newDecimal("0.5"))].toTable, belief: toFormula("00001111")),
    Message(opinions: @[(topic, newDecimal("0.7"))].toTable, belief: toFormula("11110000")),
  ]
  let opinions = @[(topic, newDecimal("0.5"))].toTable
  let beliefs = "11000000".toFormula
  let epsilon = newDecimal("0.2")
  let delta = 2
  let opdistWeight = newDecimal("0.5")

  test "each":
    let agent = Agent(
      opinions: opinions,
      belief: beliefs,
      epsilon: epsilon,
      delta: delta,
      acceptanceDescision: AcceptanceDescision.each,
      opdistWeight: opdistWeight,
    )
    let expecteds = @[true, false, false, true]
    let zero = newDecimal("0")
    for (msg, expected) in zip(messages, expecteds):
      let now = agent.distance(msg) == zero
      check now == expected

  test "unified":
    let agent = Agent(
      opinions: opinions,
      belief: beliefs,
      epsilon: epsilon,
      delta: delta,
      acceptanceDescision: AcceptanceDescision.unified,
      opdistWeight: opdistWeight,
    )
    let expecteds = @[true, true, false, false]
    for i, (msg, expected) in zip(messages, expecteds):
      let now = agent.distance(msg) <= agent.epsilon
      check now == expected
    
