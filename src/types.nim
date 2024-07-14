import intbrg
import sets
import options

type Opinion* = float

type FilterStrategy* {.pure.} = enum
  all, obounded, bbounded, both

type UpdatingStrategy* {.pure.} = enum
  independent, badjust, oadjust, bcirc, ocirc

type RewritingStrategy* {.pure.} = enum
  random, repost, recommendation

type Agent* = ref object
  id*: int
  belief*: Formulae
  opinion*: Opinion
  neighbors*: HashSet[int]
  filterStrategy*: FilterStrategy
  updatingStrategy*: UpdatingStrategy
  rewritingStrategy*: RewritingStrategy
  mu*: float  # Torelance threshold for opinion dynamics

type Message* = ref object
  author*: int
  belief*: Formulae
  opinion*: Opinion
  postedAt*: int
  repostedBy*: Option[int]
  repostedAt*: Option[int]

type Simulator* = ref object
  agents*: seq[Agent]
  topic*: Formulae
  posts*: seq[Message]