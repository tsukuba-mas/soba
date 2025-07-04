import unittest

import interactions/opinionDynamics
import types 
import intbrg
import tables

suite "Opinion Dynamics (DeGroot model)":
  let topic = toFormula("0")

  test "Opinions do not update if empty list is given":
    let opinion = newDecimal(1) / newDecimal(2)
    var agent = Agent(opinions: @[(topic, opinion)].toTable)
    agent.opinionDynamicsDeGrootmodel(@[topic], @[], 0)
    check agent.opinions[topic] == opinion
  
  test "Opinions will be updated based on other opinions":
    let op1 = newDecimal(1) / newDecimal(2)
    let op2 = newDecimal(1) / newDecimal(10)
    let op3 = newDecimal(1) / newDecimal(5)

    var agent = Agent(opinions: @[(topic, op1)].toTable)
    let others = @[
      Message(opinions: @[(topic, op2)].toTable),
      Message(opinions: @[(topic, op3)].toTable),
    ]
    let expected = (op1 + op2 + op3) * newDecimal(1) / newDecimal(3)
    agent.opinionDynamicsDeGrootmodel(@[topic], others, 0)
    check agent.opinions[topic] == expected

suite "Opinion Dynamics (DW model)":
  let topic = toFormula("0")

  test "Opinions do not update if empty list is given":
    let opinion = newDecimal(1) / newDecimal(2)
    var agent = Agent(opinions: @[(topic, opinion)].toTable)
    agent.opinionDynamicsDWmodel(@[topic], @[], 0)
    check agent.opinions[topic] == opinion
  
  test "Opinions will be updated based on other opinions":
    let mu = newDecimal(1) / newDecimal(4)
    let op1 = newDecimal(1) / newDecimal(2)
    let op2 = newDecimal(1) / newDecimal(10)
    let op3 = newDecimal(1) / newDecimal(5)

    var agent = Agent(opinions: @[(topic, op1)].toTable, mu: mu)
    let others = @[
      Message(opinions: @[(topic, op2)].toTable),
      Message(opinions: @[(topic, op3)].toTable),
    ]
    let expected = (newDecimal(1) / newDecimal(1) - mu) * op1 + mu * (op2 + op3) * newDecimal(1) / newDecimal(2)
    agent.opinionDynamicsDWmodel(@[topic], others, 0)
    check agent.opinions[topic] == expected
