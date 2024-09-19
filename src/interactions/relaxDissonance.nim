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

var opinion2beliefCache = initTable[Opinion, seq[Formulae]]()

proc getBeliefBasedOpinion*(belief: Formulae, values: seq[float], topic: Formulae): float =
  let merged = revision(belief, @[topic])
  zip($merged, values).filterIt(it[0] == '1').mapIt(it[1]).mean()

proc getBeliefBasedOpinion(agent: Agent, topic: Formulae): float =
  getBeliefBasedOpinion(agent.belief, agent.values, topic)

proc opinionFormation*(agent: Agent, topic: Formulae, tick: int): Agent =
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

proc generateOpinionToBeliefCache(topic: Formulae, values: seq[float]) = 
  for phi in allFormulae(3):
    if (not phi).isTautology():
      continue
    let opinion = getBeliefBasedOpinion(phi, values, topic)
    if opinion2beliefCache.hasKey(opinion):
      opinion2beliefCache[opinion].add(phi)
    else:
      opinion2beliefCache[opinion] = @[phi]

proc beliefAlignment*(agent: Agent, topic: Formulae, tick: int): Agent =
  var maxError = high(float)
  var key = 0.0
  
  if opinion2beliefCache.len == 0:
    generateOpinionToBeliefCache(topic, agent.values)
  
  for opinion in opinion2beliefCache.keys:
    let diff = abs(agent.opinion - opinion)
    if diff < maxError:
      maxError = diff
      key = opinion

  # choose one of the optimal one randomly
  let updatedBelief = opinion2beliefCache[key].argmin(agent.belief).choose().get
  verboseLogger(
    fmt"BA {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)
