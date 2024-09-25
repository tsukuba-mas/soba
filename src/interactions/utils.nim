import ../types
import ../distance
import ../randomUtils
import sequtils
import sets
import options
import algorithm
import intbrg
import tables

proc isAcceptablePost*(agent: Agent, post: Message): bool =
  result = 
    case agent.filterStrategy
    of FilterStrategy.all:
      true
    of FilterStrategy.obounded:
      agent.hasSimilarOpinion(post)
    of FilterStrategy.bbounded:
      agent.hasSimilarBelief(post)
    of FilterStrategy.both:
      agent.hasSimilarOpinion(post) and agent.hasSimilarBelief(post)

proc takeN*[T](xs: seq[T], n: int): Option[seq[T]] =
  if xs.len < n:
    none(seq[T])
  else:
    var idx = initHashSet[int]()
    while idx.len < n:
      idx.incl(rand(0, xs.len - 1))
    some(idx.toSeq.sorted.mapIt(xs[it]))

proc choose*[T](xs: seq[T]): Option[T] =
  let taken = takeN(xs, 1)
  if taken.isSome():
    some(taken.get()[0])
  else:
    none(T)

proc revision*(self: Formulae, others: seq[Formulae]): Formulae = 
  if others.len == 0:
    self
  else:
    r3(self, others, hamming, sum)