import types
import sequtils
import tables
import sets
import math

proc getNeighborList(simulator: Simulator, id: int): seq[int] =
  if simulator.graph.hasKey(id):
    return simulator.graph[id].items.toSeq
  else:
    return @[]

proc opinionDynamics(simulator: Simulator, agent: Agent): Agent =
  let neighbors = simulator.getNeighborList(agent.id).mapIt(agent.opinion)
  let updatedOpinion = (agent.opinion + neighbors.sum) / (1 + neighbors.len).toFloat
  Agent(opinion: updatedOpinion, belief: agent.belief, id: agent.id)

proc opinionDynamics*(simulator: Simulator): Simulator =
  let updatedAgents = simulator.agents.mapIt(simulator.opinionDynamics(it))
  Simulator(agents: updatedAgents, graph: simulator.graph, topic: simulator.topic)