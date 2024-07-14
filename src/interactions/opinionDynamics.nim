import ../types
import sequtils
import math
import sets
import utils

proc opinionDynamics(simulator: Simulator, agent: Agent): Agent =
  let neighbors = agent.postSelector(simulator.posts).mapIt(it.opinion)
  let updatedOpinion = (agent.opinion + neighbors.sum) / (1 + neighbors.len).toFloat
  Agent(opinion: updatedOpinion, belief: agent.belief, id: agent.id, neighbors: agent.neighbors)

proc opinionDynamics*(simulator: var Simulator) =
  let updatedAgents = simulator.agents.mapIt(simulator.opinionDynamics(it))
  simulator.agents = updatedAgents