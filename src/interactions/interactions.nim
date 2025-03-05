import ../types
import ../copyUtils
import ../distance
import sequtils
import opinionDynamics
import brg
import relaxDissonance
import intbrg
import tables
import messageReceiver

proc doOnestep(agent: Agent, strategy: UpdatingStrategy, messages: seq[Message], topics: seq[Formulae], tick: int): Agent =
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

proc isInternalProcess(strategy: UpdatingStrategy): bool = 
  case strategy
  of UpdatingStrategy.barc, UpdatingStrategy.bavm, UpdatingStrategy.`of`:
    true
  else:
    false

proc performPrehoc(agent: Agent, prehocs: seq[UpdatingStrategy], topics: seq[Formulae]): Agent =
  ## Perform the four procedures (ba or of) following to the array of updating strategy.
  ## The execution order will be the same with the order in the array.
  ## **Note that only internal processes are allowed in this procedure.**
  ## If the social processes (i.e., od or br) are passed, they are ignored.
  var newAgent = agent
  for strategy in prehocs:
    if strategy.isInternalProcess():
      newAgent = newAgent.doOnestep(strategy, @[], topics, 0)
  return newAgent

proc performPrehoc*(simulator: Simulator, prehocs: seq[UpdatingStrategy], canPerformUntilStabilize: bool, theta: DecimalType): Simulator = 
  ## Perform prehoc procedures.
  result = simulator.copy()
  while true:
    let newAgents = result.agents.mapIt(it.performPrehoc(prehocs, simulator.topics))
    let newSimulator = simulator.updateAgents(newAgents)

    # If the prehoc should be done only once, exit
    if not canPerformUntilStabilize:
      return newSimulator

    # If agents stabilize, exit
    let hasOpinionsStabilized = result.agents.zip(newSimulator.agents).allIt(distance(it[0].opinions, it[1].opinions) <= theta)
    let hasBeliefsStabilized = result.agents.zip(newSimulator.agents).allIt(distance(it[0].belief, it[1].belief) == 0)
    if hasOpinionsStabilized and hasBeliefsStabilized:
      return newSimulator

    # Otherwise continue
    result = newSimulator

proc performInteractions*(simulator: Simulator, id2evaluatedMessages: Table[Id, EvaluatedMessages], tick: int): Simulator =
  ## Returns the simulator with agents after interactions.
  ## If an agent is activated to perform (possibly some of) the four procedures (od, br, ba, of),
  ## they do them according to their updating strategy. Otherwise, do nothing.
  var newSimulator = simulator.copy()
  for process in simulator.updatingProcesses:
    let messages = newSimulator.receiveMessages(id2evaluatedMessages.keys.toSeq)
    let newAgents = newSimulator.agents.mapIt(
      if messages.contains(it.id):
        # for od and br, use acceptable messages only.
        let acceptableMessages = messages[it.id].acceptables
        doOnestep(it, process, acceptableMessages, simulator.topics, tick)
      else:
        it
    )
    newSimulator = newSimulator.updateAgents(newAgents)
  return newSimulator