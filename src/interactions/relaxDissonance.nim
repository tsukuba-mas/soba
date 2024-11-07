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

## Table which associates opinion to beliefs which yield opinions.
## Here, it is assumed that all of the agents share the same cultural values.
var opinion2beliefCache = initTable[Opinion, seq[Formulae]]()

proc getBeliefBasedOpinion(belief: Formulae, values: seq[float], topic: Formulae): float =
  ## Returns opinion toward `topic` based on `belief`.
  let merged = revision(belief, @[topic])
  zip($merged, values).filterIt(it[0] == '1').mapIt(it[1]).mean()

proc getBeliefBasedOpinion(agent: Agent, topic: Formulae): float =
  ## Returns `agent`'s opinion toward `topic`.
  getBeliefBasedOpinion(agent.belief, agent.values, topic)

proc opinionFormation*(agent: Agent, topic: Formulae, tick: int): Agent =
  ## Returns the agent after opinion formation.
  let newOpinion = agent.opinion * agent.alpha + (1.0 - agent.alpha) * agent.getBeliefBasedOpinion(topic)
  verboseLogger(
    fmt"OF {tick} {agent.id} {agent.opinion} -> {newOpinion}",
    tick
  )
  agent.updateOpinion(newOpinion)

proc hamming(x, y: Formulae): int =
  ## Returns the hamming distance (i.e., the number of interpretations that are also model of `x` xor `y`) 
  ## between two formulae `x` and `y`.
  zip($x, $y).filterIt(it[0] != it[1]).len

proc argmin[T](xs: seq[T], by: T, dist: proc (x, y: T): float | int): seq[T] =
  ## Returns all of elements in `xs` such that they minimize the distance to `by`.
  let distances = xs.mapIt(dist(it, by))
  let minDist = distances.min
  (0..<xs.len).toSeq.filterIt(distances[it] == minDist).mapIt(xs[it])

proc getNumberOfAtomicProps[T](values: seq[T]): int =
  ## Return the number of atomic propositions.
  ## It is assumed that len(values) == 2^n where n is the number.
  let interpretations = values.len
  var atomicProps = 1
  while true:
    if interpretations == (1 shl atomicProps):
      return atomicProps
    atomicProps += 1

proc generateOpinionToBeliefCache(topic: Formulae, values: seq[float]) = 
  ## Generate the cache of opinions to beliefs, i.e., tables from opinions to
  ## beliefs which yields the key (opinion).
  for phi in allFormulae(getNumberOfAtomicProps(values)):
    if (not phi).isTautology():
      continue
    let opinion = getBeliefBasedOpinion(phi, values, topic)
    if opinion2beliefCache.hasKey(opinion):
      opinion2beliefCache[opinion].add(phi)
    else:
      opinion2beliefCache[opinion] = @[phi]

proc beliefAlignment*(agent: Agent, topic: Formulae, tick: int): Agent =
  ## Returns agent after belief alignment.
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
  let updatedBelief = opinion2beliefCache[key].argmin(agent.belief, hamming).choose().get
  verboseLogger(
    fmt"BA {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)

proc makeOpinionsAndBeliefsCoherent*(simulator: Simulator): Simulator =
  ## Make opinions and beliefs are coherent for all agents.
  ## Here, agents perform just belief alignment.
  generateOpinionToBeliefCache(simulator.topic, simulator.agents[0].values)
  simulator.updateAgents(
    simulator.agents.mapIt(it.beliefAlignment(simulator.topic, 0))
  )