import unittest

import interactions/opinionDynamics
import types 

suite "Opinion Dynamics (DeGroot model)":
  test "Opinions do not update if empty list is given":
    let opinion = 0.5
    let agent = Agent(opinion: opinion)
    check agent.opinionDynamicsDeGrootmodel(@[], 0).opinion == opinion
  
  test "Opinions will be updated based on other opinions":
    let op1 = 0.5
    let op2 = 0.1
    let op3 = 0.2

    let agent = Agent(opinion: op1)
    let others = @[
      Message(opinion: op2),
      Message(opinion: op3),
    ]
    let expected = (op1 + op2 + op3) / 3.0
    check agent.opinionDynamicsDeGrootmodel(others, 0).opinion == expected

suite "Opinion Dynamics (DW model)":
  test "Opinions do not update if empty list is given":
    let opinion = 0.5
    let agent = Agent(opinion: opinion)
    check agent.opinionDynamicsDWmodel(@[], 0).opinion == opinion
  
  test "Opinions will be updated based on other opinions":
    let mu = 0.25
    let op1 = 0.5
    let op2 = 0.1
    let op3 = 0.2

    let agent = Agent(opinion: op1, mu: mu)
    let others = @[
      Message(opinion: op2),
      Message(opinion: op3),
    ]
    let expected = (1.0 - mu) * op1 + mu * (op2 + op3) / 2.0
    check agent.opinionDynamicsDWmodel(others, 0).opinion == expected