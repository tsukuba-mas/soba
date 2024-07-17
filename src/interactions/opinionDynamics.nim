import ../types
import ../copyUtils
import sequtils
import stats
import utils
import sets

proc opinionDynamics(simulator: Simulator, agent: Agent): Agent =
  let neighbors = agent.postSelector(simulator.posts, simulator.screenSize).mapIt(it.opinion)
  if neighbors.len == 0:
    return agent
  let updatedOpinion = agent.mu * agent.opinion + (1.0 - agent.mu) * mean(neighbors)
  agent.updateOpinion(updatedOpinion)

proc opinionDynamics*(simulator: Simulator, targets: HashSet[Id]): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if targets.contains(it.id): simulator.opinionDynamics(it) else: it
  )
  simulator.updateAgents(updatedAgents)