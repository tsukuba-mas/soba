import random
import options
import sets
import sequtils
import algorithm

var rng: Option[Rand] = none(Rand)

proc initRand*(seed: int) =
  rng = some(random.initRand(seed))

proc rand*[T: int or float](lb, ub: T): T =
  rng.get.rand(lb..ub)

proc shuffle*[T](xs: seq[T]): seq[T] =
  var ys = xs
  rng.get.shuffle(ys)
  ys

proc takeN*[T](xs: seq[T], n: int): seq[T] =
  var taken = initHashSet[int]()
  while taken.len < n:
    taken.incl(rand(0, xs.len - 1))
  taken.toSeq.sorted.mapIt(xs[it])