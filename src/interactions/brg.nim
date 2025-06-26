import ../types
import ../logger
import sequtils
import utils
import strformat

proc beliefRevisionGames*(agent: var Agent, acceptablePosts: seq[Message], tick: int) =
  ## Perform belief revision games (BRG).
  let neighborBeliefs = acceptablePosts.mapIt(it.belief)
  let updatedBelief = revision(agent.belief, neighborBeliefs)
  verboseLogger(
    fmt"BR {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.belief = updatedBelief
