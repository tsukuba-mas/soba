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
  ## Returns true iff the agent with the `id` is not followed by the agent `by`.
  not by.neighbors.contains(id) and by.id != id

proc recommendRandomly(target: Agent, agentNum: int): Option[Id] = 
  ## Returns recommended agent that is chosen randomly from the agents who are not followed by `target`.
  let notFollowes = (0..<agentNum).toSeq.map(toId).filterIt(target.isNotFollowing(it))
  notFollowes.choose()

proc filterRecommendedPosts(target: Agent, posts: seq[Message], myMostRecentPost: Message): seq[Message] = 
  ## Fileter messages in `posts` and returns some of them that are regarded as concordant 
  ## (i.e., similar to `target`'s opinions and/or beliefs).
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

proc recommendUser(target: Agent, agentNum: int, allPosts: seq[Message]): Option[Id] =
  ## Recommend a user to be followed.
  result = 
    case target.rewritingStrategy
    of RewritingStrategy.none:
      none(Id)
    of RewritingStrategy.random:
      target.recommendRandomly(agentNum)
    of RewritingStrategy.oprecommendation, 
       RewritingStrategy.belrecommendation, 
       RewritingStrategy.bothrecommendation:
      let myMessage = target.writeMessage()
      let recommendedUsers = target.filterRecommendedPosts(allPosts, myMessage).mapIt(it.author)
      let candidates = recommendedUsers.filterIt(target.isNotFollowing(it))
      if candidates.len == 0:
        target.recommendRandomly(agentNum)
      else:
        candidates.choose()
  
proc getAuthors(posts: seq[Message]): seq[Id] =
  ## Get authors of given posts.
  posts.mapIt(it.author)
  
proc updateNeighbors(agent: Agent, evaluatedMessages: EvaluatedMessages, allMessages: seq[Message], agentNum: int, tick: int): Agent =
  ## Returns an agent after it revises the set of neighbors (i.e., the set of agents it follows) if it does; 
  ## if it does not, `agent` itself is returned.
  withProbability(agent.unfollowProb):
    let unfollowed = evaluatedMessages.unacceptables.getAuthors().choose()
    let newNeighbor = agent.recommendUser(agentNum, allMessages)
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

proc updateNeighbors*(simulator: Simulator, id2evaluatedMessages: Table[Id, EvaluatedMessages], time: int): Simulator =
  ## Returns a simulator with agents after their updates on their neighbors (i.e., the agents they follow).
  let allMessages = simulator.agents.writeMessage()
  let updatedAgents = simulator.agents.mapIt(
    if id2evaluatedMessages.contains(it.id): 
      it.updateNeighbors(id2evaluatedMessages[it.id], allMessages, simulator.agents.len, time) 
    else: 
      it
  )
  simulator.updateAgents(updatedAgents)