import intbrg

type Agent* = ref object
  id*: int
  belief*: Formulae
  opinion*: range[0.0..1.0]