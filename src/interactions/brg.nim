import ../types
import intbrg
import utils
import sequtils

proc beliefRevisionGames(simulator: Simulator, agent: Agent): Agent =
  let neighborBeliefs = simulator.getNeighborList(agent.id).mapIt(simulator.agents[it].belief)
  let updatedBelief = r3(agent.belief, neighborBeliefs, hamming, sum)
  Agent(opinion: agent.opinion, belief: updatedBelief, id: agent.id)

proc beliefRevisionGames*(simulator: var Simulator) = 
  let updatedAgents = simulator.agents.mapIt(simulator.beliefRevisionGames(it))
  simulator.agents = updatedAgents