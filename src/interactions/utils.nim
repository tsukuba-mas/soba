import ../types
import ../distance
import sequtils
import intbrg
from math import isPowerOfTwo

proc isAcceptablePost*(agent: Agent, post: Message): bool =
  ## Return `true` iff `post` is acceptable for `agent`.
  agent.hasSimilarOpinion(post) and agent.hasSimilarBelief(post)

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

proc writeMessage*(agents: seq[Agent]): seq[Message] =
  ## Returns messages from all of the agents.
  agents.map(writeMessage)

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
  assert values.len.isPowerOfTwo
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