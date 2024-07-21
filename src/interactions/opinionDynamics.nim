import ../types
import ../copyUtils
import ../logger
import sequtils
import stats
import tables
import strformat

proc opinionDynamics(agent: Agent, acceptablePosts: seq[Message], tick: int): Agent =
  let neighbors = acceptablePosts.mapIt(it.opinion)
  if neighbors.len == 0:
    return agent
  let updatedOpinion = agent.mu * agent.opinion + (1.0 - agent.mu) * mean(neighbors)
  verboseLogger(
    fmt"OD {tick} {agent.id} {agent.opinion} -> {updatedOpinion}",
    tick
  )
  agent.updateOpinion(updatedOpinion)

proc opinionDynamics*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], tick: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id): it.opinionDynamics(evaluatedPosts[it.id].acceptables, tick) 
    else: it
  )
  simulator.updateAgents(updatedAgents)