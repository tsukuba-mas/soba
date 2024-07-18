import ../types
import ../copyUtils
import ../logger
import sequtils
import stats
import utils
import sets
import strformat

proc opinionDynamics(simulator: Simulator, agent: Agent, tick: int): Agent =
  let neighbors = agent.getAcceptablePosts(simulator.posts, simulator.screenSize).mapIt(it.opinion)
  if neighbors.len == 0:
    return agent
  let updatedOpinion = agent.mu * agent.opinion + (1.0 - agent.mu) * mean(neighbors)
  simulator.verboseLogger(
    fmt"OD {tick} {agent.id} {agent.opinion} -> {updatedOpinion}",
    tick
  )
  agent.updateOpinion(updatedOpinion)

proc opinionDynamics*(simulator: Simulator, targets: HashSet[Id], tick: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if targets.contains(it.id): simulator.opinionDynamics(it, tick) else: it
  )
  simulator.updateAgents(updatedAgents)