import ../types
import ../randomUtils
import ../copyUtils
import utils
import sequtils
import sets
import options

proc isNotFollowed(agentId: Id, neighbors: HashSet[Id]): bool =
  not neighbors.contains(agentId)

proc recommendRandomly(simulator: Simulator, target: Agent): Option[Id] = 
  let notFollowes = (0..<simulator.agents.len).toSeq.map(toId).filterIt(it != target.id and it.isNotFollowed(target.neighbors))
  notFollowes.choose()

proc recommendUser(simulator: Simulator, target: Agent): Option[Id] =
  result = 
    case target.rewritingStrategy
    of RewritingStrategy.random:
      simulator.recommendRandomly(target)
    of RewritingStrategy.repost:
      let reposts = target.getTimeline(simulator.posts, simulator.screenSize).filterIt(it.repostedBy.isSome)
      let repostAuthors = reposts.mapIt(it.author)
      if repostAuthors.len == 0:
        simulator.recommendRandomly(target)
      else:
        repostAuthors.choose()
    of RewritingStrategy.recommendation:
      let acceptablePosts = target.postSelector(simulator.posts, simulator.screenSize)
      let acceptablePostsAuthors = acceptablePosts.mapIt(it.author)
      let candidates = acceptablePostsAuthors.filterIt(it != target.id and it.isNotFollowed(target.neighbors))
      if candidates.len == 0:
        simulator.recommendRandomly(target)
      else:
        candidates.choose()
  
proc updateNeighbors(simulator: Simulator, agent: Agent): Agent =
  withProbability(agent.unfollowProb):
    let unfollowed = agent.neighbors.toSeq.choose()
    let newNeighbor = simulator.recommendUser(agent)
    if unfollowed.isSome() and newNeighbor.isSome():
      return agent.updateNeighbors(unfollowed.get(), newNeighbor.get())

  return agent

proc updateNeighbors*(simulator: Simulator, targets: HashSet[Id]): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if targets.contains(it.id): simulator.updateNeighbors(it) else: it
  )
  simulator.updateAgents(updatedAgents)