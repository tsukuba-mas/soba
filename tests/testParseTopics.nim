import unittest

include argumentParser

suite "Topics Parser":
  const atoms = 2
  const seed = 42
  initRand(seed)
  
  test "when nothing is specified":
    let topics = "".parseTopics(atoms)
    check topics.len > 0
    check topics.allIt(($it).len == 1 shl atoms)
  
  test "when topics are given":
    let topics = @["1000", "0100", "0010", "0001"]
    let actual = topics.join(",").parseTopics(atoms)
    check actual.len == topics.len
    check zip(topics, actual).allIt(it[0] == ($it[1]))