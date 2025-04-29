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
