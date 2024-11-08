import unittest

include argumentParser

suite "Belief Json Parser":
  const agents = 5
  
  test "when the key is -1 only":
    let belstr = "11110000"
    let json = """{"-1":"""" & belstr & """"}"""
    check json.parseBeliefJson(agents) == (0..<agents).mapIt((Id(it), toFormula(belstr))).toTable
  
  test "when all of the values are set":
    let bels = @["10000000", "01000000", "00100000", "00010000", "00001000"]
    let json = "{" & (0..<agents).mapIt("\"" & $it & "\":\"" & bels[it] & "\"").join(",") & "}"
    check json.parseBeliefJson(agents) == (0..<agents).mapIt((Id(it), toFormula(bels[it]))).toTable
  
  test "-1 and agent id appear at the same time":
    let wildcard = "00000001"
    let bels = @["10000000", wildcard, "00100000", "00010000", wildcard]
    let json = """{"-1":"""" & wildcard & """",""" & (0..<agents).mapIt("\"" & $it & "\":\"" & bels[it] & "\"").join(",") & "}"
    check json.parseBeliefJson(agents) == (0..<agents).mapIt((Id(it), toFormula(bels[it]))).toTable