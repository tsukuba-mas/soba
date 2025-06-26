import unittest

include argumentParser

suite "Network Json Parser":
  const seed = 42

  # test "random network":
  #   let agents = 10
  #   let edges = 20

  #   rngInitializer((0..<agents).toSeq.mapIt(42 + it))

  #   let actual = "".parseNetworkJson(agents, edges, InitNetworkConfig.random)
  #   check actual.keys.toSeq.len == agents
  #   check actual.values.toSeq.mapIt(it.len).sum == edges
  #   check actual.values.toSeq.allIt(it.len > 0)

  # test "random network with lower maximal out degree":
  #   let agents = 10
  #   let edges = 20

  #   rngInitializer((0..<agents).toSeq.mapIt(it + 42))

  #   let actual = "".parseNetworkJson(agents, edges, InitNetworkConfig.randomLowerMOD)
  #   check actual.keys.toSeq.len == agents
  #   check actual.values.toSeq.mapIt(it.len).sum == edges
  #   check actual.values.toSeq.allIt(it.len > 0)

  #   let totallyRandom = "".parseNetworkJson(agents, edges, InitNetworkConfig.random)
  #   let currentMaximalOutDeg = actual.keys.toSeq.mapIt(actual[it].len).max
  #   let totallyRandomOutDeg = totallyRandom.keys.toSeq.mapIt(totallyRandom[it].len).max
  #   check currentMaximalOutDeg <= totallyRandomOutDeg

  test "initialize via json":
    let json = """{"0": [1], "1": [0,2], "2": [1]}"""
    let ids = (0..<3).toSeq.mapIt(Id(it))
    let expected = @[
      (ids[0], [ids[1]].toHashSet), 
      (ids[1], [ids[0], ids[2]].toHashSet), 
      (ids[2], [ids[1]].toHashSet)
    ].toTable
    let parsed1 = json.parseNetworkJson(3, 4, InitNetworkConfig.random)
    let parsed2 = json.parseNetworkJson(3, 4, InitNetworkConfig.randomLowerMOD)

    # Check whether the expected network is generated

    check parsed1.keys.toSeq.toHashSet == expected.keys.toSeq.toHashSet
    check parsed1.keys.toSeq.allIt(parsed1[it] == expected[it])

    # Check whether the result is independent of the configuration
    check parsed1.keys.toSeq.toHashSet == parsed2.keys.toSeq.toHashSet
    check parsed1.keys.toSeq.allIt(parsed1[it] == parsed2[it])
