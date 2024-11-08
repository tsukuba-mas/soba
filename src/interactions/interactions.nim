import ../types
import ../copyUtils
import sequtils
import opinionDynamics
import brg
import relaxDissonance
import intbrg
import tables

proc doOnestep(agent: Agent, strategy: UpdatingStrategy, messages: seq[Message], topic: Formulae, tick: int): Agent =
  case strategy
  of UpdatingStrategy.oddw:
    agent.opinionDynamicsDWmodel(messages, tick)
  of UpdatingStrategy.oddg:
    agent.opinionDynamicsDeGrootmodel(messages, tick)
  of UpdatingStrategy.br:
    agent.beliefRevisionGames(messages, tick)
  of UpdatingStrategy.bavm, UpdatingStrategy.barc:
    agent.beliefAlignment(topic, tick, strategy)
  of UpdatingStrategy.`of`:
    agent.opinionFormation(topic, tick)

proc performInteractions(agent: Agent, messages: seq[Message], topic: Formulae, tick: int): Agent =
  ## Perform the four procedures (od, br, ba, of) following to the array of updating strategy.
  ## The execution order will be the same with the order in the array.
  var newAgent = agent
  for strategy in agent.updatingStrategy:
    newAgent = newAgent.doOnestep(strategy, messages, topic, tick)
  return newAgent

proc isInternalProcess(strategy: UpdatingStrategy): bool = 
  case strategy
  of UpdatingStrategy.barc, UpdatingStrategy.bavm, UpdatingStrategy.`of`:
    true
  else:
    false

proc performPrehoc(agent: Agent, prehocs: seq[UpdatingStrategy], topic: Formulae): Agent =
  ## Perform the four procedures (ba or of) following to the array of updating strategy.
  ## The execution order will be the same with the order in the array.
  ## **Note that only internal processes are allowed in this procedure.**
  ## If the social processes (i.e., od or br) are passed, they are ignored.
  var newAgent = agent
  for strategy in prehocs:
    if strategy.isInternalProcess():
      newAgent = newAgent.doOnestep(strategy, @[], topic, 0)
  return newAgent

proc performPrehoc*(simulator: Simulator, prehocs: seq[UpdatingStrategy]): Simulator = 
  let newAgents = simulator.agents.mapIt(it.performPrehoc(prehocs, simulator.topic))
  simulator.updateAgents(newAgents)

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