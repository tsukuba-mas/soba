import types
import intbrg
import sequtils
import tables
import sets
import strformat

proc distance*(x, y: Table[Formulae, Opinion]): DecimalType =
  ## Returns the Manhattan distance between two opinions `x` and `y`.
  if x.keys.toSeq.toHashSet != y.keys.toSeq.toHashSet:
    raise newException(
      SOBADefect,
      fmt"Keys of x and y differs: {x.keys.toSeq} and {y.keys.toSeq}"
    )
  let topics = x.keys.toSeq
  topics.mapIt(abs(x[it] - y[it])).sum()

proc distance*(x, y: Formulae): int =
  ## Returns the Hamming distance between two beliefs `x` and `y`.
  zip($x, $y).filterIt(it[0] != it[1]).len

proc getPossibleModels(beliefs: Formulae): int =
  ($beliefs).len

proc hasSimilarOpinion*(agent: Agent, post: Message): bool =
  distance(agent.opinions, post.opinions) <= agent.epsilon

proc hasSimilarBelief*(agent: Agent, post: Message): bool =
  distance(agent.belief, post.belief) <= agent.delta

proc unifiedDistance*(agent: Agent, message: Message): DecimalType =
  ## Measure the distance between `agent` and `message` with unified distance.
  let opdist = distance(agent.opinions, message.opinions)
  let beldist = distance(agent.belief, message.belief).newDecimal / agent.belief.getPossibleModels.newDecimal
  agent.opDistWeight * opdist + (newDecimal(1) - agent.opDistWeight) * beldist

proc eachDistance(agent: Agent, message: Message): DecimalType =
  ## Measure the distance between `agent` and `message` by evaluating whether opinions (resp. beliefs) are
  ## enough close to `agent`'s.
  ## Returns `0` if both are enough close; return a positive integer otherwise.
  if agent.hasSimilarOpinion(message) and agent.hasSimilarBelief(message):
    newDecimal(0)
  else:
    newDecimal(1)

proc distance*(agent: Agent, message: Message): DecimalType =
  case agent.acceptanceDescision
  of AcceptanceDescision.each:
    agent.eachDistance(message)
  of AcceptanceDescision.unified:
    agent.unifiedDistance(message)

