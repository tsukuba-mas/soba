import ../types
import ../copyUtils
import ../logger
import sequtils
import utils
import strformat

proc beliefRevisionGames*(agent: Agent, acceptablePosts: seq[Message], tick: int): Agent =
  let neighborBeliefs = acceptablePosts.mapIt(it.belief)
  let updatedBelief = revision(agent.belief, neighborBeliefs)
  verboseLogger(
    fmt"BR {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)
