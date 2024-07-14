import ../types
import sequtils
import math
import sets

proc opinionDynamics(simulator: Simulator, agent: Agent): Agent =
  let neighbors = agent.neighbors.toSeq.mapIt(agent.opinion)
  let updatedOpinion = (agent.opinion + neighbors.sum) / (1 + neighbors.len).toFloat
  Agent(opinion: updatedOpinion, belief: agent.belief, id: agent.id, neighbors: agent.neighbors)

proc opinionDynamics*(simulator: var Simulator) =
  let updatedAgents = simulator.agents.mapIt(simulator.opinionDynamics(it))
  simulator.agents = updatedAgents