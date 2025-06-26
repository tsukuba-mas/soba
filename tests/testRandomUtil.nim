import unittest

include randomUtils
import random as stdrand

InitRNGs()

suite "Random Utils":
  const seed = 42
  const trial = 1_000_000
  let agent = Agent(id: Id(0))

  test "generate random numbers":
    var rng = random.initRand(seed)
  
    rngInitializer(@[seed])

    for _ in 0..<trial:
      check agent.rand(1, 100) == rng.rand(1..100)
      check agent.rand(0.0, 1.0) == rng.rand(0.0..1.0)

  test "different seed creates different numbers":
    rngInitializer(@[100, 200])

    let a2 = Agent(id: Id(1))
    for _ in 0..<trial:
      check agent.rand(0, high(int)) != a2.rand(0, high(int))
  
  test "shuffle sequenses":
    var rng = random.initRand(seed)

    rngInitializer(@[seed])
    
    var xs = @[0, 1, 2, 3, 4]
    var ys = @[0, 1, 2, 3, 4]
    for _ in 0..<trial:
      xs = shuffle(agent, xs)
      stdrand.shuffle(rng, ys)
      check xs == ys
  
  test "with probability":
    var rng = random.initRand(seed)

    rngInitializer(@[seed])
    
    var count = 0
    let prob = 0.25

    for _ in 0..<trial:
      agent.withProbability(prob):
        count += 1
    
    for _ in 0..<trial:
      if rng.rand(0.0..1.0) <= prob:
        count -= 1
    
    check count == 0
      
