import ../types
import ../copyUtils
import ../logger
import intbrg
import sequtils
import utils
import tables
import strformat

proc beliefRevisionGames(agent: Agent, acceptablePosts: seq[Message], tick: int): Agent =
  let neighborBeliefs = acceptablePosts.mapIt(it.belief)
  let updatedBelief = revision(agent.belief, neighborBeliefs)
  simulator.verboseLogger(
    fmt"BR {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)

proc beliefRevisionGames*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], tick: int): Simulator = 
  let updatedAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id): it.beliefRevisionGames(evaluatedPosts.acceptables, tick) 
    else: it
  )
  simulator.updateAgents(updatedAgents)