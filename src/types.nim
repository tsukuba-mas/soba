import intbrg
import sets
import options
import hashes

type Opinion* = float

type FilterStrategy* {.pure.} = enum
  all, obounded, bbounded, both

type UpdatingStrategy* {.pure.} = enum
  independent, badjust, oadjust, bcirc, ocirc

type RewritingStrategy* {.pure.} = enum
  random, repost, recommendation

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
  updatingStrategy*: UpdatingStrategy
  rewritingStrategy*: RewritingStrategy
  mu*: float  # Torelance threshold for opinion dynamics
  repostProb*: float
  unfollowProb*: float

type Message* = object
  author*: Id
  belief*: Formulae
  opinion*: Opinion
  postedAt*: int
  repostedBy*: Option[Id]
  repostedAt*: Option[int]

type Simulator* = object
  agents*: seq[Agent]
  topic*: Formulae
  posts*: seq[Message]
  screenSize*: int
  verbose*: bool