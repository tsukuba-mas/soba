import types
import intbrg
import sequtils

proc distance*(x, y: Opinion): float =
  abs(x - y)

proc distance*(x, y: Formulae): int =
  zip($x, $y).filterIt(it[0] != it[1]).len