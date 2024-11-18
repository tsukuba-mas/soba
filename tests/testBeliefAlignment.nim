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
    let dist = proc (x: string): int = len(x) - len(by)
    let longStr = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    check argmin(@[longStr], dist) == @[longStr]
    check argmin(@["aaa", "aa", "a"], dist) == @["a"]
    check argmin(@["aa", "a", ""], dist) == @[""]
    check argmin(@["a", "b", "c"], dist) == @["a", "b", "c"]
  
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
    let dist = proc (x: Foo): float = x.val * by.val
    check argmin(@[Foo(val: 2.0), Foo(val: 1.0)], dist) == @[Foo(val: 1.0)]
    check argmin(@[Foo(val: -1.0), Foo(val: 1.0), Foo(val: 0.0)], dist) == @[Foo(val: -1.0)]
    check argmin(@[Foo(val: 1.0), Foo(val: 1.0)], dist) == @[Foo(val: 1.0), Foo(val: 1.0)]

suite "Belief Alignment (Random choose)":
  let values = @[0 // 10, 1 // 10, 8 // 10, 10 // 10]
  let topic = toFormula("1100")
  initRand(42)

  test "get atomic props":
    check values.getNumberOfAtomicProps() == 2
  
  test "generate cache":
    generateOpinionToBeliefCache(@[topic], values)
    let possibleOpinions = opinion2beliefCache.keys.toSeq
    let expected = @[
      newDecimal("0"), newDecimal("0.05"), newDecimal("0.1"), newDecimal("0.4"),
      newDecimal("0.475"), newDecimal("0.55"),
    ]
    check possibleOpinions.len == expected.len
    check expected.allIt(possibleOpinions.contains(@[(topic, it)].toTable))

  test "belief alignment for already coherent agent":
    let agent = Agent(
      opinions: @[(topic, newDecimal("0.05"))].toTable, 
      belief: toFormula("1101")
    )
    check agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief == toFormula("1101")
  
  test "belief alignment without distance sorting and random choice":
    let agent = Agent(
      opinions: @[(topic, newDecimal("0.5"))].toTable,
      belief: toFormula("1111")
    )
    check agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief == toFormula("0011")
  
  test "belief alignment with sorting with distance sorting and without random choice":
    let agent = Agent(
      opinions: @[(topic, newDecimal("0.4375"))].toTable, 
      belief: toFormula("0010")
    )
    check agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief == toFormula("0010")
  
  test "belief alignment with sorting with distance sorting and random choice":
    let agent = Agent(
      opinions: @[(topic, newDecimal("0.03"))].toTable, 
      belief: toFormula("1101")
    )

    # To make defining test easily, use another values
    let v2 = @[
      1 // 2, 1 // 2, 0 // 1, 0 // 1
    ]
    opinion2beliefCache.clear()
    generateOpinionToBeliefCache(@[topic], v2)

    let alignedBelief = agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief 
    check alignedBelief == toFormula("0001") or alignedBelief == toFormula("0011")
    
suite "Belief Alignment (deterministic choice with respect to values)":
  let values = @[0 // 10, 1 // 10, 8 // 10, 10 // 10]
  let topic = toFormula("1100")
  initRand(42)
  generateOpinionToBeliefCache(@[topic], values)
  setPrec(10)  # default precise

  test "choose the best one wrt values":
    let b1 = toFormula("1100")
    let b2 = toFormula("1101")
    let b3 = toFormula("1111")
    check @[b1].chooseBest(values) == b1
    check @[b1, b2].chooseBest(values) == b2
    check @[b3, b2, b1].chooseBest(values) == b3

  test "belief alignment for already coherent agent":
    opinion2beliefCache.clear()
    let agent1 = Agent(
     opinions: @[(topic, newDecimal("0.05"))].toTable, 
      belief: toFormula("1101"), 
      values: values
    )
    check agent1.beliefAlignment(@[topic], 0, UpdatingStrategy.bavm).belief == toFormula("1111")
    let agent2 = Agent(
      opinions: @[(topic, newDecimal("0.05"))].toTable, 
      belief: toFormula("1111"), 
      values: values
    )
    check agent2.beliefAlignment(@[topic], 0, UpdatingStrategy.bavm).belief == toFormula("1111")

  test "if there exist some beliefs which minimize the error":
    opinion2beliefCache.clear()
    let cv = @[7 // 7, 3 // 7, 6 // 7, 2 // 7, 5 // 7, 1 // 7, 4 // 7, 0 // 7]
    let topics = @[toFormula("11110000"), toFormula("00001111")]
    let agent = Agent(
      opinions: @[
        (topics[0], newDecimal(7) / newDecimal(32)),
        (topics[1], newDecimal(19) / newDecimal(28)),
      ].toTable,
      belief: toFormula("01001111"),
      values: cv,
    )

    # In theory, candidates which minimize the error should be either of them:
    let candidates = selectBeliefsWithMinimalError(agent.opinions, topics, cv)
    check candidates.len == 2
    check candidates.contains(toFormula("00011010"))
    check candidates.contains(toFormula("00011000"))

    # And by choosing the best one with respect to the values, the answer is:
    check agent.beliefAlignment(topics, 0, UpdatingStrategy.bavm).belief == toFormula("00011010")
