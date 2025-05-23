import unittest

import distance
import intbrg
import types
import tables

suite "Distances":
  test "between opinions":
    let t1 = toFormula("1")
    check distance(@[(t1, newDecimal("0.3"))].toTable, @[(t1, newDecimal("0.8"))].toTable) == newDecimal("0.5")
  
  test "between beliefs":
    check distance(toFormula("11110000"), toFormula("11101000")) == 2

suite "Similar Opinions/Beliefs":
  let topic = toFormula("00000001")
  let agent = Agent(
    opinions: @[(topic, newDecimal("0.5"))].toTable, 
    belief: toFormula("11110000"), 
    epsilon: newDecimal("0.1"), 
    delta: 2,
  )

  test "similar opinions":
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.5"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.55"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.45"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.4"))].toTable))
    check agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.6"))].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.35"))].toTable))
    check not agent.hasSimilarOpinion(Message(opinions: @[(topic, newDecimal("0.65"))].toTable))

  test "similar beliefs":
    check agent.hasSimilarBelief(Message(belief: toFormula("11110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("11110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110000")))
    check agent.hasSimilarBelief(Message(belief: toFormula("01110001")))
    check agent.hasSimilarBelief(Message(belief: toFormula("10010000")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("00001111")))
    check not agent.hasSimilarBelief(Message(belief: toFormula("10001000")))


suite "order between diffrence info":
  let infos = @[
    DifferenceInfo(
      opinions: newDecimal("0.2"),
      beliefs: 2,
      id: Id(0),
    ),
    DifferenceInfo(
      opinions: newDecimal("0.2"),
      beliefs: 4,
      id: Id(1),
    ),
    DifferenceInfo(
      opinions: newDecimal("0.4"),
      beliefs: 2,
      id: Id(2),
    ),
    DifferenceInfo(
      opinions: newDecimal("0.4"),
      beliefs: 4,
      id: Id(3),
    ),
  ]

  test "opinion only":
    # 0 == 1 < 2 == 3
    check opinionCmp(infos[0], infos[1]) == 0  # ==
    check opinionCmp(infos[2], infos[3]) == 0  # ==
    check opinionCmp(infos[0], infos[2]) < 0   # <
    check opinionCmp(infos[3], infos[1]) > 0   # >

  test "beliefs only":
    # 0 == 2 < 1 == 3
    check beliefCmp(infos[0], infos[2]) == 0   # ==
    check beliefCmp(infos[1], infos[3]) == 0   # ==
    check beliefCmp(infos[0], infos[1]) < 0    # <
    check beliefCmp(infos[3], infos[2]) > 0    # >

  test "opinion -> belief":
    # 0 < 1 < 2 < 3
    check opbelCmp(infos[0], infos[1]) < 0
    check opbelCmp(infos[3], infos[2]) > 0
    check opbelCmp(infos[0], infos[2]) < 0
    check opbelCmp(infos[3], infos[1]) > 0
    check opbelCmp(infos[0], infos[0]) == 0

  test "belief -> opinion":
    # 0 < 2 < 1 < 3
    check belopCmp(infos[0], infos[2]) < 0
    check belopCmp(infos[3], infos[1]) > 0
    check belopCmp(infos[2], infos[1]) < 0
    check belopCmp(infos[3], infos[0]) > 0
    check belopCmp(infos[0], infos[0]) == 0

