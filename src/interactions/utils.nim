import ../types
import ../distance
import sequtils
import intbrg
import strformat
import tables
import algorithm
from math import isPowerOfTwo

proc isAcceptablePost*(agent: Agent, post: Message): bool =
  ## Return `true` iff `post` is acceptable for `agent`.
  let dist = agent.distance(post)
  dist == newDecimal(0)

proc revision*(self: Formulae, others: seq[Formulae]): Formulae = 
  ## Returns the formulae which merge `self` and `others`.
  ## If `others` is empty, `self` itself is returned.
  if others.len == 0:
    self
  else:
    r3(self, others, hamming, sum)

proc writeMessage*(agent: Agent): Message =
  ## Returns a message based on `agent`'s opinion and belief.
  Message(
    author: agent.id,
    belief: agent.belief,
    opinions: agent.opinions,
  )

proc writeMessage*(agents: seq[Agent]): Table[Id, Message] =
  ## Returns messages from all of the agents.
  agents.mapIt((it.id, it.writeMessage)).toTable

proc getAcceptableMessages(agent: Agent, messages: seq[Message]): seq[Message] =
  ## Returns acceptable messages for `agent` in `messages`.
  messages.filterIt(agent.isAcceptablePost(it))

proc getUnacceptableMessages(agent: Agent, messages: seq[Message]): seq[Message] =
  ## Returns unacceptable messages for `agent` in `messages`.
  messages.filterIt(not agent.isAcceptablePost(it))

proc evaluateMessages*(agent: Agent, messages: seq[Message]): EvaluatedMessages =
  ## Returns the result of evaluation of `messages` by `agent`.
  EvaluatedMessages(
    acceptables: agent.getAcceptableMessages(messages),
    unacceptables: agent.getUnacceptableMessages(messages)
  )

proc getNumberOfAtomicProps*[T](values: seq[T]): int =
  ## Return the number of atomic propositions.
  ## It is assumed that len(values) == 2^n where n is the number.
  if not values.len.isPowerOfTwo:
    raise newException(
      SOBADefect,
      fmt"the lengh of values {values} is not power if 2"
    )
  let interpretations = values.len
  var atomicProps = 1
  while true:
    if interpretations == (1 shl atomicProps):
      return atomicProps
    atomicProps += 1

proc mean*(xs: seq[DecimalType]): DecimalType =
  xs.sum / xs.len.newDecimal

proc mean*(xs: seq[Rational]): Rational =
  xs.sum * (1 // xs.len)

proc argm[T, S](xs: seq[T], dist: proc (x: T): S, isMin: bool): seq[T] =
  ## Returns all of elements in `xs` which minimizes the distance function `dist`.
  let distances = xs.mapIt(dist(it))
  let minDist = if isMin: distances.min else: distances.max
  (0..<xs.len).toSeq.filterIt(distances[it] == minDist).mapIt(xs[it])

proc getCmpFunc*(agent: Agent): proc (d1, d2: DifferenceInfo): int =
  case agent.agentOrder
  of AgentOrder.opinion: opinionCmp
  of AgentOrder.belief:  beliefCmp
  of AgentOrder.opbel:   opbelCmp
  of AgentOrder.belop:   belopCmp

proc argm(infos: seq[DifferenceInfo], agent: Agent, order: SortOrder): seq[Id] =
  assert infos.len > 0
  let cmpFunc = agent.getCmpFunc()
  let sortedInfos = infos.sorted(cmp=cmpFunc, order=order)
  var lb = 0
  while lb < sortedInfos.len:
    if cmpFunc(sortedInfos[0], sortedInfos[lb]) != 0:
      break
    lb += 1
  (0..<lb).toSeq.mapIt(sortedInfos[it].id)


proc argmin*[T, S](xs: seq[T], dist: proc (x: T): S) : seq[T] =
  argm(xs, dist, true)

proc argmin*(infos: seq[DifferenceInfo], agent: Agent): seq[Id] =
  argm(infos, agent, SortOrder.Ascending)

proc argmax*[T, S](xs: seq[T], dist: proc (x: T): S) : seq[T] =
  argm(xs, dist, false)

proc argmax*(infos: seq[DifferenceInfo], agent: Agent): seq[Id] =
  argm(infos, agent, SortOrder.Descending)

