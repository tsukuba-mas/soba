import random
import options
import sets
import sequtils
import algorithm
import types
import macros

export Rand

# RNG tempaltes
     
template InitRNGs*() =
  var rngs: seq[Rand]


  # RNG initializers
  proc rngInitializer(seeds: seq[int]) =
    rngs = newSeq[Rand](seeds.len)
    for idx, seed in seeds:
      rngs[idx] = random.initRand(seed)

  proc rngInitializer(rng: var Rand, n: int) =
    rngs = newSeq[Rand](n)
    for idx in 0..<n:
      let currentSeed = rng.rand(1..high(int))
      rngs[idx] = random.initRand(currentSeed)

  # Produce one random numbers
  proc rand[T: int or float](rng: var Rand, lb, ub: T): T =
    rng.rand(lb..ub)

  proc rand[T: int or float](agents: Agent, lb, ub: T): T =
    rngs[int(agents.id)].rand(lb, ub)


  # Shuffle sequence
  proc shuffle[T](rng: var Rand, xs: seq[T]): seq[T] = 
    var ys = xs
    # Specify the library so that below does not call this proc infinitely
    random.shuffle(rng, ys)
    return ys

  proc shuffle[T](agent: Agent, xs: seq[T]): seq[T] = 
    rngs[int(agent.id)].shuffle(xs)


  # Take N element from sequence
  proc takeN[T](rng: var Rand, xs: seq[T], n: int): Option[seq[T]] =
    if xs.len < n:
      none(seq[T])
    else:
      var idx = initHashSet[int]()
      while idx.len < n:
        ## Specify the module to avoid conflict
        idx.incl(rng.rand(0, xs.len - 1))

      some(idx.items.toSeq.sorted.map(proc (idx: int): T = xs[idx]))

  proc takeN[T](agent: Agent, xs: seq[T], n: int): Option[seq[T]] =
    rngs[int(agent.id)].takeN(xs, n)


  # Take one element from sequence
  proc choose[T](rng: var Rand, xs: seq[T]): Option[T] =
    let taken = rng.takeN(xs, 1)
    if taken.isSome():
      some(taken.get()[0])
    else:
      none(T)

  proc choose[T](agent: Agent, xs: seq[T]): Option[T] = 
    rngs[int(agent.id)].choose(xs)

  # Do something probabilistically
  template withProbability(rng: var Rand, prob: float, body: untyped): untyped =
    ## With probability `prob`, do `body`.
    ## This template should be applied to `body` which is related to agents' actions.
    if rng.rand(0.0, 1.0) <= prob:
      body
  
  template withProbability(agent: Agent, prob: float, body: untyped): untyped =
    ## With probability `prob`, do `body`.
    ## This template should be applied to `body` which is related to agents' actions.
    rngs[int(agent.id)].withProbability(prob):
      body


