import ../types
import ../copyUtils
import sequtils
import math
import utils

proc opinionDynamics(simulator: Simulator, agent: Agent): Agent =
  let neighbors = agent.postSelector(simulator.posts).mapIt(it.opinion)
  let updatedOpinion = (agent.opinion + neighbors.sum) / (1 + neighbors.len).toFloat
  agent.updateOpinion(updatedOpinion)

proc opinionDynamics*(simulator: Simulator): Simulator =
  let updatedAgents = simulator.agents.mapIt(simulator.opinionDynamics(it))
  simulator.updateAgents(updatedAgents)