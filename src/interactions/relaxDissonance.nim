import ../types
import sets
import sequtils
import ../copyUtils
import utils
import intbrg
import stats
import options
import ../logger
import strformat
import tables

proc getBeliefBasedOpinion(belief: Formulae, values: seq[float], topic: Formulae): float =
  let merged = revision(belief, @[topic])
  zip($merged, values).mapIt(if it[0] == '1': it[1] else: 0.0).mean()

proc getBeliefBasedOpinion(agent: Agent, topic: Formulae): float =
  getBeliefBasedOpinion(agent.belief, agent.values, topic)

proc opinionFormation(simulator: Simulator, agent: Agent, tick: int): Agent =
  let newOpinion = agent.opinion * agent.alpha + (1.0 - agent.alpha) * agent.getBeliefBasedOpinion(simulator.topic)
  verboseLogger(
    fmt"OF {tick} {agent.id} {agent.opinion} -> {newOpinion}",
    tick
  )
  agent.updateOpinion(newOpinion)

proc opinionFormation*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], tick: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id): simulator.opinionFormation(it, tick)
    else: it
  )
  simulator.updateAgents(updatedAgents)

proc beliefAlignment(simulator: Simulator, agent: Agent, tick: int): Agent =
  var maxError = high(float)
  var currentCandidates: seq[Formulae] = @[]
  for phi in allFormulae(3):
    if (not phi).isTautology():
      continue
    let diff = abs(agent.opinion - getBeliefBasedOpinion(phi, agent.values, simulator.topic))
    if diff < maxError:
      maxError = diff
      currentCandidates = @[phi]
    elif diff == maxError:
      currentCandidates.add(phi)

  # choose one of the optimal one randomly
  let updatedBelief = currentCandidates.choose().get
  verboseLogger(
    fmt"BA {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)

proc beliefAlignment*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], tick: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id): simulator.beliefAlignment(it, tick)
    else: it
  )
  simulator.updateAgents(updatedAgents)