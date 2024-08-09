import ../types
import ../randomUtils
import ../copyUtils
import ../logger
import ../distance
import utils
import sequtils
import sets
import options
import strformat
import tables

proc isNotFollowing(by: Agent, id: Id): bool =
  not by.neighbors.contains(id) and by.id != id

proc recommendRandomly(target: Agent, agentNum: int): Option[Id] = 
  let notFollowes = (0..<agentNum).toSeq.map(toId).filterIt(target.isNotFollowing(it))
  notFollowes.choose()

proc filterRecommendedPosts(target: Agent, posts: seq[Message], myMostRecentPost: Message): seq[Message] = 
  case target.rewritingStrategy
  of RewritingStrategy.oprecommendation:
    posts.filterIt(target.hasSimilarOpinion(it))
  of RewritingStrategy.belrecommendation:
    posts.filterIt(target.hasSimilarBelief(it))
  of RewritingStrategy.bothrecommendation:
    posts.filterIt(
      target.hasSimilarOpinion(it) and target.hasSimilarBelief(it)
    )
  else:
    # NOT expected to reach here
    @[]
  
proc getMyMostRecentPost(target: Agent, allPosts: seq[Message]): Option[Message] =
  let myPosts = allPosts.filterIt(it.author == target.id)
  if myPosts.len == 0:
    none(Message)
  else:
    some(myPosts[^1])

proc recommendUser(target: Agent, evaluatedPosts: EvaluatedTimeline, agentNum: int, allPosts: seq[Message]): Option[Id] =
  result = 
    case target.rewritingStrategy
    of RewritingStrategy.none:
      none(Id)
    of RewritingStrategy.random:
      target.recommendRandomly(agentNum)
    of RewritingStrategy.repost:
      let reposts = evaluatedPosts.acceptables.filterIt(it.repostedBy.isSome)
      let repostAuthors = reposts.mapIt(it.author).filterIt(target.isNotFollowing(it))
      if repostAuthors.len == 0:
        target.recommendRandomly(agentNum)
      else:
        repostAuthors.choose()
    of RewritingStrategy.oprecommendation, 
       RewritingStrategy.belrecommendation, 
       RewritingStrategy.bothrecommendation:
      let myMostRecentPostOptional = target.getMyMostRecentPost(allPosts)
      if myMostRecentPostOptional.isNone:
        target.recommendRandomly(agentNum)
      else:
        let myMostRecentPost = myMostRecentPostOptional.get()
        let recommendedUsers = target.filterRecommendedPosts(allPosts, myMostRecentPost).mapIt(it.author)
        let candidates = recommendedUsers.filterIt(target.isNotFollowing(it))
        if candidates.len == 0:
          target.recommendRandomly(agentNum)
        else:
          candidates.choose()
  
proc getAuthorsOrRepostedUser(posts: seq[Message]): seq[Id] =
  posts.mapIt(
    if it.repostedBy.isSome(): it.repostedBy.get()
    else: it.author
  )
  
proc updateNeighbors(agent: Agent, evaluatedPosts: EvaluatedTimeline, agentNum: int, allPosts: seq[Message], tick: int): Agent =
  withProbability(agent.unfollowProb):
    let unfollowed = evaluatedPosts.unacceptables.getAuthorsOrRepostedUser().choose()
    let newNeighbor = agent.recommendUser(evaluatedPosts, agentNum, allPosts)
    if unfollowed.isSome() and newNeighbor.isSome():
      assert agent.neighbors.contains(unfollowed.get())
      assert not agent.neighbors.contains(newNeighbor.get())
      assert agent.id != unfollowed.get
      assert agent.id != newNeighbor.get
      verboseLogger(
        fmt"NG {tick} {agent.id} removed {unfollowed.get()} followed {newNeighbor.get()}",
        tick
      )
      return agent.updateNeighbors(unfollowed.get(), newNeighbor.get())

  return agent

proc updateNeighbors*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], time: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id): it.updateNeighbors(evaluatedPosts[it.id], simulator.agents.len, simulator.posts, time) 
    else: it
  )
  simulator.updateAgents(updatedAgents)