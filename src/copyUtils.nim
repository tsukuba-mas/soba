import types
import intbrg
import sets
import utils

proc copy(simulator: Simulator): Simulator =
  Simulator(
    agents: simulator.agents,
    topic: simulator.topic,
    posts: simulator.posts,
    screenSize: simulator.screenSize,
    verbose: simulator.verbose,
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

proc updatePosts*(simulator: Simulator, posts: seq[Message]): Simulator =
  var newSimulator = simulator.copy()
  newSimulator.posts = posts.tail(newSimulator.agents.len)
  newSimulator