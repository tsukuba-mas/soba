import unittest

include argumentParser

# To avoid strict compare between float numbers ...
proc compare(xs, ys: seq[float]): bool = 
  xs.len == ys.len and (0..<xs.len).toSeq.allIt(abs(xs[it] - ys[it]) <= 1e-7)

suite "Values Json Parser":
  const agents = 5
  let ids = (0..<agents).mapIt(Id(it))
  
  test "when the key is -1 only":
    let values = (0..<8).toSeq.mapIt(it.toFloat / 7.0)
    let json = """{"-1":[""" & values.mapIt($it).join(",") & """]}"""
    let actual = json.parseValuesJson(agents)
    let expected = (0..<agents).mapIt((Id(it), values)).toTable
    check ids.allIt(compare(actual[it], expected[it]))
  
  test "when all of the values are set":
    let values = @[
      @[0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08],
      @[0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18],
      @[0.21, 0.22, 0.23, 0.24, 0.25, 0.26, 0.27, 0.28],
      @[0.31, 0.32, 0.33, 0.34, 0.35, 0.36, 0.37, 0.38],
      @[0.41, 0.42, 0.43, 0.44, 0.45, 0.46, 0.47, 0.48],
    ]
    let json = "{" & (0..<agents).mapIt("\"" & $it & "\":[" & values[it].mapIt($it).join(",") & "]").join(",") & "}"
    let actual = json.parseValuesJson(agents)
    let expected = (0..<agents).mapIt((Id(it), values[it])).toTable
    check ids.allIt(compare(actual[it], expected[it]))
  
  test "-1 and agent id appear at the same time":
    let fixed = (0..<8).toSeq.mapIt(it.toFloat / 7.0)
    let values = @[
      fixed,
      @[0.11, 0.12, 0.13, 0.14, 0.15, 0.16, 0.17, 0.18],
      @[0.21, 0.22, 0.23, 0.24, 0.25, 0.26, 0.27, 0.28],
      fixed,
      @[0.41, 0.42, 0.43, 0.44, 0.45, 0.46, 0.47, 0.48],
    ]
    let json = "{\"-1\":[" & fixed.mapIt($it).join(",") & "]," & (0..<agents).mapIt("\"" & $it & "\":[" & values[it].mapIt($it).join(",") & "]").join(",") & "}"
    let actual = json.parseValuesJson(agents)
    let expected = (0..<agents).mapIt((Id(it), values[it])).toTable
    check ids.allIt(compare(actual[it], expected[it]))