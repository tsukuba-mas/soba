import types
import intbrg
import sequtils

proc distance*(x, y: Opinion): float =
  abs(x - y)

proc distance*(x, y: Formulae): int =
  zip($x, $y).filterIt(it[0] != it[1]).len

proc hasSimilarOpinion*(agent: Agent, post: Message): bool =
  distance(agent.opinion, post.opinion) <= agent.epsilon

proc hasSimilarBelief*(agent: Agent, post: Message): bool =
  distance(agent.belief, post.belief) <= agent.delta