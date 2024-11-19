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
    let expected = toFormula("1101")
    let agent = Agent(
      opinions: @[(topic, newDecimal("0.05"))].toTable, 
      belief: expected
    )
    check selectBeliefsWithMinimalError(agent.opinions, @[topic], values).toHashSet == 
      @[toFormula("1100"), toFormula("1101"), toFormula("1110"), toFormula("1111")].toHashSet
    check agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief == expected
  
  test "belief alignment without distance sorting and random choice":
    let agent = Agent(
      opinions: @[(topic, newDecimal("0.5"))].toTable,
      belief: toFormula("1111")
    )
    let expected = toFormula("0011")
    check selectBeliefsWithMinimalError(agent.opinions, @[topic], values).toHashSet == 
      @[expected].toHashSet
    check agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief == expected
  
  test "belief alignment with sorting with distance sorting and without random choice":
    let agent = Agent(
      opinions: @[(topic, newDecimal("0.4375"))].toTable, # 0.4375 = (0.5 + 0.475) / 2
      belief: toFormula("0010")
    )
    let expected = toFormula("0010")
    check selectBeliefsWithMinimalError(agent.opinions, @[topic], values).toHashSet == 
      @[expected, toFormula("0011")].toHashSet
    check agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief == expected
  
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

    let expected = @[toFormula("0001"), toFormula("0011"), toFormula("0010")]
    check selectBeliefsWithMinimalError(agent.opinions, @[topic], v2).toHashSet == expected.toHashSet
    let alignedBelief = agent.beliefAlignment(@[topic], 0, UpdatingStrategy.barc).belief 
    check expected.contains(alignedBelief)
    
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
    let shouldBeSelected = @[toFormula("1111"), toFormula("1110"), toFormula("1101"), toFormula("1100")]
    check selectBeliefsWithMinimalError(agent1.opinions, @[topic], values).toHashSet == shouldBeSelected.toHashSet
    check agent1.beliefAlignment(@[topic], 0, UpdatingStrategy.bavm).belief == toFormula("1111")

    # another test ...
    let agent2 = Agent(
      opinions: @[(topic, newDecimal("0.05"))].toTable, 
      belief: toFormula("1111"), 
      values: values
    )
    check selectBeliefsWithMinimalError(agent2.opinions, @[topic], values).toHashSet == shouldBeSelected.toHashSet
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

suite "Belief Alignment (critical cases)":
  # Here, 'critical case' is when there exists more than one opinions based on beliefs
  # such that they minimize the distance between them and current opinions.
  # Depending on the implementation (especially if opinions are represented as standard float numbers),
  # the outputs can be different from the theory.
  let topic1 = toFormula("11000000")
  let topic2 = toFormula("00000011")
  initRand(42)
  opinion2BeliefCache = @[
    # Case 1
    #[ A ]# (@[(topic1, newDecimal("0.1")), (topic2, newDecimal("1.0"))].toTable, @[toFormula("00000001")]),
    #[ B ]# (@[(topic1, newDecimal("0.1")), (topic2, newDecimal("0.999999"))].toTable, @[toFormula("00000010")]),
    #[ C ]# (@[(topic1, newDecimal("0.10000025")), (topic2, newDecimal("0.99999975"))].toTable, @[toFormula("00000011")]),
    #[ WRONG ANSWER A ]# (@[(topic1, newDecimal("0.1000006")),  (topic2, newDecimal("1.0"))].toTable, @[toFormula("10000000")]),
    #[ WRONG ANSWER B ]# (@[(topic1, newDecimal("0.1000002")),  (topic2, newDecimal("0.9999991"))].toTable, @[toFormula("10000000")]),

    # Case 2
    #[ A ]# (@[(topic1, newDecimal("0.4")), (topic2, newDecimal("0.5"))].toTable, @[toFormula("00000100")]),
    #[ B ]# (@[(topic1, newDecimal("0.6")), (topic2, newDecimal("0.5"))].toTable, @[toFormula("00000101")]),
    #[ C ]# (@[(topic1, newDecimal("0.45")), (topic2, newDecimal("0.45"))].toTable, @[toFormula("00000110")]),
    #[ WRONG ANSWER A ]# (@[(topic1, newDecimal("0.5")),  (topic2, newDecimal("0.39999999"))].toTable, @[toFormula("10000000")]),
    #[ WRONG ANSWER B ]# (@[(topic1, newDecimal("0.549999999")),  (topic2, newDecimal("0.599999999"))].toTable, @[toFormula("10000000")]),
  ].toTable
  setPrec(10)  # default precise
  let possibleOpinions = opinion2BeliefCache.keys.toSeq
  
  test "if one of the opinions differs slightly":
    let eps = newDecimal("1e-8")
    for possible in possibleOpinions:
      let opinion = @[(topic1, possible[topic1]), (topic2, possible[topic2] - eps)].toTable
      check selectBeliefsWithMinimalError(opinion, @[], @[]).toHashSet == opinion2BeliefCache[possible].toHashSet
  
  test "if both of the opinions differ slightly":
    let eps = newDecimal("1e-8")
    for possible in possibleOpinions:
      let opinion = @[(topic1, possible[topic1] - eps), (topic2, possible[topic2] - eps)].toTable
      check selectBeliefsWithMinimalError(opinion, @[], @[]).toHashSet == opinion2BeliefCache[possible].toHashSet
  
  test "case 1":
    let opinion = @[(topic1, newDecimal("0.1")), (topic2, newDecimal("0.9999995"))].toTable
    check selectBeliefsWithMinimalError(opinion, @[], @[]).toHashSet == 
      @[toFormula("00000001"), toFormula("00000010"), toFormula("00000011")].toHashSet
  
  test "case 2":
    let opinion = @[(topic1, newDecimal("0.5")), (topic2, newDecimal("0.5"))].toTable
    check selectBeliefsWithMinimalError(opinion, @[], @[]).toHashSet == 
      @[toFormula("00000100"), toFormula("00000101"), toFormula("00000110")].toHashSet