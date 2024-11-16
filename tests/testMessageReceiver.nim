import unittest

import intbrg
import interactions/messageReceiver
import types
import sets
import tables
import nimice

proc simulatorInitializer(
  ops: seq[Opinion], 
  bels: seq[Formulae], 
  eps: Rational, 
  delta: int,
  neighbors: seq[HashSet[Id]],
  topic: Formulae,
): Simulator =
  assert ops.len == bels.len
  assert bels.len == neighbors.len
  var sim = Simulator(agents: @[])
  for i in 0..<ops.len:
    sim.agents.add(
      Agent(
        id: Id(i),
        opinions: @[(topic, ops[i])].toTable,
        belief: bels[i],
        neighbors: neighbors[i],
        epsilon: eps,
        delta: delta,
      )
    )
  return sim

suite "Message Receiver":
  let ops = @[toRational(0, 1), toRational(1, 5), toRational(1, 1)]
  let bels = @[toFormula("1000"), toFormula("0100"), toFormula("0011")]
  let topic = toFormula("0001")
  let activated = @[Id(0), Id(1), Id(2)]
  let neighbors = @[
    toHashSet(@[Id(1)]),
    toHashSet(@[Id(0), Id(2)]),
    toHashSet(@[Id(1)]),
  ]
  let expecteds = @[
    Message(
      author: Id(0), 
      opinions: @[(topic, ops[0])].toTable, 
      belief: bels[0]
    ),
    Message(
      author: Id(1), 
      opinions: @[(topic, ops[1])].toTable, 
      belief: bels[1]
    ),
    Message(
      author: Id(2), 
      opinions: @[(topic, ops[2])].toTable, 
      belief: bels[2]
    )
  ]

  test "no filtering (i.e., all messages are acceptable)":
    let simulator = simulatorInitializer(ops, bels, toRational(1, 1), 8, neighbors, topic)
    let id2msg = simulator.receiveMessages(activated)

    for idx in 0..<ops.len:
      block agent:
        let message = id2msg[Id(idx)]
        check message.acceptables.len == simulator.agents[idx].neighbors.len
        for id in neighbors[idx]:
          let expected = Message(
            author: id, 
            opinions: @[(topic, ops[int(id)])].toTable, 
            belief: bels[int(id)]
          )
          check message.acceptables.contains(expected)
        check message.unacceptables.len == 0
  
  test "filtering based on opinions":
    let simulator = simulatorInitializer(ops, bels, toRational(1, 5), 8, neighbors, topic)
    let id2msg = simulator.receiveMessages(activated)

    block agent0:
      let message = id2msg[Id(0)]
      check message.acceptables.len + message.unacceptables.len == neighbors[0].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 0
      check message.acceptables.contains(expecteds[1])
    
    block agent1:
      let message = id2msg[Id(1)]
      check message.acceptables.len + message.unacceptables.len == neighbors[1].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 1
      check message.acceptables.contains(expecteds[0])
      check message.unacceptables.contains(expecteds[2])
    
    block agent2:
      let message = id2msg[Id(2)]
      check message.acceptables.len + message.unacceptables.len == neighbors[2].len
      check message.acceptables.len == 0
      check message.unacceptables.len == 1
      check message.unacceptables.contains(expecteds[1])

  test "filtering based on beliefs":
    let simulator = simulatorInitializer(ops, bels, toRational(1, 1), 2, neighbors, topic)
    let id2msg = simulator.receiveMessages(activated)

    block agent0:
      let message = id2msg[Id(0)]
      check message.acceptables.len + message.unacceptables.len == neighbors[0].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 0
      check message.acceptables.contains(expecteds[1])
    
    block agent1:
      let message = id2msg[Id(1)]
      check message.acceptables.len + message.unacceptables.len == neighbors[1].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 1
      check message.acceptables.contains(expecteds[0])
      check message.unacceptables.contains(expecteds[2])
    
    block agent2:
      let message = id2msg[Id(2)]
      check message.acceptables.len + message.unacceptables.len == neighbors[2].len
      check message.acceptables.len == 0
      check message.unacceptables.len == 1
      check message.unacceptables.contains(expecteds[1])

  test "both filtering":
    let simulator = simulatorInitializer(ops, bels, toRational(1, 5), 1, neighbors, topic)
    let id2msg = simulator.receiveMessages(activated)

    for idx in 0..<ops.len:
      block agent:
        let message = id2msg[Id(idx)]
        check message.unacceptables.len == simulator.agents[idx].neighbors.len
        for id in neighbors[idx]:
          check message.unacceptables.contains(expecteds[int(id)])
        check message.acceptables.len == 0