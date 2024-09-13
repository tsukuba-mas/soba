import ../types
import ../copyUtils
import ../logger
import sequtils
import stats
import strformat

proc opinionDynamics*(agent: Agent, acceptablePosts: seq[Message], tick: int): Agent =
  let neighbors = acceptablePosts.mapIt(it.opinion)
  let updatedOpinion = 
    if neighbors.len > 0: 
      (1.0 - agent.mu) * agent.opinion + agent.mu * mean(neighbors)
    else:
      agent.opinion
  verboseLogger(
    fmt"OD {tick} {agent.id} {agent.opinion} -> {updatedOpinion}",
    tick
  )
  agent.updateOpinion(updatedOpinion)
