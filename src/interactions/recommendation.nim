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

proc getAcceptableMessages(agent: Agent, messages: seq[Message]): seq[Message] =
  messages.filterIt(agent.isAcceptablePost(it))

proc getUnacceptableMessages(agent: Agent, messages: seq[Message]): seq[Message] =
  messages.filterIt(not agent.isAcceptablePost(it))

proc evaluateMessages(agent: Agent, messages: seq[Message]): EvaluatedTimeline =
  EvaluatedTimeline(
    acceptables: agent.getAcceptableMessages(messages),
    unacceptables: agent.getUnacceptableMessages(messages)
  )

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

proc recommendUser(target: Agent, agentNum: int, allPosts: seq[Message]): Option[Id] =
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
  posts.mapIt(it.author)
  
proc updateNeighbors(agent: Agent, messages: seq[Message], agentNum: int, tick: int): Agent =
  withProbability(agent.unfollowProb):
    let evaluatedMessages = agent.evaluateMessages(messages.filterIt(agent.neighbors.contains(it.author)))
    let unfollowed = evaluatedMessages.unacceptables.getAuthors().choose()
    let newNeighbor = agent.recommendUser(agentNum, messages)
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

proc updateNeighbors*(simulator: Simulator, allMessages: seq[Message], targets: seq[Id], time: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if targets.contains(it.id): it.updateNeighbors(allMessages, simulator.agents.len, time) 
    else: it
  )
  simulator.updateAgents(updatedAgents)