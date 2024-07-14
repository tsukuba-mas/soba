import ../types
import ../distance
import sequtils
import sets
import options

const eps = 1e-5

proc isRelatedToNeighbors(neighbors: HashSet[int], post: Message): bool =
  let isInitialAuthor = neighbors.contains(post.author)
  let isRepostAuthor = post.repostedBy.isSome() and neighbors.contains(post.repostedBy.get())
  isInitialAuthor or isRepostAuthor

proc postSelector*(agent: Agent, posts: seq[Message]): seq[Message] =
  let availablePosts = posts.filterIt(agent.neighbors.isRelatedToNeighbors(it))
  result = case agent.filterStrategy
    of FilterStrategy.all:
      availablePosts
    of FilterStrategy.obounded:
      availablePosts.filterIt(distance(agent.opinion, it.opinion) <= eps)
    of FilterStrategy.bbounded:
      availablePosts.filterIt(distance(agent.belief, it.belief) <= 1)
    of FilterStrategy.both:
      availablePosts.filterIt(
        distance(agent.opinion, it.opinion) <= eps and distance(agent.belief, it.belief) <= 1
      )