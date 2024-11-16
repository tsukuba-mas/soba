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
        check toRational(0, 1) <= actual[id][topic]
        check actual[id][topic] <= toRational(1, 1)
  
  test "when the key is -1 only":
    let opinions = [toRational(1, 4), toRational(3, 4)]
    let json = "{\"-1\":[" & opinions.mapIt("\"" & $it & "\"").join(",") & "]}"
    let expected = zip(topics, opinions).toSeq.toTable
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), expected)).toTable
  
  test "when all of the values are set":
    let opinions = @[
      [toRational(0, 1), toRational(1, 1)], 
      [toRational(1, 4), toRational(3, 4)], 
      [toRational(1, 2), toRational(1, 2)], 
      [toRational(3, 4), toRational(1, 4)], 
      [toRational(1, 1), toRational(0, 1)],
    ]
    var subjson: seq[string] = @[]
    for idx, opinion in opinions:
      subjson.add("\"" & $idx & "\":[\"" & opinion.mapIt($it).join("\",\"") & "\"]")
    let json = "{" & subjson.join(",") & "}"
    let ts = opinions.mapIt(zip(topics, it).toSeq.toTable)
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), ts[it])).toTable
  
  test "-1 and agent id appear at the same time":
    let wildcard = [toRational(0, 1), toRational(0, 1)]
    let opinions = @[
      [toRational(0, 1), toRational(1, 1)], 
      wildcard,
      [toRational(1, 2), toRational(1, 2)], 
      [toRational(3, 4), toRational(1, 4)], 
      wildcard,
    ]
    var subjson = @["\"-1\":[\"" & wildcard.mapIt($it).join("\",\"") & "\"]"]
    for idx, opinion in opinions:
      if opinion == wildcard:
        continue
      subjson.add("\"" & $idx & "\":[\"" & opinion.mapIt($it).join("\",\"") & "\"]")
    let json = "{" & subjson.join(",") & "}"
    let ts = opinions.mapIt(zip(topics, it).toSeq.toTable)
    check json.parseOpinionJson(agents, topics) == (0..<agents).mapIt((Id(it), ts[it])).toTable