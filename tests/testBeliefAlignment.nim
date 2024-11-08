import unittest

include interactions/relaxDissonance

# Here is the merging results with topic 1100 (x is don't care):
# belief --> merged result
# 11xx --> 1100
# 10xx --> 1000
# 01xx --> 0100
# 0001 --> 0101
# 0010 --> 1010
# 0011 --> 1111

suite "utility procedure: hamming distance":
  test "return 0 if same formula is passed":
    let phi = toFormula("11110000")
    check hamming(phi, phi) == 0
  
  test "return >0 if different formula is passed":
    check hamming(toFormula("10101010"), toFormula("01010101")) == 8
    check hamming(toFormula("11110000"), toFormula("11111111")) == 4

suite "utility procedure: argmin":
  test "for string":
    let by = "x"
    let dist = proc (x, y: string): int = len(x) - len(y)
    let longStr = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    check argmin(@[longStr], by, dist) == @[longStr]
    check argmin(@["aaa", "aa", "a"], by, dist) == @["a"]
    check argmin(@["aa", "a", ""], by, dist) == @[""]
    check argmin(@["a", "b", "c"], by, dist) == @["a", "b", "c"]
  
  test "for original types":
    type Foo = ref object
      val: float
    proc `==`(x, y: Foo): bool = x.val == y.val
    proc `==`(xs, ys: seq[Foo]): bool = 
      if xs.len != ys.len:
        return false
      else:
        for (x, y) in zip(xs, ys):
          if x != y:
            return false
        return true
    
    let by = Foo(val: 0.5)
    let dist = proc (x, y: Foo): float = x.val * y.val
    check argmin(@[Foo(val: 2.0), Foo(val: 1.0)], by, dist) == @[Foo(val: 1.0)]
    check argmin(@[Foo(val: -1.0), Foo(val: 1.0), Foo(val: 0.0)], by, dist) == @[Foo(val: -1.0)]
    check argmin(@[Foo(val: 1.0), Foo(val: 1.0)], by, dist) == @[Foo(val: 1.0), Foo(val: 1.0)]

suite "Belief Alignment":
  let values = @[0.0, 0.1, 0.8, 1.0]
  let topic = toFormula("1100")
  initRand(42)

  test "get atomic props":
    check values.getNumberOfAtomicProps() == 2
  
  test "generate cache":
    generateOpinionToBeliefCache(topic, values)
    let possibleOpinions = opinion2beliefCache.keys.toSeq
    let expected = @[0.0, 0.05, 0.1, 0.4, 0.475, 0.55]
    check possibleOpinions.len == expected.len
    check expected.allIt(possibleOpinions.contains(it))

  test "belief alignment for already coherent agent":
    let agent = Agent(opinion: 0.05, belief: toFormula("1101"))
    check agent.beliefAlignment(topic, 0).belief == toFormula("1101")
  
  test "belief alignment without distance sorting and random choice":
    let agent = Agent(opinion: 0.5, belief: toFormula("1111"))
    check agent.beliefAlignment(topic, 0).belief == toFormula("0011")
  
  test "belief alignment with sorting with distance sorting and without random choice":
    let agent = Agent(opinion: 0.4375, belief: toFormula("0010"))
    check agent.beliefAlignment(topic, 0).belief == toFormula("0010")
  
  test "belief alignment with sorting with distance sorting and random choice":
    let agent = Agent(opinion: 0.03, belief: toFormula("1101"))

    # To make defining test easily, use another values
    let v2 = @[0.5, 0.5, 0.0, 0.0]
    opinion2beliefCache.clear()
    generateOpinionToBeliefCache(topic, v2)

    let alignedBelief = agent.beliefAlignment(topic, 0).belief 
    check alignedBelief == toFormula("0001") or alignedBelief == toFormula("0011")
    
