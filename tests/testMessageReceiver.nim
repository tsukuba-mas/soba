import unittest

import intbrg
import interactions/messageReceiver
import types
import sets
import tables

proc simulatorInitializer(
  ops: seq[float], 
  bels: seq[Formulae], 
  eps: float, 
  delta: int,
  neighbors: seq[HashSet[Id]],
  fs: FilterStrategy,
): Simulator =
  assert ops.len == bels.len
  assert bels.len == neighbors.len
  var sim = Simulator(agents: @[])
  for i in 0..<ops.len:
    sim.agents.add(
      Agent(
        id: Id(i),
        opinion: ops[i],
        belief: bels[i],
        neighbors: neighbors[i],
        epsilon: eps,
        delta: delta,
        filterStrategy: fs,
      )
    )
  return sim

suite "Message Receiver":
  let ops = @[0.0, 0.2, 1.0]
  let bels = @[toFormula("1000"), toFormula("0100"), toFormula("0011")]
  let activated = @[Id(0), Id(1), Id(2)]
  let neighbors = @[
    toHashSet(@[Id(1)]),
    toHashSet(@[Id(0), Id(2)]),
    toHashSet(@[Id(1)]),
  ]

  test "no filtering":
    let simulator = simulatorInitializer(ops, bels, 1.0, 4, neighbors, FilterStrategy.all)
    let id2msg = simulator.receiveMessages(activated)

    for idx in 0..<ops.len:
      block agent:
        let message = id2msg[Id(idx)]
        check message.acceptables.len == simulator.agents[idx].neighbors.len
        for id in neighbors[idx]:
          check message.acceptables.contains(Message(author: id, opinion: ops[int(id)], belief: bels[int(id)]))
        check message.unacceptables.len == 0
  
  test "filtering based on opinions":
    let simulator = simulatorInitializer(ops, bels, 0.2, 4, neighbors, FilterStrategy.obounded)
    let id2msg = simulator.receiveMessages(activated)

    block agent0:
      let message = id2msg[Id(0)]
      check message.acceptables.len + message.unacceptables.len == neighbors[0].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 0
      check message.acceptables.contains(Message(author: Id(1), opinion: ops[1], belief: bels[1]))
    
    block agent1:
      let message = id2msg[Id(1)]
      check message.acceptables.len + message.unacceptables.len == neighbors[1].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 1
      check message.acceptables.contains(Message(author: Id(0), opinion: ops[0], belief: bels[0]))
      check message.unacceptables.contains(Message(author: Id(2), opinion: ops[2], belief: bels[2]))
    
    block agent2:
      let message = id2msg[Id(2)]
      check message.acceptables.len + message.unacceptables.len == neighbors[2].len
      check message.acceptables.len == 0
      check message.unacceptables.len == 1
      check message.unacceptables.contains(Message(author: Id(1), opinion: ops[1], belief: bels[1]))

  test "filtering based on beliefs":
    let simulator = simulatorInitializer(ops, bels, 1.0, 2, neighbors, FilterStrategy.bbounded)
    let id2msg = simulator.receiveMessages(activated)

    block agent0:
      let message = id2msg[Id(0)]
      check message.acceptables.len + message.unacceptables.len == neighbors[0].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 0
      check message.acceptables.contains(Message(author: Id(1), opinion: ops[1], belief: bels[1]))
    
    block agent1:
      let message = id2msg[Id(1)]
      check message.acceptables.len + message.unacceptables.len == neighbors[1].len
      check message.acceptables.len == 1
      check message.unacceptables.len == 1
      check message.acceptables.contains(Message(author: Id(0), opinion: ops[0], belief: bels[0]))
      check message.unacceptables.contains(Message(author: Id(2), opinion: ops[2], belief: bels[2]))
    
    block agent2:
      let message = id2msg[Id(2)]
      check message.acceptables.len + message.unacceptables.len == neighbors[2].len
      check message.acceptables.len == 0
      check message.unacceptables.len == 1
      check message.unacceptables.contains(Message(author: Id(1), opinion: ops[1], belief: bels[1]))

  test "both filtering":
    let simulator = simulatorInitializer(ops, bels, 0.2, 1, neighbors, FilterStrategy.both)
    let id2msg = simulator.receiveMessages(activated)

    for idx in 0..<ops.len:
      block agent:
        let message = id2msg[Id(idx)]
        check message.unacceptables.len == simulator.agents[idx].neighbors.len
        for id in neighbors[idx]:
          check message.unacceptables.contains(Message(author: id, opinion: ops[int(id)], belief: bels[int(id)]))
        check message.acceptables.len == 0