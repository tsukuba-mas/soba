import unittest

include argumentParser

suite "Opinion Json Parser":
  const agents = 5
  const topics = @[toFormula("0"), toFormula("1")]
  const seed = 42
  initRand(seed)

  test "if nothing is specified":
    let actual = "".parseOpinionJson(agents, topics)
    for idx in 0..<agents:
      let id = Id(idx)
      check actual[id].len == topics.len
      for topic in topics:
        check newDecimal(0) <= actual[id][topic]
        check actual[id][topic] <= newDecimal(1)
  
  test "when the key is -1 only":
    let input = [1 // 4, 3 // 4]
    let json = "{\"-1\":[" & input.mapIt("\"" & $it & "\"").join(",") & "]}"
    let expected = zip(topics, input.map(toDecimal)).toSeq.toTable
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), expected)).toTable
  
  test "when all of the values are set":
    let inputs = @[
      [0 // 1, 1 // 1], 
      [1 // 4, 3 // 4], 
      [1 // 2, 1 // 2], 
      [3 // 4, 1 // 4], 
      [1 // 1, 0 // 1],
    ]
    var subjson: seq[string] = @[]
    for idx, input in inputs:
      subjson.add("\"" & $idx & "\":[\"" & input.mapIt($it).join("\",\"") & "\"]")
    let json = "{" & subjson.join(",") & "}"
    let ts = inputs.mapIt(zip(topics, it).mapIt((it[0], it[1].toDecimal)).toSeq.toTable)
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), ts[it])).toTable
  
  test "-1 and agent id appear at the same time":
    let wildcard = [0 // 1, 0 // 1]
    let inputs = @[
      [0 // 1, 1 // 1], 
      wildcard,
      [1 // 2, 1 // 2], 
      [3 // 4, 1 // 4], 
      wildcard,
    ]
    var subjson = @["\"-1\":[\"" & wildcard.mapIt($it).join("\",\"") & "\"]"]
    for idx, input in inputs:
      if input == wildcard:
        continue
      subjson.add("\"" & $idx & "\":[\"" & input.mapIt($it).join("\",\"") & "\"]")
    let json = "{" & subjson.join(",") & "}"
    let ts = inputs.mapIt(zip(topics, it).mapIt((it[0], it[1].toDecimal)).toSeq.toTable)
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), ts[it])).toTable