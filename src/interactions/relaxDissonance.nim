import ../types
import sets
import sequtils
import ../copyUtils
import utils
import intbrg
import options
import ../logger
import ../randomUtils
import strformat
import tables
import algorithm
import nimice

## Table which associates opinion to beliefs which yield opinions.
## Here, it is assumed that all of the agents share the same cultural values.
var opinion2beliefCache = initTable[Table[Formulae, Opinion], seq[Formulae]]()

proc getBeliefBasedOpinion(belief: Formulae, values: seq[Rational], topic: Formulae): Opinion =
  ## Returns opinion toward `topic` based on `belief`.
  let merged = revision(belief, @[topic])
  zip($merged, values).filterIt(it[0] == '1').mapIt(it[1]).mean()

proc getBeliefBasedOpinion(agent: Agent, topic: Formulae): Opinion =
  ## Returns `agent`'s opinion toward `topic`.
  getBeliefBasedOpinion(agent.belief, agent.values, topic)

proc opinionFormation*(agent: Agent, topics: seq[Formulae], tick: int): Agent =
  ## Returns the agent after opinion formation.
  var newOpinion = initTable[Formulae, Opinion]()
  for topic in topics:
    newOpinion[topic] = agent.opinions[topic] * agent.alpha + (toRational(1, 1) - agent.alpha) * agent.getBeliefBasedOpinion(topic)
  
  verboseLogger(
    fmt"OF {tick} {agent.id} {agent.opinions} -> {newOpinion}",
    tick
  )
  agent.updateOpinion(newOpinion)

proc hamming(x, y: Formulae): int =
  ## Returns the hamming distance (i.e., the number of interpretations that are also model of `x` xor `y`) 
  ## between two formulae `x` and `y`.
  zip($x, $y).filterIt(it[0] != it[1]).len

proc argm[T](xs: seq[T], dist: proc (x: T): float | int, isMin: bool): seq[T] =
  ## Returns all of elements in `xs` which minimizes the distance function `dist`.
  let distances = xs.mapIt(dist(it))
  let minDist = if isMin: distances.min else: distances.max
  (0..<xs.len).toSeq.filterIt(distances[it] == minDist).mapIt(xs[it])

proc argmin[T](xs: seq[T], dist: proc (x: T): float | int) : seq[T] =
  argm(xs, dist, true)

proc argmax[T](xs: seq[T], dist: proc (x: T): float | int) : seq[T] =
  argm(xs, dist, false)

proc generateOpinionToBeliefCache(topics: seq[Formulae], values: seq[Rational]) = 
  ## Generate the cache of opinions to beliefs, i.e., tables from opinions to
  ## beliefs which yields the key (opinion).
  for phi in allFormulae(getNumberOfAtomicProps(values)):
    if (not phi).isTautology():
      continue
    var opinion = initTable[Formulae, Opinion]()
    for topic in topics:
      opinion[topic] = getBeliefBasedOpinion(phi, values, topic)
    if opinion2beliefCache.hasKey(opinion):
      opinion2beliefCache[opinion].add(phi)
    else:
      opinion2beliefCache[opinion] = @[phi]
  echo opinion2beliefCache

proc flatten[T](xxs: seq[seq[T]]): seq[T] =
  for xs in xxs:
    for x in xs:
      result.add(x)

proc interpretation2preference(values: seq[Rational]): seq[int] =
  let allInterpretations = (0..<values.len).toSeq
  let sortedInterpretations = zip(values, allInterpretations).toSeq.sorted().mapIt(it[1])
  result = newSeqWith(values.len, 0)
  for idx, interpretation in sortedInterpretations:
    result[interpretation] = 1 shl idx

proc chooseBest(candidates: seq[Formulae], values: seq[Rational]): Formulae =
  assert values.toHashSet.len == values.len, "Values should be unique"
  let preferences = values.interpretation2preference()  # i is preferable to j iff preferences[j] < preferences[j]
  let formula2preference = proc (x: Formulae): int = zip($x, preferences).toSeq.filterIt(it[0] == '1').mapIt(it[1]).sum()
  # It can be assumed that it returns the seq with length 1.
  candidates.argmax(formula2preference)[0]

proc selectOneBelief(candidates: seq[Formulae], by: Agent, strategy: UpdatingStrategy): Formulae =
  case strategy
  of UpdatingStrategy.barc:
    let hammingWithCurrentBelief = proc (x: Formulae): int = hamming(by.belief, x)
    candidates.argmin(hammingWithCurrentBelief).choose().get
  of UpdatingStrategy.bavm:
    candidates.chooseBest(by.values)
  else:
    assert false, "Performing belief alignment while the corresponding strategy is " & $strategy
    by.belief

proc beliefAlignment*(agent: Agent, topics: seq[Formulae], tick: int, strategy: UpdatingStrategy): Agent =
  ## Returns agent after belief alignment.
  var maxError = toRational(high(int), 1)
  var keys: seq[Table[Formulae, Opinion]] = @[]
  
  if opinion2beliefCache.len == 0:
    generateOpinionToBeliefCache(topics, agent.values)
  
  for opinion in opinion2beliefCache.keys:
    let diff = topics.mapIt(abs(opinion[it] - agent.opinions[it])).sum()
    if diff < maxError:
      maxError = diff
      keys = @[opinion]
    elif diff == maxError:
      keys.add(opinion)

  # choose one of the optimal one randomly
  let updatedBelief = keys.mapIt(opinion2beliefCache[it]).flatten().selectOneBelief(agent, strategy)
  verboseLogger(
    fmt"BA {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.updateBelief(updatedBelief)
