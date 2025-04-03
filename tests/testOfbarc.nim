import unittest

import randomUtils
include interactions/relaxDissonance

test "ofbarc and performing of and barc until stability yield the same results":
  let values = @[
    7//7, 6//7, 5//7, 4//7, 3//7, 2//7, 1//7, 0//7,
  ]
  let topic = toFormula("11000000")
  let alpha = newDecimal("0.5")
  let theta = newDecimal("0.00001")
  const seed = 42
  
  initRand(seed)
  let ofbarcAgent = Agent(
    id: Id(0),
    opinions: @[(topic, newDecimal("0"))].toTable,
    belief: toFormula("11110000"),
    values: values,
    alpha: alpha,
  ).doOfAndBarcUntilStable(@[topic], 0, theta)

  initRand(seed)  # reset it
  var agent = Agent(
    id: Id(1),
    opinions: @[(topic, newDecimal("0"))].toTable,
    belief: toFormula("11110000"),
    values: values,
    alpha: alpha,
  )
  
  while true:
    let mid = agent.opinionFormation(@[topic], 0)
    let updated = mid.beliefAlignment(@[topic], 0, UpdatingStrategy.barc)
    let haveOpinionsConverged = distance(agent.opinions, updated.opinions) <= theta
    let haveBeliefsConverged = distance(agent.belief, updated.belief) == 0
    agent = updated
    if haveOpinionsConverged and haveBeliefsConverged:
      break
  
  check distance(agent.opinions, ofbarcAgent.opinions) <= theta
  check distance(agent.belief, ofbarcAgent.belief) == 0
