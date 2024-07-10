import intbrg
import tables
import sets

type Agent* = ref object
  id*: int
  belief*: Formulae
  opinion*: range[0.0..1.0]

type Simulator* = ref object
  graph*: Table[int, HashSet[int]]
  agents*: seq[Agent]
  topic*: Formulae