import intbrg
import sets
import hashes

type Opinion* = float

type FilterStrategy* {.pure.} = enum
  all, obounded, bbounded, both

type UpdatingStrategy* {.pure.} = enum
  od = "od", br = "br", `of` = "of", ba = "ba"

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
  opinion*: Opinion
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
  opinion*: Opinion

type Simulator* = object
  agents*: seq[Agent]
  topic*: Formulae
  verbose*: bool
  followFrom*: seq[Id]

type CommandLineArgs* = object
  seed*: int
  dir*: string
  n*: int
  follow*: int
  tick*: int
  filter*: FilterStrategy
  update*: seq[UpdatingStrategy]
  rewriting*: RewritingStrategy
  verbose*: bool
  mu*: float
  alpha*: float
  unfollowProb*: float
  activationProb*: float
  values*: seq[float]
  epsilon*: float
  delta*: int
  atomicProps*: int
  topic*: Formulae

type EvaluatedMessages* = object
  acceptables*: seq[Message]
  unacceptables*: seq[Message]