import ../types
import ../copyUtils
import intbrg
import sequtils
import utils

proc beliefRevisionGames(simulator: Simulator, agent: Agent): Agent =
  let neighborBeliefs = agent.postSelector(simulator.posts).mapIt(it.belief)
  let updatedBelief = r3(agent.belief, neighborBeliefs, hamming, sum)
  agent.updateBelief(updatedBelief)

proc beliefRevisionGames*(simulator: Simulator): Simulator = 
  let updatedAgents = simulator.agents.mapIt(simulator.beliefRevisionGames(it))
  simulator.updateAgents(updatedAgents)