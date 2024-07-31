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
  zip($merged, values).filterIt(it[0] == '1').mapIt(it[1]).mean()

proc getBeliefBasedOpinion(agent: Agent, topic: Formulae): float =
  getBeliefBasedOpinion(agent.belief, agent.values, topic)

proc opinionFormation(agent: Agent, topic: Formulae, tick: int): Agent =
  let newOpinion = agent.opinion * agent.alpha + (1.0 - agent.alpha) * agent.getBeliefBasedOpinion(topic)
  verboseLogger(
    fmt"OF {tick} {agent.id} {agent.opinion} -> {newOpinion}",
    tick
  )
  agent.updateOpinion(newOpinion)

proc hamming(x, y: Formulae): int =
  zip($x, $y).filterIt(it[0] != it[1]).len

proc argmin(xs: seq[Formulae], current: Formulae): seq[Formulae] =
  let distances = xs.mapIt(hamming(it, current))
  let minDist = distances.min
  (0..<xs.len).toSeq.filterIt(distances[it] == minDist).mapIt(xs[it])

proc beliefAlignment(agent: Agent, topic: Formulae, tick: int): Agent =
  var maxError = high(float)
  var currentCandidates: seq[Formulae] = @[]
  for phi in allFormulae(3):
    if (not phi).isTautology():
      continue
    let diff = abs(agent.opinion - getBeliefBasedOpinion(phi, agent.values, topic))
    if diff < maxError:
      maxError = diff
      currentCandidates = @[phi]
    elif diff == maxError:
      currentCandidates.add(phi)

  # choose one of the optimal one randomly
  let updatedBelief = currentCandidates.argmin(agent.belief).choose().get
  verboseLogger(
    fmt"BA {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)

proc relaxDissonance*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], tick: int): Simulator =
  let updatedAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id):
      case it.updatingStrategy
      of UpdatingStrategy.independent:
        it
      of UpdatingStrategy.badjust:
        it.beliefAlignment(simulator.topic, tick)
      of UpdatingStrategy.oadjust:
        it.opinionFormation(simulator.topic, tick)
      of UpdatingStrategy.bcirc:
        let tmp = it.beliefAlignment(simulator.topic, tick)
        tmp.opinionFormation(simulator.topic, tick)
      of UpdatingStrategy.ocirc:
        let tmp = it.opinionFormation(simulator.topic, tick)
        tmp.beliefAlignment(simulator.topic, tick)
    else:
      it
  )
  simulator.updateAgents(updatedAgents)