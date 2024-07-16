import ../types
import ../distance
import ../randomUtils
import sequtils
import sets
import options
import algorithm

const eps = 1e-5

proc isRelatedToNeighbors(neighbors: HashSet[int], post: Message): bool =
  let isInitialAuthor = neighbors.contains(post.author)
  let isRepostAuthor = post.repostedBy.isSome() and neighbors.contains(post.repostedBy.get())
  isInitialAuthor or isRepostAuthor

proc getTimeline*(agent: Agent, posts: seq[Message]): seq[Message] = 
  posts.filterIt(agent.neighbors.isRelatedToNeighbors(it))

proc isAcceptablePost*(agent: Agent, post: Message): bool =
  result = 
    case agent.filterStrategy
    of FilterStrategy.all:
      true
    of FilterStrategy.obounded:
      distance(agent.opinion, agent.opinion) <= eps
    of FilterStrategy.bbounded:
      distance(agent.belief, agent.belief) <= 1
    of FilterStrategy.both:
      distance(agent.opinion, agent.opinion) <= eps and distance(agent.belief, agent.belief) <= 1

proc postSelector*(agent: Agent, posts: seq[Message]): seq[Message] =
  agent.getTimeline(posts).filterIt(agent.isAcceptablePost(it))

proc takeN*[T](xs: seq[T], n: int): seq[T] =
  var idx = initHashSet[int]()
  while idx.len < n:
    idx.incl(rand(0, xs.len - 1))
  idx.toSeq.sorted.mapIt(xs[it])