import ../types
import ../copyUtils
import sequtils
import opinionDynamics
import brg
import relaxDissonance
import intbrg
import tables
import utils

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

proc performInteractions*(simulator: Simulator, id2evaluatedMessages: Table[Id, EvaluatedTimeline], tick: int): Simulator =
  let newAgents = simulator.agents.mapIt(
    if id2evaluatedMessages.contains(it.id):
      let allMessages = id2evaluatedMessages[it.id].concat()
      performInteractions(it, allMessages, simulator.topic, tick)
    else:
      it
  )
  simulator.updateAgents(newAgents)