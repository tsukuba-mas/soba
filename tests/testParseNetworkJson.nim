import unittest

include argumentParser

suite "Network Json Parser":
  test "network":
    let json = """{"0": [1], "1": [0,2], "2": [1]}"""
    let ids = @[Id(0), Id(1), Id(2)]
    let expected = @[
      (ids[0], [ids[1]].toHashSet), 
      (ids[1], [ids[0], ids[2]].toHashSet), 
      (ids[2], [ids[1]].toHashSet)
    ].toTable
    check json.parseNetworkJson(3) == expected