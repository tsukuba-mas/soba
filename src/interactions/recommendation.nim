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
  target.choose(notFollowes)

proc recommendUser(target: Agent, agentNum: int, allPosts: Table[Id, Message]): Option[Id] =
  ## Recommend a user to be followed.
  let allMessagesSeq = (0..<agentNum).toSeq.mapIt(allPosts[Id(it)])
  result = 
    case target.rewritingStrategy
    of RewritingStrategy.none:
      none(Id)
    of RewritingStrategy.random:
      target.recommendRandomly(agentNum)
    of RewritingStrategy.swapMaxMin:
      let messageFromNonNeighbors = allMessagesSeq.filterIt(target.isNotFollowing(it.author))
      let differenceInfos = messageFromNonNeighbors.toDifferenceInfo(target)
      let minDistNonNeighbors = differenceInfos.argmin(target)
      target.choose(minDistNonNeighbors)
  
proc getAuthors(posts: seq[Message]): seq[Id] =
  ## Get authors of given posts.
  posts.mapIt(it.author)

proc getUnfollowedAgent(agent: Agent, allMessages: Table[Id, Message], unacceptables: seq[Message]): Option[Id] =
  case agent.rewritingStrategy
  of RewritingStrategy.swapMaxMin:
    let messagesFromNeighbors = agent.neighbors.toSeq.mapIt(allMessages[it])
    let differenceInfos = messagesFromNeighbors.todifferenceInfo(agent)
    let maxDistNeighbors = differenceInfos.argmax(agent)
    agent.choose(maxDistNeighbors)
  of RewritingStrategy.random:
    agent.choose(unacceptables.getAuthors())
  of RewritingStrategy.none:
    none(Id)

proc canUpdateNeighbors(
  agent: Agent,
  unfollowedAgentMessage: Option[Message],
  followedAgentMessage: Option[Message],
): bool =
  case agent.rewritingStrategy
  of RewritingStrategy.none:
    return false
  of RewritingStrategy.swapMaxMin:
    let isSucceededInChoosingAgents = unfollowedAgentMessage.isSome() and followedAgentMessage.isSome()
    if not isSucceededInChoosingAgents:
      return false
    else:
      return agent.distance(unfollowedAgentMessage.get()) > agent.distance(followedAgentMessage.get())
  of RewritingStrategy.random:
    return unfollowedAgentMessage.isSome() and followedAgentMessage.isSome()

proc getMessagesOption(messages: Table[Id, Message], id: Option[Id]): Option[Message] =
  if id.isSome():
    return some(messages[id.get])
  else:
    return none(Message)
  
  
proc updateNeighbors(
  agent: Agent,
  evaluatedMessages: EvaluatedMessages,
  allMessages: Table[Id, Message],
  agentNum: int,
  tick: int
): Agent =
  ## Returns an agent after it revises the set of neighbors (i.e., the set of agents it follows) if it does; 
  ## if it does not, `agent` itself is returned.
  agent.withProbability(agent.unfollowProb):
    let unfollowed = agent.getUnfollowedAgent(allMessages, evaluatedMessages.unacceptables)
    let newNeighbor = agent.recommendUser(agentNum, allMessages)
    let unfollowedAgentMessage = getMessagesOption(allMessages, unfollowed)
    let newlyFollowedAgentMessage = getMessagesOption(allMessages, newNeighbor)
    if canUpdateNeighbors(agent, unfollowedAgentMessage, newlyFollowedAgentMessage):
      if not agent.neighbors.contains(unfollowed.get()):
        raise newException(
          SOBADefect,
          fmt"agent {agent.id}'s neighbors are {agent.neighbors}, which do not contain {unfollowed.get()}"
        )
      if agent.neighbors.contains(newNeighbor.get()):
        raise newException(
          SOBADefect,
          fmt"agent {agent.id} is trying to add agent {newNeighbor.get()} to neighbors, while it is already in it"
        )
      if agent.id == unfollowed.get:
        raise newException(
          SOBADefect,
          fmt"agent {agent.id} is trying to remove itself from its neighbors"
        )
      if agent.id == newNeighbor.get:
        raise newException(
          SOBADefect,
          fmt"agent {agent.id} is trying to add itself to its neighbors"
        )
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
