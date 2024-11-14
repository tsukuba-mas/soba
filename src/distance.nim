import types
import intbrg
import sequtils
import tables
import math

proc distance*(x, y: Table[Formulae, Opinion]): float =
  ## Returns the Manhattan distance between two opinions `x` and `y`.
  assert x.keys.toSeq == y.keys.toSeq
  let topics = x.keys.toSeq
  topics.mapIt(abs(x[it] - y[it])).sum()

proc distance*(x, y: Formulae): int =
  ## Returns the Hamming distance between two beliefs `x` and `y`.
  zip($x, $y).filterIt(it[0] != it[1]).len

proc hasSimilarOpinion*(agent: Agent, post: Message): bool =
  distance(agent.opinions, post.opinions) <= agent.epsilon

proc hasSimilarBelief*(agent: Agent, post: Message): bool =
  distance(agent.belief, post.belief) <= agent.delta