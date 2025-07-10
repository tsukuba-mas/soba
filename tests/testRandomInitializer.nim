import unittest

include initializer

proc isBetween01(val: Rational): bool =
  let num = val.num
  let den = val.den
  let isNonNegative = num >= 0 and den >= 0
  let isSmallerThan1 = num <= den
  isNonNegative and isSmallerThan1

proc isBetween01(val: Opinion): bool =
  newDecimal(0) <= val and val <= newDecimal(1)

suite "Random initializers":  
  test "opinions":
    rngInitializer(@[42])
    let opinion = generateOpinionRandomly()
    check opinion.isBetween01

  test "beliefs":
    let atoms = 4
    let beliefs = generateBeliefRandomly(atoms)
    check ($beliefs).len == 16
    check not (not beliefs).isTautology()

  test "values":
    let values = generateValuesRandomly(1, 3)
    check values.keys.toSeq.len == 1
    check values[Id(0)].len == 8
    check values[Id(0)].all(isBetween01)

  test "random graph":
    let vs = 10
    let edges = 20
    let graph = generateRandomGraph(vs, edges, true)
    let agents = (0..<vs).toSeq.mapIt(Id(it))
    check agents.allIt(graph[it].len > 0)
    check agents.mapIt(graph[it].len).sum() == edges
