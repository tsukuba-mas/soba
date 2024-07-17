import types
import intbrg
import sets

proc copy(simulator: Simulator): Simulator =
  Simulator(
    agents: simulator.agents,
    topic: simulator.topic,
    posts: simulator.posts,
  )

proc copy(agent: Agent): Agent =
  Agent(
    id: agent.id,
    belief: agent.belief,
    opinion: agent.opinion,
    neighbors: agent.neighbors,
    filterStrategy: agent.filterStrategy,
    updatingStrategy: agent.updatingStrategy,
    rewritingStrategy: agent.rewritingStrategy,
    mu: agent.mu,
    repostProb: agent.repostProb,
    unfollowProb: agent.unfollowProb,
  )

proc updateOpinion*(agent: Agent, opinion: Opinion): Agent =
  var newAgent = agent.copy()
  newAgent.opinion = opinion
  newAgent

proc updateBelief*(agent: Agent, belief: Formulae): Agent =
  var newAgent = agent.copy()
  newAgent.belief = belief
  newAgent

proc updateNeighbors*(agent: Agent, removed: Id, added: Id): Agent =
  var newAgent = agent.copy()
  newAgent.neighbors = newAgent.neighbors - toHashSet(@[removed]) + toHashSet(@[added])
  newAgent

proc updateAgents*(simulator: Simulator, agents: seq[Agent]): Simulator =
  var newSimulator = simulator.copy()
  newSimulator.agents = agents
  newSimulator

proc tail[T](xs: seq[T], n: int): seq[T] = 
  if xs.len <= n:
    xs
  else:
    xs[(xs.len - n)..<xs.len]

proc updatePosts*(simulator: Simulator, posts: seq[Message]): Simulator =
  var newSimulator = simulator.copy()
  newSimulator.posts = posts.tail(newSimulator.agents.len)
  newSimulator