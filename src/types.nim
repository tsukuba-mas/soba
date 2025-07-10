## Type definitions and basic procedures for these types.

import intbrg
import sets
import hashes
import tables
import rationals as stdrat
import sequtils
import strutils
import strformat

# installation via nimble does not work...
# instead, importing it directly from the source code as a submodule
# import ../nimdecimal/decimal/decimal
# Apparently the memory allocated by the wrapped C library is not freed...
# This leads to fuge consumption of memory.
# Hence so far standard `float` is used.
# Most of the codes are preserved intentionally so that better decimal number library
# can be applied easily.

type DecimalType* = float

# Specific defect type for this simulator
type SOBADefect* = object of Defect

# Type for opinion
# To avoid comparison and addition/subtraction to floats,
# represent opinions as decimal numbers.
type Opinion* = DecimalType
# export DecimalType, decimal.`-`, decimal.`+`, decimal.`*`, 
#   decimal.`/`, decimal.`==`, decimal.`+=`, decimal.`abs`, 
#   decimal.`$`, decimal.newDecimal, decimal.`<`, decimal.`<=`,
#   decimal.setPrec

proc newDecimal*(x: int): DecimalType = float(x)
proc newDecimal*(x: string): DecimalType = parseFloat(x)
proc newDecimal*(x: float): DecimalType = float(x)
proc setPrec*(x: int) = discard
proc sum[T](xs: seq[T], init: T): T = xs.foldl(a + b, init)
proc sum*(xs: seq[DecimalType]): DecimalType = xs.sum(newDecimal(0))
# proc hash*(x: DecimalType): Hash = hash($x)

proc splitBySlash(rawData: string): (string, string) =
  ## Parse rational number (e.g., 2/3) and return as a value with type `Opinion`.
  let splited = rawData.split("/")
  if splited.len != 2:
    raise newException(
      SOBADefect,
      fmt"Unknown format of rational number, {rawData} is given"
    )
  let num = splited[0].strip
  let den = splited[1].strip
  return (num, den)

proc parseDecimal*(rawData: string): DecimalType =
  let (num, den) = rawData.splitBySlash()
  newDecimal(num) / newDecimal(den)

type UpdatingStrategy* {.pure.} = enum
  oddw = "oddw", oddg = "oddg", br = "br", `of` = "of", barc = "barc", bavm = "bavm",
  ofbarc = "ofbarc*", ofbavm = "ofbavm*"

type RewritingStrategy* {.pure.} = enum
  none, random, swapMaxMin

type AgentOrder* {.pure.} = enum
  opinion, belief, opbel, belop

type InitNetworkConfig* {.pure.} = enum
  random, randomLowerMOD

type Id* = distinct int
proc hash*(id: Id): Hash {.borrow.}
proc `==`*(x, y: Id): bool {.borrow.}
proc `<`*(x, y: Id): bool {.borrow.}
proc `$`*(id: Id): string {.borrow.}
proc toId*(x: int): Id = Id(x)

# To avoid repeating [int]
type Rational* = stdrat.Rational[int]
export stdrat.`//`, stdrat.`*`, stdrat.`<`, stdrat.`$`
proc `*`*(x, y: Rational): Rational = stdrat.`*`(x, y)
proc sum*(xs: seq[Rational]): Rational = xs.sum(0 // 1)

proc parseRational*(rawData: string): Rational =
  let (num, den) = rawData.splitBySlash()
  num.parseInt // den.parseInt

proc toDecimal*(rat: Rational): DecimalType =
  newDecimal(rat.num) / newDecimal(rat.den)


type CulturalValues* = seq[Rational]

type Agent* = object
  id*: Id
  belief*: Formulae
  opinions*: Table[Formulae, Opinion]
  neighbors*: HashSet[Id]
  rewritingStrategy*: RewritingStrategy
  values*: CulturalValues
  alpha*: DecimalType
  mu*: DecimalType  # Torelance threshold for opinion dynamics
  unfollowProb*: float
  activationProb*: float
  epsilon*: DecimalType
  delta*: int
  agentOrder*: AgentOrder

type Message* = object
  author*: Id
  belief*: Formulae
  opinions*: Table[Formulae, Opinion]

type DifferenceInfo* = object
  opinions*: DecimalType
  beliefs*: int
  id*: Id

type Simulator* = object
  agents*: seq[Agent]
  topics*: seq[Formulae]
  verbose*: bool
  followFrom*: seq[Id]
  updatingProcesses*: seq[UpdatingStrategy]
  numberOfActivatedAgents*: int

type CommandLineArgs* = object
  seed*: int
  dir*: string
  n*: int
  edges*: int
  networkType*: InitNetworkConfig
  atoms*: int
  tick*: int
  update*: seq[UpdatingStrategy]
  rewriting*: RewritingStrategy
  prehoc*: seq[UpdatingStrategy]
  verbose*: bool
  mu*: DecimalType
  alpha*: DecimalType
  unfollowProb*: float
  activationProb*: float
  values*: Table[Id, CulturalValues]
  epsilon*: DecimalType
  delta*: int
  topics*: seq[Formulae]
  opinions*: Table[Id, Table[Formulae, Opinion]]
  beliefs*: Table[Id, Formulae]
  network*: Table[Id, HashSet[Id]]
  prec*: int
  activatedAgents*: int
  maximalOpinionChange*: DecimalType
  agentOrder*: AgentOrder
  forceConnectedNetwork*: bool

type EvaluatedMessages* = object
  acceptables*: seq[Message]
  unacceptables*: seq[Message]
