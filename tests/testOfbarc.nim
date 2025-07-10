import unittest

import randomUtils
include interactions/relaxDissonance

template ofbaCheck(algorithm: UpdatingStrategy) =
  let values = @[
    7//7, 6//7, 5//7, 4//7, 3//7, 2//7, 1//7, 0//7,
  ]
  let topic = toFormula("11000000")
  let alpha = newDecimal("0.5")
  let theta = newDecimal("0.00001")
  const seed = 42
  
  rngInitializer(@[seed])

  var ofbarcAgent = Agent(
    id: Id(0),
    opinions: @[(topic, newDecimal("0"))].toTable,
    belief: toFormula("11110000"),
    values: values,
    alpha: alpha,
  )
  ofbarcAgent.doOfAndBaUntilStable(@[topic], 0, theta, algorithm)

  rngInitializer(@[seed])  # reset it
  var agent = Agent(
    id: Id(0),
    opinions: @[(topic, newDecimal("0"))].toTable,
    belief: toFormula("11110000"),
    values: values,
    alpha: alpha,
  )
  
  while true:
    let oldOpinions = agent.opinions
    let oldBeliefs = agent.belief
    agent.opinionFormation(@[topic], 0)
    agent.beliefAlignment(@[topic], 0, algorithm)
    let haveOpinionsConverged = distance(agent.opinions, oldOpinions) <= theta
    let haveBeliefsConverged = distance(agent.belief, oldBeliefs) == 0
    if haveOpinionsConverged and haveBeliefsConverged:
      break
  
  check distance(agent.opinions, ofbarcAgent.opinions) <= theta
  check distance(agent.belief, ofbarcAgent.belief) == 0


suite "ofba## and performing of and ba## until stability yield the same results":
  test "## = rc":
    ofbaCheck(UpdatingStrategy.barc)

  test "## = vm":
    ofbaCheck(UpdatingStrategy.bavm)
    
