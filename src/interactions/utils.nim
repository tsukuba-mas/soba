import ../types
import ../distance
import ../randomUtils
import sequtils
import sets
import options
import algorithm
import intbrg
import tables

proc isAcceptablePost*(agent: Agent, post: Message): bool =
  ## Return `true` iff `post` is acceptable for `agent`.
  result = 
    case agent.filterStrategy
    of FilterStrategy.all:
      true
    of FilterStrategy.obounded:
      agent.hasSimilarOpinion(post)
    of FilterStrategy.bbounded:
      agent.hasSimilarBelief(post)
    of FilterStrategy.both:
      agent.hasSimilarOpinion(post) and agent.hasSimilarBelief(post)

proc takeN*[T](xs: seq[T], n: int): Option[seq[T]] =
  ## Returns `n` element in `xs` randomly.
  ## If the number of elements in `xs` is less than `n`, `none(T)` is returned; 
  ## otherwise `some(ys)` is returned where `ys` contains exactly `n` elements 
  ## which are also elements of `xs`.
  if xs.len < n:
    none(seq[T])
  else:
    var idx = initHashSet[int]()
    while idx.len < n:
      idx.incl(rand(0, xs.len - 1))
    some(idx.toSeq.sorted.mapIt(xs[it]))

proc choose*[T](xs: seq[T]): Option[T] =
  ## Returns one element in `xs` randomly.
  ## If `xs` is an empty seq, `none(T)` is returned; otherwise `some(x)` is returned
  ## where `x` is an element of `xs`.
  let taken = takeN(xs, 1)
  if taken.isSome():
    some(taken.get()[0])
  else:
    none(T)

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
    opinion: agent.opinion,
  )

proc writeMessage*(agents: seq[Agent]): seq[Message] =
  ## Returns messages from all of the agents.
  agents.map(writeMessage)

proc concat*(evaluatedMessage: EvaluatedMessages): seq[Message] =
  ## Concatnate the messages in `evaluatedMessage`.
  evaluatedMessage.acceptables.concat(evaluatedMessage.unacceptables)

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