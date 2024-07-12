import ../types
import intbrg
import utils
import sequtils

proc beliefRevisionGames(simulator: Simulator, agent: Agent): Agent =
  let neighborBeliefs = simulator.getNeighborList(agent.id).mapIt(simulator.agents[it].belief)
  let updatedBelief = r3(agent.belief, neighborBeliefs, hamming, sum)
  Agent(opinion: agent.opinion, belief: updatedBelief, id: agent.id)

proc beliefRevisionGames*(simulator: Simulator): Simulator = 
  let updatedAgents = simulator.agents.mapIt(simulator.beliefRevisionGames(it))
  Simulator(agents: updatedAgents, graph: simulator.graph, topic: simulator.topic)