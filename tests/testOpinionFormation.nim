import unittest

include interactions/relaxDissonance

suite "Opinion Formation":
  let values = @[0.6, 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  let belief = toFormula("11110000")
  let topic = toFormula("11000000")
  
  test "belief-based opinions":
    check getBeliefBasedOpinion(belief, values, topic) == 0.5

  test "opinion formation":
    let alpha = 0.2
    let oldOpinion = 1.0
    let agent = Agent(opinions: @[(topic, oldOpinion)].toTable, belief: belief, values: values, alpha: alpha)
    let expected = alpha * oldOpinion + (1.0 - alpha) * 0.5
    check agent.opinionFormation(@[topic], 0).opinions[topic] == expected
