import intbrg
import tables
import sets
import options

type Agent* = ref object
  id*: int
  belief*: Formulae
  opinion*: range[0.0..1.0]

type Message* = ref object
  author*: int
  belief*: Formulae
  opinion*: range[0.0..1.0]
  postedAt*: int
  repostedBy*: Option[int]
  repostedAt*: Option[int]

type Simulator* = ref object
  graph*: Table[int, HashSet[int]]
  agents*: seq[Agent]
  topic*: Formulae