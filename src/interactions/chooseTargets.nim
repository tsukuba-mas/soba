import ../randomUtils
import sequtils
import sets
import algorithm

proc takeN[T](xs: seq[T], n: int): seq[T] =
  var idx = initHashSet[int]()
  while idx.len < n:
    idx.incl(rand(0, xs.len - 1))
  idx.toSeq.sorted.mapIt(xs[it])

proc chooseTargets*(agents: int): seq[int] = 
  (0..<agents).toSeq.takeN(1)