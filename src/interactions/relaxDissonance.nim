import ../types
import sets
import sequtils
import ../copyUtils
import intbrg
import stats

proc getBeliefBasedOpinion(agent: Agent, topic: Formulae): float =
  let merged = r3(agent.belief, @[topic], hamming, sum)
  zip($merged, agent.values).mapIt(if it[0] == '1': it[1] else: 0.0).mean()

proc opinionFormation(simulator: Simulator, agent: Agent, tick: int): Agent =
  let newOpinion = agent.opinion * agent.alpha + (1.0 - agent.alpha) * agent.getBeliefBasedOpinion(simulator.topic)
  agent.updateOpinion(newOpinion)

proc opinionFormation*(simulator: Simulator, targets: HashSet[Id], tick: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if targets.contains(it.id): simulator.opinionFormation(it, tick)
    else: it
  )
  simulator.updateAgents(updatedAgents)
