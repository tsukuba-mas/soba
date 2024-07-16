import random
import options

var rng: Option[Rand] = none(Rand)

proc initRand*(seed: int) =
  rng = some(random.initRand(seed))

proc rand*[T: int or float](lb, ub: T): T =
  rng.get.rand(lb..ub)

proc shuffle*[T](xs: seq[T]): seq[T] =
  var ys = xs
  rng.get.shuffle(ys)
  ys