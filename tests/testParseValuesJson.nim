import unittest

include argumentParser

suite "Values Json Parser":
  const agents = 5
  const atoms = 3
  let ids = (0..<agents).mapIt(Id(it))
  
  test "when the key is -1 only":
    let values = (0..7).toSeq.mapIt(it // 7)
    let json = "{\"-1\":[\"" & values.mapIt($it).join("\",\"") & "\"]}"
    let actual = json.parseValuesJson(agents, atoms)
    let expected = (0..<agents).mapIt((Id(it), values)).toTable
    check ids.allIt(actual[it] == expected[it])
  
  test "when all of the values are set":
    let values = @[
      (1..8).toSeq.mapIt(it // 100),
      (1..8).toSeq.mapIt((10 + it) // 100),
      (1..8).toSeq.mapIt((20 + it) // 100),
      (1..8).toSeq.mapIt((30 + it) // 100),
      (1..8).toSeq.mapIt((40 + it) // 100),
    ]
    var subjson: seq[string] = @[]
    for idx, value in values:
      subjson.add("\"" & $idx & "\":[\"" & value.mapIt($it).join("\",\"") & "\"]")
    let json = "{" & subjson.join(",") & "}"
    let actual = json.parseValuesJson(agents, atoms)
    let expected = (0..<agents).mapIt((Id(it), values[it])).toTable
    check ids.allIt(actual[it] == expected[it])
  
  test "-1 and agent id appear at the same time":
    let fixed = (0..7).toSeq.mapIt(it // 7)
    let values = @[
      fixed,
      (1..8).toSeq.mapIt((10 + it) // 100),
      (1..8).toSeq.mapIt((20 + it) // 100),
      fixed,
      (1..8).toSeq.mapIt((40 + it) // 100),
    ]
    var subjson = @["\"-1\":[\"" & fixed.mapIt($it).join("\",\"") & "\"]"]
    for idx, value in values:
      if value == fixed:
        continue
      subjson.add("\"" & $idx & "\":[\"" & value.mapIt($it).join("\",\"") & "\"]")
    let json = "{" & subjson.join(",") & "}"
    let actual = json.parseValuesJson(agents, atoms)
    let expected = (0..<agents).mapIt((Id(it), values[it])).toTable
    check ids.allIt(actual[it] == expected[it])