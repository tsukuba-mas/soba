import types
import randomUtils
import sets
import intbrg
import strutils
import sequtils
import tables

proc generateRandomBelief(atomicProps: int): Formulae =
  let uniqueModels = 1 shl atomicProps
  let possibleBeliefs = 1 shl uniqueModels
  toFormula(toBin(rand(1, possibleBeliefs - 1), uniqueModels))

proc generateInitialBeliefs(agents: int, atomicProps: int): seq[Formulae] =
  var beliefs = initHashSet[Formulae]()
  while beliefs.len < agents:
    beliefs.incl(generateRandomBelief(atomicProps))
  beliefs.toSeq.shuffle()

iterator pairs[S, T](xs: seq[S], ys: seq[T]): (S, T) =
  for x in xs:
    for y in ys:
      yield (x, y)

proc randomGraphGenerator(vertices: int, edges: int): Table[int, HashSet[int]] =
  let vs = (0..<vertices).toSeq
  var allEdges = pairs(vs, vs).toSeq.filterIt(it[0] != it[1]).shuffle()
  var graph = initTable[int, HashSet[int]]()
  for v in 0..<vertices:
    graph[v] = initHashSet[int]()
  for i in 0..<edges:
    let (u, v) = allEdges[i]
    graph[u].incl(v)
  graph
  
proc initilizeSimulator*(agents: int, atomicProps: int, edges: int): Simulator =
  let initialBeliefs = generateInitialBeliefs(agents, atomicProps)
  let graph = randomGraphGenerator(agents, edges)
  let allAgents = (0..<agents).toSeq.mapIt(
    Agent(
      id: it, 
      belief: initialBeliefs[it], 
      opinion: rand(0.0, 1.0),
      neighbors: graph[it],
      filterStrategy: FilterStrategy.all,
      updatingStrategy: UpdatingStrategy.independent,
      rewritingStrategy: RewritingStrategy.random,
      mu: 0.5,
    )
  )
  Simulator(
    agents: allAgents, 
    topic: generateRandomBelief(atomicProps),
    posts: @[],
  )