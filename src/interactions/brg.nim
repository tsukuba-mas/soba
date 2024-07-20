import ../types
import ../copyUtils
import ../logger
import intbrg
import sequtils
import utils
import sets
import strformat

proc beliefRevisionGames(simulator: Simulator, agent: Agent, tick: int): Agent =
  let neighborBeliefs = agent.getAcceptablePosts(simulator.posts, simulator.screenSize).mapIt(it.belief)
  let updatedBelief = revision(agent.belief, neighborBeliefs)
  simulator.verboseLogger(
    fmt"BR {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)

proc beliefRevisionGames*(simulator: Simulator, targets: HashSet[Id], tick: int): Simulator = 
  let updatedAgents = simulator.agents.mapIt(
    if targets.contains(it.id): simulator.beliefRevisionGames(it, tick) else: it
  )
  simulator.updateAgents(updatedAgents)