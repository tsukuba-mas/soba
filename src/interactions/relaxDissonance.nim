import ../types
import sets
import sequtils
import utils
import intbrg
import options
import ../logger
from ../randomUtils import InitRNGs, Rand
import ../distance
import strformat
import tables
import algorithm

InitRNGs()

proc relaxDissonanceRNGinitializer*(seeds: seq[int]) =
  rngInitializer(seeds)

## Table which associates opinion to beliefs which yield opinions.
## Here, it is assumed that all of the agents share the same cultural values.
var opinion2beliefCache = initTable[Table[Formulae, Opinion], seq[Formulae]]()

proc getBeliefBasedOpinion(belief: Formulae, values: CulturalValues, topic: Formulae): Opinion =
  ## Returns opinion toward `topic` based on `belief`.
  let merged = revision(belief, @[topic])
  zip($merged, values).filterIt(it[0] == '1').mapIt(it[1]).mean().toDecimal

proc getBeliefBasedOpinion(agent: Agent, topic: Formulae): Opinion =
  ## Returns `agent`'s opinion toward `topic`.
  getBeliefBasedOpinion(agent.belief, agent.values, topic)

proc opinionFormation*(agent: var Agent, topics: seq[Formulae], tick: int) =
  ## Returns the agent after opinion formation.
  var newOpinion = initTable[Formulae, Opinion]()
  for topic in topics:
    newOpinion[topic] = agent.opinions[topic] * agent.alpha + (newDecimal(1) - agent.alpha) * agent.getBeliefBasedOpinion(topic)
  
  verboseLogger(
    fmt"OF {tick} {agent.id} {agent.opinions} -> {newOpinion}",
    tick
  )
  agent.opinions = newOpinion

proc overwriteOpinionsBasedOnBeliefs*(agent: var Agent, topics: seq[Formulae], tick: int) =
  ## Overwrite agent's opinions with its beleifs-based opinions.
  ## This is equivalent to OF with alpha = 0.
  let alphaBak = agent.alpha
  agent.alpha = newDecimal(0)
  agent.opinionFormation(topics, tick)
  agent.alpha = alphaBak

proc hamming(x, y: Formulae): int =
  ## Returns the hamming distance (i.e., the number of interpretations that are also model of `x` xor `y`) 
  ## between two formulae `x` and `y`.
  zip($x, $y).filterIt(it[0] != it[1]).len

proc generateOpinionToBeliefCache(topics: seq[Formulae], values: CulturalValues) = 
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

proc flatten[T](xxs: seq[seq[T]]): seq[T] =
  for xs in xxs:
    for x in xs:
      result.add(x)

proc interpretation2preference(values: CulturalValues): seq[int] =
  let allInterpretations = (0..<values.len).toSeq
  let sortedInterpretations = zip(values, allInterpretations).toSeq.sorted().mapIt(it[1])
  result = newSeqWith(values.len, 0)
  for idx, interpretation in sortedInterpretations:
    result[interpretation] = 1 shl idx

proc chooseBest(candidates: seq[Formulae], values: CulturalValues): Formulae =
  if values.toHashSet.len != values.len:
    raise newException(
      SOBADefect,
      fmt"Given value {values} is not injection"
    )
  let preferences = values.interpretation2preference()  # i is preferable to j iff preferences[j] < preferences[j]
  let formula2preference = proc (x: Formulae): int = zip($x, preferences).toSeq.filterIt(it[0] == '1').mapIt(it[1]).sum()
  # It can be assumed that it returns the seq with length 1.
  candidates.argmax(formula2preference)[0]

proc selectOneBelief(candidates: seq[Formulae], by: Agent, strategy: UpdatingStrategy): Formulae =
  case strategy
  of UpdatingStrategy.barc:
    let hammingWithCurrentBelief = proc (x: Formulae): int = hamming(by.belief, x)
    by.choose(candidates.argmin(hammingWithCurrentBelief)).get
  of UpdatingStrategy.bavm:
    candidates.chooseBest(by.values)
  else:
    raise newException(
      SOBADefect,
      fmt"Performing belief alignment while the corresponding strategy is {strategy}"
    )

proc selectBeliefsWithMinimalError(currentOpinion: Table[Formulae, Opinion], topics: seq[Formulae], values: CulturalValues): seq[Formulae] =
  if opinion2beliefCache.len == 0:
    generateOpinionToBeliefCache(topics, values)
  
  let error = proc (opinions: Table[Formulae, Opinion]): DecimalType = distance(opinions, currentOpinion)
  opinion2beliefCache.keys.toSeq.argmin(error).mapIt(opinion2beliefCache[it]).flatten()

proc beliefAlignment*(agent: var Agent, topics: seq[Formulae], tick: int, strategy: UpdatingStrategy) = 
  ## Returns agent after belief alignment.
  let candidates = agent.opinions.selectBeliefsWithMinimalError(topics, agent.values)
  let updatedBelief = candidates.selectOneBelief(agent, strategy)
  verboseLogger(
    fmt"BA {tick} {agent.id} {agent.belief} -> {updatedBelief}",
    tick
  )
  agent.belief = updatedBelief

proc doOfAndBaUntilStable*(agent: var Agent, topics: seq[Formulae], tick: int, threshold: DecimalType, baAlgorithm: UpdatingStrategy) =
  assert baAlgorithm == UpdatingStrategy.barc or baAlgorithm == UpdatingStrategy.bavm
  while true:
    let oldOpinion = agent.opinions
    let oldBelief = agent.belief
    opinionFormation(agent, topics, tick)
    beliefAlignment(agent, topics, tick, baAlgorithm)
    let haveOpinionsConverged = distance(oldOpinion, agent.opinions) <= threshold
    let haveBeliefsConverged = distance(oldBelief, agent.belief) == 0
    if haveOpinionsConverged and haveBeliefsConverged:
      break


proc unifiedSynchronization*(agent: var Agent, topics: seq[Formulae], tick: int) =
  var maxError = high(float)
  var candidates: seq[Formulae] = @[]
  for phi in allFormulae(getNumberOfAtomicProps(agent.values)):
    if (not phi).isTautology():
      continue
    let newOpinions = topics.mapIt((it, getBeliefBasedOpinion(phi, agent.values, it))).toTable
    let ratio = agent.gamma
    let opdiff = distance(agent.opinions, newOpinions)
    let beldiff = distance(agent.belief, phi).float
    let diff = ratio * opdiff + (1.0 - ratio) * beldiff / ($(agent.belief)).len.toFloat
    if diff < maxError:
      maxError = diff
      candidates = @[]
    if maxError == diff:
      candidates.add(phi)
  
  let new = agent.choose(candidates).get()
  agent.belief = new
  agent.opinions = topics.mapIt((it, getBeliefBasedOpinion(new, agent.values, it))).toTable


