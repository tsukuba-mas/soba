import unittest

include interactions/relaxDissonance

suite "Opinion Formation":
  let values = @[
    toRational(3, 5), toRational(2, 5), toRational(0, 1), 
    toRational(0, 1), toRational(0, 1), toRational(0, 1), 
    toRational(0, 1), toRational(0, 1)
  ]
  let belief = toFormula("11110000")
  let topic = toFormula("11000000")
  
  test "belief-based opinions":
    check getBeliefBasedOpinion(belief, values, topic) == toRational(1, 2)

  test "opinion formation":
    let alpha = toRational(1, 5)
    let oldOpinion = toRational(1, 1)
    let agent = Agent(opinions: @[(topic, oldOpinion)].toTable, belief: belief, values: values, alpha: alpha)
    let expected = alpha * oldOpinion + (toRational(1, 1) - alpha) * toRational(1, 2)
    check agent.opinionFormation(@[topic], 0).opinions[topic] == expected
