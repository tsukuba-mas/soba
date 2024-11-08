import ../types
import ../copyUtils
import ../logger
import sequtils
import stats
import strformat

proc opinionDynamicsDeGrootmodel*(agent: Agent, acceptablePosts: seq[Message], tick: int): Agent =
  ## Perform opinion dynamics based on the DeGroot model.
  ## Here, the weight for the agent itself and its neighbors are the same.
  let neighbors = acceptablePosts.mapIt(it.opinion)
  let updatedOpinion = mean(@[agent.opinion].concat(neighbors))
  verboseLogger(
    fmt"ODDG {tick} {agent.id} {agent.opinion} -> {updatedOpinion}",
    tick
  )
  agent.updateOpinion(updatedOpinion)

proc opinionDynamicsDWmodel*(agent: Agent, acceptablePosts: seq[Message], tick: int): Agent =
  ## Perform opinion dynamics based on a bounded confidence model.
  let neighbors = acceptablePosts.mapIt(it.opinion)
  let updatedOpinion = 
    if neighbors.len > 0: 
      (1.0 - agent.mu) * agent.opinion + agent.mu * mean(neighbors)
    else:
      agent.opinion
  verboseLogger(
    fmt"ODDW {tick} {agent.id} {agent.opinion} -> {updatedOpinion}",
    tick
  )
  agent.updateOpinion(updatedOpinion)
