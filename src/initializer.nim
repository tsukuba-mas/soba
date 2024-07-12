import types
import random
import sets
import intbrg
import strutils
import sequtils
import tables

proc generateRandomBelief(rng: var Rand, atomicProps: int): Formulae =
  let possibleBeliefs = 1 shl atomicProps
  toFormula(toBin(rng.rand(1..<possibleBeliefs), possibleBeliefs))

proc generateInitialBeliefs(rng: var Rand, agents: int, atomicProps: int): seq[Formulae] =
  var beliefs = initHashSet[Formulae]()
  while beliefs.len < agents:
    beliefs.incl(rng.generateRandomBelief(atomicProps))
  var belSeq = beliefs.toSeq
  rng.shuffle(belSeq)
  belSeq

iterator pairs[S, T](xs: seq[S], ys: seq[T]): (S, T) =
  for x in xs:
    for y in ys:
      yield (x, y)

proc randomGraphGenerator(rng: var Rand, vertices: int, edges: int): Table[int, HashSet[int]] =
  let vs = (0..<vertices).toSeq
  var allEdges = pairs(vs, vs).toSeq.filterIt(it[0] != it[1])
  rng.shuffle(allEdges)
  var graph = initTable[int, HashSet[int]]()
  for i in 0..<edges:
    let (u, v) = allEdges[i]
    graph[u].incl(v)
  graph
  
proc initilizeSimulator*(seed: int, agents: int, atomicProps: int, edges: int): Simulator =
  var rng = initRand(seed)
  let initialBeliefs = rng.generateInitialBeliefs(agents, atomicProps)
  let allAgents = (0..<agents).toSeq.mapIt(Agent(id: it, belief: initialBeliefs[it], opinion: rng.rand(0.0..1.0)))
  let graph = rng.randomGraphGenerator(agents, edges)
  Simulator(graph: graph, agents: allAgents, topic: rng.generateRandomBelief(atomicProps))