import unittest

include interactions/relaxDissonance

suite "Opinion Formation":
  let values = @[
    3 // 5, 2 // 5, 0 // 1, 
    0 // 1, 0 // 1, 0 // 1, 
    0 // 1, 0 // 1
  ]
  let belief = toFormula("11110000")
  let topic = toFormula("11000000")
  
  test "belief-based opinions":
    check getBeliefBasedOpinion(belief, values, topic) == newDecimal("0.5")

  test "opinion formation":
    let alpha = newDecimal("0.2")
    let oldOpinion = newDecimal("1")
    let agent = Agent(opinions: @[(topic, oldOpinion)].toTable, belief: belief, values: values, alpha: alpha)
    let expected = alpha * oldOpinion + (newDecimal(1)  - alpha) / newDecimal(2)
    check agent.opinionFormation(@[topic], 0).opinions[topic] == expected
