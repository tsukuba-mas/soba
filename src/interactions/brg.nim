import ../types
import ../copyUtils
import intbrg
import sequtils
import utils
import sets

proc beliefRevisionGames(simulator: Simulator, agent: Agent): Agent =
  let neighborBeliefs = agent.postSelector(simulator.posts).mapIt(it.belief)
  if neighborBeliefs.len == 0:
    return agent
  let updatedBelief = r3(agent.belief, neighborBeliefs, hamming, sum)
  agent.updateBelief(updatedBelief)

proc beliefRevisionGames*(simulator: Simulator, targets: HashSet[int]): Simulator = 
  let updatedAgents = simulator.agents.mapIt(
    if targets.contains(it.id): simulator.beliefRevisionGames(it) else: it
  )
  simulator.updateAgents(updatedAgents)