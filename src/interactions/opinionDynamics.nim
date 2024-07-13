import ../types
import sequtils
import math
import utils

proc opinionDynamics(simulator: Simulator, agent: Agent): Agent =
  let neighbors = simulator.getNeighborList(agent.id).mapIt(agent.opinion)
  let updatedOpinion = (agent.opinion + neighbors.sum) / (1 + neighbors.len).toFloat
  Agent(opinion: updatedOpinion, belief: agent.belief, id: agent.id)

proc opinionDynamics*(simulator: var Simulator) =
  let updatedAgents = simulator.agents.mapIt(simulator.opinionDynamics(it))
  simulator.agents = updatedAgents