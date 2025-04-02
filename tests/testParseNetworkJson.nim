import unittest

include argumentParser

suite "Network Json Parser":
  const seed = 42
  initRand(seed)

  test "if nothing is given":
    let agents = 10
    let edges = 20
    let actual = "".parseNetworkJson(agents, edges)
    check actual.keys.toSeq.len == agents
    check actual.values.toSeq.mapIt(it.len).sum == edges
    check actual.values.toSeq.allIt(it.len > 0)

  test "initialize via json":
    let json = """{"0": [1], "1": [0,2], "2": [1]}"""
    let ids = (0..<3).toSeq.mapIt(Id(it))
    let expected = @[
      (ids[0], [ids[1]].toHashSet), 
      (ids[1], [ids[0], ids[2]].toHashSet), 
      (ids[2], [ids[1]].toHashSet)
    ].toTable
    check json.parseNetworkJson(3, 4) == expected