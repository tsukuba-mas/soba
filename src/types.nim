import intbrg
import sets
import hashes
import tables

type Opinion* = float

type FilterStrategy* {.pure.} = enum
  all, obounded, bbounded, both

type UpdatingStrategy* {.pure.} = enum
  oddw = "oddw", oddg = "oddg", br = "br", `of` = "of", barc = "barc", bavm = "bavm"

type RewritingStrategy* {.pure.} = enum
  none, random, oprecommendation, belrecommendation, bothrecommendation

type Id* = distinct int
proc hash*(id: Id): Hash {.borrow.}
proc `==`*(x, y: Id): bool {.borrow.}
proc `$`*(id: Id): string {.borrow.}
proc toId*(x: int): Id = Id(x)

type Agent* = object
  id*: Id
  belief*: Formulae
  opinions*: Table[Formulae, Opinion]
  neighbors*: HashSet[Id]
  filterStrategy*: FilterStrategy
  updatingStrategy*: seq[UpdatingStrategy]
  rewritingStrategy*: RewritingStrategy
  values*: seq[float]
  alpha*: float
  mu*: float  # Torelance threshold for opinion dynamics
  unfollowProb*: float
  activationProb*: float
  epsilon*: float
  delta*: int

type Message* = object
  author*: Id
  belief*: Formulae
  opinions*: Table[Formulae, Opinion]

type Simulator* = object
  agents*: seq[Agent]
  topics*: seq[Formulae]
  verbose*: bool
  followFrom*: seq[Id]

type CommandLineArgs* = object
  seed*: int
  dir*: string
  n*: int
  tick*: int
  filter*: FilterStrategy
  update*: seq[UpdatingStrategy]
  rewriting*: RewritingStrategy
  prehoc*: seq[UpdatingStrategy]
  verbose*: bool
  mu*: float
  alpha*: float
  unfollowProb*: float
  activationProb*: float
  values*: Table[Id, seq[float]]
  epsilon*: float
  delta*: int
  topics*: seq[Formulae]
  opinions*: Table[Id, Table[Formulae, Opinion]]
  beliefs*: Table[Id, Formulae]
  network*: Table[Id, HashSet[Id]]

type EvaluatedMessages* = object
  acceptables*: seq[Message]
  unacceptables*: seq[Message]