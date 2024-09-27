import types
import intbrg
import sequtils

proc distance*(x, y: Opinion): float =
  ## Returns the Euclidian distance between two opinions `x` and `y`.
  abs(x - y)

proc distance*(x, y: Formulae): int =
  ## Returns the Hamming distance between two beliefs `x` and `y`.
  zip($x, $y).filterIt(it[0] != it[1]).len

proc hasSimilarOpinion*(agent: Agent, post: Message): bool =
  distance(agent.opinion, post.opinion) <= agent.epsilon

proc hasSimilarBelief*(agent: Agent, post: Message): bool =
  distance(agent.belief, post.belief) <= agent.delta