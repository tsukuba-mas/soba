import unittest

include interactions/recommendation
import intbrg

suite "argmin/argmax for DifferenceInfo":
  let infos = @[
    DifferenceInfo(
      opinions: newDecimal("0.2"),
      beliefs: 2,
      id: Id(0),
    ),
    DifferenceInfo(
      opinions: newDecimal("0.2"),
      beliefs: 4,
      id: Id(1),
    ),
    DifferenceInfo(
      opinions: newDecimal("0.4"),
      beliefs: 2,
      id: Id(2),
    ),
    DifferenceInfo(
      opinions: newDecimal("0.4"),
      beliefs: 4,
      id: Id(3),
    ),
  ]

  test "argmin + oponly":
    let selected = infos.argmin(Agent(agentOrder: AgentOrder.opinion))
    check selected.len == 2
    check Id(0) in selected
    check Id(1) in selected

  test "argmax + oponly":
    let selected = infos.argmax(Agent(agentOrder: AgentOrder.opinion))
    check selected.len == 2
    check Id(2) in selected
    check Id(3) in selected

  test "argmin + bronly":
    let selected = infos.argmin(Agent(agentOrder: AgentOrder.belief))
    check selected.len == 2
    check Id(0) in selected
    check Id(2) in selected

  test "argmax + bronly":
    let selected = infos.argmax(Agent(agentOrder: AgentOrder.belief))
    check selected.len == 2
    check Id(1) in selected
    check Id(3) in selected

  test "argmin + opinion -> belief":
    let selected = infos.argmin(Agent(agentOrder: AgentOrder.opbel))
    check selected.len == 1
    check Id(0) in selected

  test "argmax + opinion -> belief":
    let selected = infos.argmax(Agent(agentOrder: AgentOrder.opbel))
    check selected.len == 1
    check Id(3) in selected

  test "argmin + belief -> opinion":
    let selected = infos.argmin(Agent(agentOrder: AgentOrder.belop))
    check selected.len == 1
    check Id(0) in selected

  test "argmax + belief -> opinion":
    let selected = infos.argmax(Agent(agentOrder: AgentOrder.belop))
    check selected.len == 1
    check Id(3) in selected


proc genAgent(msg: Message, agentOrder: AgentOrder, rewriting: RewritingStrategy): Agent =
  Agent(
    id: Id(0),
    neighbors: @[Id(1), Id(2), Id(3)].toHashSet,
    opinions: msg.opinions,
    belief: msg.belief,
    epsilon: "0.1".newDecimal,
    delta: 2,
    agentOrder: AgentOrder.opinion,
    rewritingStrategy: rewriting,
  )

suite "Recommendation":
  initRand(42, 1)
  let topic = "11110000".toFormula
  let messages = @[
    Message(opinions: @[(topic, "0.5".newDecimal)].toTable, belief: "11110000".toFormula, author: Id(0)),

    # Neighbors
    Message(opinions: @[(topic, "0.25".newDecimal)].toTable, belief: "11100000".toFormula, author: Id(1)),
    Message(opinions: @[(topic, "0.75".newDecimal)].toTable, belief: "10000000".toFormula, author: Id(2)),
    Message(opinions: @[(topic, "1.0".newDecimal)].toTable, belief: "00001111".toFormula, author: Id(3)),

    # Non-neighbors
    Message(opinions: @[(topic, "0.4".newDecimal)].toTable, belief: "11101000".toFormula, author: Id(4)),
    Message(opinions: @[(topic, "0.45".newDecimal)].toTable, belief: "1110000".toFormula, author: Id(5)),
    Message(opinions: @[(topic, "0.9".newDecimal)].toTable, belief: "00000001".toFormula, author: Id(6))
  ]
  let t_messages = messages.mapIt((it.author, it)).toTable
  let n = messages.len

  
  test "is not following":
    let agent = messages[0].genAgent(AgentOrder.opinion, RewritingStrategy.random)
    check not agent.isNotFollowing(Id(1))
    check not agent.isNotFollowing(Id(2))
    check agent.isNotFollowing(Id(4))

  test "none":
    let agent = messages[0].genAgent(AgentOrder.opinion, RewritingStrategy.none)
    check agent.recommendUser(n, t_messages).isNone()
  
  test "randomly":
    let agent = messages[0].genAgent(AgentOrder.opinion, RewritingStrategy.random)
    check agent.recommendRandomly(n).get in @[Id(4), Id(5), Id(6)]

  test "swapMaxMin (opinion)":
    let agent = messages[0].genAgent(AgentOrder.opinion, RewritingStrategy.swapMaxMin)
    check agent.getUnfollowedAgent(t_messages, @[]) == some(Id(3))
    check agent.recommendUser(n, t_messages) == some(Id(5))
    check agent.canUpdateNeighbors(some(messages[3]), some(messages[5]))

  test "swapMaxMin (belief)":
    let agent = messages[0].genAgent(AgentOrder.belief, RewritingStrategy.swapMaxMin)
    check agent.getUnfollowedAgent(t_messages, @[]) == some(Id(3))
    check agent.recommendUser(n, t_messages) in @[some(Id(4)), some(Id(5))]
    check agent.canUpdateNeighbors(some(messages[3]), some(messages[4]))
    check agent.canUpdateNeighbors(some(messages[3]), some(messages[5]))

  test "swapMaxMin (opbel)":
    let agent = messages[0].genAgent(AgentOrder.opbel, RewritingStrategy.swapMaxMin)
    check agent.getUnfollowedAgent(t_messages, @[]) == some(Id(3))
    check agent.recommendUser(n, t_messages) == some(Id(5))
    # distance between 0 and 3: opinions 0.5, beliefs: 8
    # distance between 0 and 5: opinions 0.05, beliefs: 1
    # Hence (distance 0-1) > (distance 0-5) where > is the order based on opbel
    check agent.canUpdateNeighbors(some(messages[3]), some(messages[5]))

  test "swapMaxMin(belop)":
    let agent = messages[0].genAgent(AgentOrder.belop, RewritingStrategy.swapMaxMin)
    check agent.getUnfollowedAgent(t_messages, @[]) == some(Id(3))
    check agent.recommendUser(n, t_messages) == some(Id(5))
    # distance between 0 and 3: opinions 0.5, beliefs: 8
    # distance between 0 and 5: opinions 0.05, beliefs: 1
    # Hence (distance 0-3) > (distance 0-5) where > is the order based on belop
    check agent.canUpdateNeighbors(some(messages[3]), some(messages[5]))


    
    
