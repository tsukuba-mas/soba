import types
import intbrg
import sets
import tables

proc copy*(simulator: Simulator): Simulator =
  ## Copy `simulator` explicitly.
  Simulator(
    agents: simulator.agents,
    topics: simulator.topics,
    verbose: simulator.verbose,
    followFrom: simulator.followFrom,
    updatingProcesses: simulator.updatingProcesses,
    numberOfActivatedAgents: simulator.numberOfActivatedAgents,
  )

proc copy*(agent: Agent): Agent =
  ## Copy `agent` explicitly.
  Agent(
    id: agent.id,
    belief: agent.belief,
    opinions: agent.opinions,
    neighbors: agent.neighbors,
    rewritingStrategy: agent.rewritingStrategy,
    values: agent.values,
    mu: agent.mu,
    alpha: agent.alpha,
    unfollowProb: agent.unfollowProb,
    activationProb: agent.activationProb,
    epsilon: agent.epsilon,
    delta: agent.delta,
    updated: agent.updated,
  )

proc updateOpinion*(agent: Agent, opinions: Table[Formulae, Opinion]): Agent =
  ## Returns `agent` whose opinion is replaecd to `opinions`.
  var newAgent = agent.copy()
  newAgent.opinions = opinions
  newAgent.updated = true
  newAgent

proc updateBelief*(agent: Agent, belief: Formulae): Agent =
  ## Returns `agent` whose belief is replaced to `belief`.
  var newAgent = agent.copy()
  newAgent.belief = belief
  newAgent.updated = true
  newAgent

proc updateNeighbors*(agent: Agent, removed: Id, added: Id): Agent =
  ## Returns `agent` whose neighbors are revised: the agent `removed` is removed from them and 
  ## the agent `added` is added to them.
  var newAgent = agent.copy()
  newAgent.neighbors = newAgent.neighbors - toHashSet(@[removed]) + toHashSet(@[added])
  newAgent.updated = true
  newAgent

proc updateAgents*(simulator: Simulator, agents: seq[Agent]): Simulator =
  ## Returns `simulator` whose agents are replaced to `agents`.
  var newSimulator = simulator.copy()
  newSimulator.agents = agents
  newSimulator
