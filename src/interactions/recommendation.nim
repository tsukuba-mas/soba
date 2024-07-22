import ../types
import ../randomUtils
import ../copyUtils
import ../logger
import utils
import sequtils
import sets
import options
import strformat
import tables

proc isNotFollowed(agentId: Id, neighbors: HashSet[Id]): bool =
  not neighbors.contains(agentId)

proc recommendRandomly(target: Agent, agentNum: int): Option[Id] = 
  let notFollowes = (0..<agentNum).toSeq.map(toId).filterIt(it != target.id and it.isNotFollowed(target.neighbors))
  notFollowes.choose()

proc recommendUser(target: Agent, evaluatedPosts: EvaluatedTimeline, agentNum: int): Option[Id] =
  result = 
    case target.rewritingStrategy
    of RewritingStrategy.none:
      none(Id)
    of RewritingStrategy.random:
      target.recommendRandomly(agentNum)
    of RewritingStrategy.repost:
      let reposts = concat(evaluatedPosts.acceptables, evaluatedPosts.unacceptables).filterIt(it.repostedBy.isSome)
      let repostAuthors = reposts.mapIt(it.repostedBy.get)
      if repostAuthors.len == 0:
        target.recommendRandomly(agentNum)
      else:
        repostAuthors.choose()
    of RewritingStrategy.recommendation:
      let recommendedUsers = evaluatedPosts.acceptables.mapIt(it.author)
      let candidates = recommendedUsers.filterIt(it != target.id and it.isNotFollowed(target.neighbors))
      if candidates.len == 0:
        target.recommendRandomly(agentNum)
      else:
        candidates.choose()
  
proc getAuthorsOrRepostedUser(posts: seq[Message]): seq[Id] =
  posts.mapIt(
    if it.repostedBy.isSome(): it.repostedBy.get()
    else: it.author
  )
  
proc updateNeighbors(agent: Agent, evaluatedPosts: EvaluatedTimeline, agentNum: int, tick: int): Agent =
  withProbability(agent.unfollowProb):
    let unfollowed = evaluatedPosts.unacceptables.getAuthorsOrRepostedUser().choose()
    let newNeighbor = agent.recommendUser(evaluatedPosts, agentNum)
    if unfollowed.isSome() and newNeighbor.isSome():
      verboseLogger(
        fmt"NG {tick} {agent.id} removed {unfollowed.get()} followed {newNeighbor.get()}",
        tick
      )
      return agent.updateNeighbors(unfollowed.get(), newNeighbor.get())

  return agent

proc updateNeighbors*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], time: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id): it.updateNeighbors(evaluatedPosts[it.id], simulator.agents.len, time) 
    else: it
  )
  simulator.updateAgents(updatedAgents)