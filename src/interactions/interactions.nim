import ../types
import sequtils
import opinionDynamics
import brg
import relaxDissonance
import intbrg
import tables
import messageReceiver

proc doOnestep(
  agent: var Agent, 
  strategy: UpdatingStrategy, 
  messages: seq[Message], 
  topics: seq[Formulae], 
  tick: int,
  threshold: DecimalType,
) =
  case strategy
  of UpdatingStrategy.oddw:
    agent.opinionDynamicsDWmodel(topics, messages, tick)
  of UpdatingStrategy.oddg:
    agent.opinionDynamicsDeGrootmodel(topics, messages, tick)
  of UpdatingStrategy.br:
    agent.beliefRevisionGames(messages, tick)
  of UpdatingStrategy.bavm, UpdatingStrategy.barc:
    agent.beliefAlignment(topics, tick, strategy)
  of UpdatingStrategy.`of`:
    agent.opinionFormation(topics, tick)
  of UpdatingStrategy.ofbarc:
    agent.doOfAndBaUntilStable(topics, tick, threshold, UpdatingStrategy.barc)
  of UpdatingStrategy.ofbavm:
    agent.doOfAndBaUntilStable(topics, tick, threshold, UpdatingStrategy.bavm)
  of UpdatingStrategy.us:
    agent.unifiedSynchronization(topics, tick)
  of UpdatingStrategy.fao:
    agent.overwriteOpinionsBasedOnBeliefs(topics, tick)
  of UpdatingStrategy.coh:
    agent.keepingCoherence(topics, tick)


proc isInternalProcess(strategy: UpdatingStrategy): bool = 
  case strategy
  of UpdatingStrategy.barc,
     UpdatingStrategy.bavm,
     UpdatingStrategy.`of`,
     UpdatingStrategy.ofbarc,
     UpdatingStrategy.ofbavm,
     UpdatingStrategy.us,
     UpdatingStrategy.fao,
     UpdatingStrategy.coh:
    true
  else:
    false

proc performPrehoc(
  agent: var Agent, 
  prehocs: seq[UpdatingStrategy], 
  topics: seq[Formulae], 
  threshold: DecimalType
) =
  ## Perform the four procedures (ba or of) following to the array of updating strategy.
  ## The execution order will be the same with the order in the array.
  ## **Note that only internal processes are allowed in this procedure.**
  ## If the social processes (i.e., od or br) are passed, they are ignored.
  for strategy in prehocs:
    if strategy.isInternalProcess():
      agent.doOnestep(strategy, @[], topics, 0, threshold)

proc performPrehoc*(
  simulator: var Simulator, 
  prehocs: seq[UpdatingStrategy], 
  theta: DecimalType,
) =
  ## Perform prehoc procedures.
  for idx, _ in simulator.agents:
    performPrehoc(simulator.agents[idx], prehocs, simulator.topics, theta)

proc performInteractions*(
  simulator: var Simulator, 
  id2evaluatedMessages: Table[Id, EvaluatedMessages], 
  tick: int,
  theta: DecimalType,
) =
  ## Returns the simulator with agents after interactions.
  ## If an agent is activated to perform (possibly some of) the four procedures (od, br, ba, of),
  ## they do them according to their updating strategy. Otherwise, do nothing.
  for process in simulator.updatingProcesses:
    let messages = simulator.receiveMessages(id2evaluatedMessages.keys.toSeq)
    for id in id2evaluatedMessages.keys:
      let acceptableMessages = messages[id].acceptables
      doOnestep(simulator.agents[int(id)], process, acceptableMessages, simulator.topics, tick, theta)

