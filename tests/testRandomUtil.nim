import unittest

import randomUtils
import random

suite "Random Utils":
  const seed = 42
  const trial = 1_000_000

  test "generate random numbers":
    var rng = random.initRand(seed)
    randomUtils.initRand(seed)
    for _ in 0..<trial:
      check randomUtils.rand(1, 100) == rng.rand(1..100)
      check randomUtils.rand(0.0, 1.0) == rng.rand(0.0..1.0)
  
  test "shuffle sequenses":
    var rng = random.initRand(seed)
    randomUtils.initRand(seed)
    var xs = @[0, 1, 2, 3, 4]
    var ys = @[0, 1, 2, 3, 4]
    for _ in 0..<trial:
      xs = randomUtils.shuffle(xs)
      rng.shuffle(ys)
      check xs == ys
  
  test "with probability":
    var rng = random.initRand(seed)
    randomUtils.initRand(seed)
    var count = 0
    let prob = 0.25

    for _ in 0..<trial:
      withProbability(prob):
        count += 1
    
    for _ in 0..<trial:
      if rng.rand(0.0..1.0) <= prob:
        count -= 1
    
    check count == 0
      
