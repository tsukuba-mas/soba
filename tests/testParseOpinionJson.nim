import unittest

include argumentParser

suite "Opinion Json Parser":
  const agents = 5
  const topics = @[toFormula("0"), toFormula("1")]
  
  test "when the key is -1 only":
    let opinions = [0.25, 0.75]
    let json = """{"-1":""" & $opinions & """}"""
    let expected = zip(topics, opinions).toSeq.toTable
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), expected)).toTable
  
  test "when all of the values are set":
    let opinions = @[[0.0, 1.0], [0.25, 0.75], [0.5, 0.5], [0.75, 0.25], [1.0, 0.0]]
    let json = "{" & (0..<agents).mapIt("\"" & $it & "\":" & $opinions[it]).join(",") & "}"
    let ts = opinions.mapIt(zip(topics, it).toSeq.toTable)
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), ts[it])).toTable
  
  test "-1 and agent id appear at the same time":
    let wildcard = [0.0, 0.0]
    let opinions = @[[0.0, 1.0], wildcard, [0.5, 0.5], [0.75, 0.25], wildcard]
    let json = "{" & (0..<agents).mapIt("\"" & $it & "\":" & $opinions[it]).join(",") & "}"
    let ts = opinions.mapIt(zip(topics, it).toSeq.toTable)
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), ts[it])).toTable