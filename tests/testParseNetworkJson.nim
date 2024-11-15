import unittest

include argumentParser

suite "Network Json Parser":
  const agents = 3
  const seed = 42
  initRand(seed)
  let ids = (0..<agents).toSeq.mapIt(Id(it))

  test "if nothing is given":
    let expected = @[
      (ids[0], [ids[1], ids[2]].toHashSet),
      (ids[1], [ids[0], ids[2]].toHashSet),
      (ids[2], [ids[0], ids[1]].toHashSet),
    ].toTable
    check "".parseNetworkJson(3) == expected

  test "initialize via json":
    let json = """{"0": [1], "1": [0,2], "2": [1]}"""
    let expected = @[
      (ids[0], [ids[1]].toHashSet), 
      (ids[1], [ids[0], ids[2]].toHashSet), 
      (ids[2], [ids[1]].toHashSet)
    ].toTable
    check json.parseNetworkJson(3) == expected