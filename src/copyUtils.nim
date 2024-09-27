import types
import intbrg
import sets

proc copy(simulator: Simulator): Simulator =
  ## Copy `simulator` explicitly.
  Simulator(
    agents: simulator.agents,
    topic: simulator.topic,
    verbose: simulator.verbose,
    followFrom: simulator.followFrom,
  )

proc copy(agent: Agent): Agent =
  ## Copy `agent` explicitly.
  Agent(
    id: agent.id,
    belief: agent.belief,
    opinion: agent.opinion,
    neighbors: agent.neighbors,
    filterStrategy: agent.filterStrategy,
    updatingStrategy: agent.updatingStrategy,
    rewritingStrategy: agent.rewritingStrategy,
    values: agent.values,
    mu: agent.mu,
    alpha: agent.alpha,
    unfollowProb: agent.unfollowProb,
    activationProb: agent.activationProb,
    epsilon: agent.epsilon,
    delta: agent.delta,
  )

proc updateOpinion*(agent: Agent, opinion: Opinion): Agent =
  ## Returns `agent` whose opinion is replaecd to `opinion`.
  var newAgent = agent.copy()
  newAgent.opinion = opinion
  newAgent

proc updateBelief*(agent: Agent, belief: Formulae): Agent =
  ## Returns `agent` whose belief is replaced to `belief`.
  var newAgent = agent.copy()
  newAgent.belief = belief
  newAgent

proc updateNeighbors*(agent: Agent, removed: Id, added: Id): Agent =
  ## Returns `agent` whose neighbors are revised: the agent `removed` is removed from them and 
  ## the agent `added` is added to them.
  var newAgent = agent.copy()
  newAgent.neighbors = newAgent.neighbors - toHashSet(@[removed]) + toHashSet(@[added])
  newAgent

proc updateAgents*(simulator: Simulator, agents: seq[Agent]): Simulator =
  ## Returns `simulator` whose agents are replaced to `agents`.
  var newSimulator = simulator.copy()
  newSimulator.agents = agents
  newSimulator
