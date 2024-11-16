import unittest

import interactions/opinionDynamics
import types 
import intbrg
import tables
import nimice

suite "Opinion Dynamics (DeGroot model)":
  let topic = toFormula("0")

  test "Opinions do not update if empty list is given":
    let opinion = toRational(1, 2)
    let agent = Agent(opinions: @[(topic, opinion)].toTable)
    check agent.opinionDynamicsDeGrootmodel(@[topic], @[], 0).opinions[topic] == opinion
  
  test "Opinions will be updated based on other opinions":
    let op1 = toRational(1, 2)
    let op2 = toRational(1, 10)
    let op3 = toRational(1, 5)

    let agent = Agent(opinions: @[(topic, op1)].toTable)
    let others = @[
      Message(opinions: @[(topic, op2)].toTable),
      Message(opinions: @[(topic, op3)].toTable),
    ]
    let expected = (op1 + op2 + op3) * toRational(1, 3)
    check agent.opinionDynamicsDeGrootmodel(@[topic], others, 0).opinions[topic] == expected

suite "Opinion Dynamics (DW model)":
  let topic = toFormula("0")

  test "Opinions do not update if empty list is given":
    let opinion = toRational(1, 2)
    let agent = Agent(opinions: @[(topic, opinion)].toTable)
    check agent.opinionDynamicsDWmodel(@[topic], @[], 0).opinions[topic] == opinion
  
  test "Opinions will be updated based on other opinions":
    let mu = toRational(1, 4)
    let op1 = toRational(1, 2)
    let op2 = toRational(1, 10)
    let op3 = toRational(1, 5)

    let agent = Agent(opinions: @[(topic, op1)].toTable, mu: mu)
    let others = @[
      Message(opinions: @[(topic, op2)].toTable),
      Message(opinions: @[(topic, op3)].toTable),
    ]
    let expected = (toRational(1, 1) - mu) * op1 + mu * (op2 + op3) * toRational(1, 2)
    check agent.opinionDynamicsDWmodel(@[topic], others, 0).opinions[topic] == expected