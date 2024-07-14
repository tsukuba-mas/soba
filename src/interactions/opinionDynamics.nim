import ../types
import ../copyUtils
import sequtils
import stats
import utils

proc opinionDynamics(simulator: Simulator, agent: Agent): Agent =
  let neighbors = agent.postSelector(simulator.posts).mapIt(it.opinion)
  let updatedOpinion = agent.mu * agent.opinion + (1.0 - agent.mu) * mean(neighbors)
  agent.updateOpinion(updatedOpinion)

proc opinionDynamics*(simulator: Simulator): Simulator =
  let updatedAgents = simulator.agents.mapIt(simulator.opinionDynamics(it))
  simulator.updateAgents(updatedAgents)