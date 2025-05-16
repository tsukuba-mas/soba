import unittest

include interactions/recommendation
import intbrg

suite "Recommendation":
  initRand(42, 1)
  test "is not following":
    let agent = Agent(id: Id(0), neighbors: @[Id(1), Id(2)].toHashSet)
    check not agent.isNotFollowing(Id(0))
    check not agent.isNotFollowing(Id(1))
    check agent.isNotFollowing(Id(3))
  
  test "randomly":
    let agent = Agent(id: Id(0), neighbors: @[Id(1), Id(2)].toHashSet)
    check agent.recommendRandomly(4).get == Id(3)

  test "swapMaxMin":
    let topic = "11110000".toFormula
    let agent = Agent(
      id: Id(0),
      neighbors: @[Id(1), Id(2), Id(3)].toHashSet,
      opinions: @[(topic, "0.5".newDecimal)].toTable,
      belief: "11110000".toFormula,
      epsilon: "0.1".newDecimal,
      delta: 2,
      opDistWeight: "0.5".newDecimal,
      rewritingStrategy: RewritingStrategy.swapMaxMin,
    )
    let messages = @[
      Message(opinions: agent.opinions, belief: agent.belief, author: Id(0)),

      # concordant neighbor (distance (0 + 1/8) * 0.5 = 0.0625)
      Message(opinions: @[(topic, "0.5".newDecimal)].toTable, belief: "11100000".toFormula, author: Id(1)),

      # discordant neighbor (distance (0.25 + 3/8) * 0.5 = 0.3125)
      Message(opinions: @[(topic, "0.75".newDecimal)].toTable, belief: "10000000".toFormula, author: Id(2)),

      # discordant neighbor (distance (0.5 + 8/8) * 0.5 = 0.75)
      Message(opinions: @[(topic, "1.0".newDecimal)].toTable, belief: "00001111".toFormula, author: Id(3)),

      # concordant non-neighbor (distance (0.1 + 2/8) * 0.5 = 0.175)
      Message(opinions: @[(topic, "0.4".newDecimal)].toTable, belief: "11101000".toFormula, author: Id(4)),

      # concordant non-neighbor (distance (0.05 + 1/8) * 0.5 = 0.0875)
      Message(opinions: @[(topic, "0.45".newDecimal)].toTable, belief: "1110000".toFormula, author: Id(5)),

      # discordant non-neighbor
      Message(opinions: @[(topic, "0.9".newDecimal)].toTable, belief: "00000001".toFormula, author: Id(6))
    ]

    check agent.getUnfollowedAgent(messages, @[]) == some(Id(3))
    check agent.recommendUser(7, messages) == some(Id(5))
    check agent.canUpdateNeighbors(some(messages[3]), some(messages[5]))
