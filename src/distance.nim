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

proc hasSimilarOpinion*(agent: Agent, post: Message): bool =
  distance(agent.opinions, post.opinions) <= agent.epsilon

proc hasSimilarBelief*(agent: Agent, post: Message): bool =
  distance(agent.belief, post.belief) <= agent.delta

proc eachDistance(agent: Agent, message: Message): DecimalType =
  ## Measure the distance between `agent` and `message` by evaluating whether opinions (resp. beliefs) are
  ## enough close to `agent`'s.
  ## Returns `0` if both are enough close; return a positive integer otherwise.
  if agent.hasSimilarOpinion(message) and agent.hasSimilarBelief(message):
    newDecimal(0)
  else:
    newDecimal(1)

proc distance*(agent: Agent, message: Message): DecimalType =
  agent.eachDistance(message)

proc opinionCmp*(d1, d2: DifferenceInfo): int =
  ## Compare `d1` and `d2` just based on opinions:
  if d1.opinions < d2.opinions:
    -1
  elif d1.opinions == d2.opinions:
    0
  else:
    1

proc beliefCmp*(d1, d2: DifferenceInfo): int =
  ## Compare `d1` and `d2` just based on beliefs.
  if d1.beliefs < d2.beliefs:
    -1
  elif d1.beliefs == d2.beliefs:
    0
  else:
    1

proc opbelCmp*(d1, d2: DifferenceInfo): int =
  ## Compare `d1` and `d2` with the lexicographical order (opinions -> beliefs).
  if d1.opinions < d2.opinions or (d1.opinions == d2.opinions and d1.beliefs < d2.beliefs):
    -1
  elif d1.opinions == d2.opinions and d1.beliefs == d2.beliefs:
    0
  else:
    1

proc belopCmp*(d1, d2: DifferenceInfo): int =
  ## Compare `d1` and `d2` with the lexicographical order (beliefs -> opinions).
  if d1.beliefs < d2.beliefs or (d1.beliefs == d2.beliefs and d1.opinions < d2.opinions):
    -1
  elif d1.opinions == d2.opinions and d1.beliefs == d2.beliefs:
    0
  else:
    1

proc toDifferenceInfo*(message: Message, agent: Agent): DifferenceInfo =
  DifferenceInfo(
    opinions: distance(agent.opinions, message.opinions),
    beliefs: distance(agent.belief, message.belief),
    id: message.author,
  )

proc toDifferenceInfo*(messages: seq[Message], agent: Agent): seq[DifferenceInfo] =
  messages.mapIt(it.toDifferenceInfo(agent))
  
