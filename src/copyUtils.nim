import types
import intbrg

proc copy(agent: Agent): Agent =
  Agent(
    id: agent.id,
    belief: agent.belief,
    opinion: agent.opinion,
    neighbors: agent.neighbors,
    filterStrategy: agent.filterStrategy,
    updatingStrategy: agent.updatingStrategy,
  )

proc updateOpinion*(agent: Agent, opinion: Opinion): Agent =
  var newAgent = agent.copy()
  newAgent.opinion = opinion
  newAgent

proc updateBelief*(agent: Agent, belief: Formulae): Agent =
  var newAgent = agent.copy()
  newAgent.belief = belief
  newAgent