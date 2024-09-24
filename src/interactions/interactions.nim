import ../types
import ../copyUtils
import sequtils
import opinionDynamics
import brg
import relaxDissonance
import intbrg
import tables

proc performInteractions(agent: Agent, messages: seq[Message], topic: Formulae, tick: int): Agent =
  var newAgent = agent
  for strategy in agent.updatingStrategy:
    newAgent = case strategy
    of UpdatingStrategy.od:
      newAgent.opinionDynamics(messages, tick)
    of UpdatingStrategy.br:
      newAgent.beliefRevisionGames(messages, tick)
    of UpdatingStrategy.ba:
      newAgent.beliefAlignment(topic, tick)
    of UpdatingStrategy.`of`:
      newAgent.opinionFormation(topic, tick)
  return newAgent

proc performInteractions*(simulator: Simulator, id2messages: Table[Id, seq[Message]], tick: int): Simulator =
  let newAgents = simulator.agents.mapIt(
    if id2messages.hasKey(it.id):
      performInteractions(it, id2messages[it.id], simulator.topic, tick)
    else:
      it
  )
  simulator.updateAgents(newAgents)