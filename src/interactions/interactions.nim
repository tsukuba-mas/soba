import ../types
import ../copyUtils
import sequtils
import opinionDynamics
import brg
import relaxDissonance
import intbrg
import tables

proc performInteractions(agent: Agent, messages: seq[Message], topic: Formulae, tick: int): Agent =
  ## Perform the four procedures (od, br, ba, of) following to the array of updating strategy.
  ## The execution order will be the same with the order in the array.
  var newAgent = agent
  for strategy in agent.updatingStrategy:
    newAgent = case strategy
    of UpdatingStrategy.oddw:
      newAgent.opinionDynamicsDWmodel(messages, tick)
    of UpdatingStrategy.oddg:
      newAgent.opinionDynamicsDeGrootmodel(messages, tick)
    of UpdatingStrategy.br:
      newAgent.beliefRevisionGames(messages, tick)
    of UpdatingStrategy.bavm, UpdatingStrategy.barc:
      newAgent.beliefAlignment(topic, tick, strategy)
    of UpdatingStrategy.`of`:
      newAgent.opinionFormation(topic, tick)
  return newAgent

proc performInteractions*(simulator: Simulator, id2evaluatedMessages: Table[Id, EvaluatedMessages], tick: int): Simulator =
  ## Returns the simulator with agents after interactions.
  ## If an agent is activated to perform (possibly some of) the four procedures (od, br, ba, of),
  ## they do them according to their updating strategy. Otherwise, do nothing.
  let newAgents = simulator.agents.mapIt(
    if id2evaluatedMessages.contains(it.id):
      # for od and br, use acceptable messages only.
      let acceptableMessages = id2evaluatedMessages[it.id].acceptables
      performInteractions(it, acceptableMessages, simulator.topic, tick)
    else:
      it
  )
  simulator.updateAgents(newAgents)