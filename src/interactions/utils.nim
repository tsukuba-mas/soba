import ../types
import ../distance
import ../randomUtils
import ../utils
import sequtils
import sets
import options
import algorithm

const eps = 1e-1

proc isRelatedToNeighbors(neighbors: HashSet[Id], post: Message): bool =
  let isInitialAuthor = neighbors.contains(post.author)
  let isRepostAuthor = post.repostedBy.isSome() and neighbors.contains(post.repostedBy.get())
  isInitialAuthor or isRepostAuthor

proc getTimeline*(agent: Agent, posts: seq[Message], messages: int): seq[Message] = 
  posts.filterIt(agent.neighbors.isRelatedToNeighbors(it)).tail(messages)

proc isAcceptablePost*(agent: Agent, post: Message): bool =
  result = 
    case agent.filterStrategy
    of FilterStrategy.all:
      true
    of FilterStrategy.obounded:
      distance(agent.opinion, post.opinion) <= eps
    of FilterStrategy.bbounded:
      distance(agent.belief, post.belief) <= 1
    of FilterStrategy.both:
      distance(agent.opinion, post.opinion) <= eps and distance(agent.belief, post.belief) <= 1

proc postSelector*(agent: Agent, posts: seq[Message], messages: int): seq[Message] =
  agent.getTimeline(posts, messages).filterIt(agent.isAcceptablePost(it))

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