import ../types
import utils
import sequtils
import sets
import options

proc isNotFollowed(agentId: int, neighbors: HashSet[int]): bool =
  not neighbors.contains(agentId)

proc recommendRandomly(simulator: Simulator, target: Agent): int = 
  let notFollowes = (0..<simulator.agents.len).toSeq.filterIt(it.isNotFollowed(target.neighbors))
  notFollowes.takeN(1)[0]

proc recommendUser*(simulator: Simulator, target: Agent): int =
  result = 
    case target.rewritingStrategy
    of RewritingStrategy.random:
      simulator.recommendRandomly(target)
    of RewritingStrategy.repost:
      let reposts = target.getTimeline(simulator.posts).filterIt(it.repostedBy.isSome)
      let repostAuthors = reposts.mapIt(it.author)
      if repostAuthors.len == 0:
        simulator.recommendRandomly(target)
      else:
        repostAuthors.takeN(1)[0]
    of RewritingStrategy.recommendation:
      let acceptablePosts = target.postSelector(simulator.posts)
      let acceptablePostsAuthors = acceptablePosts.mapIt(it.author)
      let candidates = acceptablePostsAuthors.filterIt(it.isNotFollowed(target.neighbors))
      if candidates.len == 0:
        simulator.recommendRandomly(target)
      else:
        candidates.takeN(1)[0]