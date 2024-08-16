import types
import randomUtils
import sets
import intbrg
import strutils
import sequtils
import tables

proc generateInitialBeliefs(agents: int, atomicProps: int): seq[Formulae] =
  var res = newSeqWith(agents, "")
  let uniqueModels = 1 shl atomicProps
  let ones = agents div 2
  for _ in 0..<uniqueModels:
    var q = newSeqWith(ones, "1").concat(newSeqWith(agents - ones, "0")).shuffle()
    for i in 0..<agents:
      res[i] = res[i] & q[i]
  let nomodel = "0".repeat(uniqueModels)
  if nomodel in res:
    generateInitialBeliefs(agents, atomicProps)
  else:
    res.map(toFormula)

iterator pairs[S, T](xs: seq[S], ys: seq[T]): (S, T) =
  for x in xs:
    for y in ys:
      yield (x, y)

proc randomGraphGenerator(vertices: int, edges: int): Table[Id, HashSet[Id]] =
  let vs = (0..<vertices).toSeq.map(toId)
  var allEdges = pairs(vs, vs).toSeq.filterIt(it[0] != it[1]).shuffle()
  var graph = initTable[Id, HashSet[Id]]()
  for v in 0..<vertices:
    graph[v.toId] = initHashSet[Id]()
  for i in 0..<edges:
    let (u, v) = allEdges[i]
    graph[u].incl(v)
  if graph.keys.toSeq.allIt(graph[it].len > 0):
    graph
  else:
    vertices.randomGraphGenerator(edges)
  
proc initilizeSimulator*(options: CommandLineArgs): Simulator =
  let agents = options.n
  let atomicProps = options.atomicProps
  let initialBeliefs = generateInitialBeliefs(agents, atomicProps)
  let graph = randomGraphGenerator(agents, options.follow)
  let opinions = (0..<agents).toSeq.mapIt(it / (agents - 1)).shuffle()
  let allAgents = (0..<agents).toSeq.mapIt(
    Agent(
      id: it.toId, 
      belief: initialBeliefs[it], 
      opinion: opinions[it],
      neighbors: graph[it.toId],
      filterStrategy: options.filter,
      updatingStrategy: options.update,
      rewritingStrategy: options.rewriting,
      mu: options.mu,
      alpha: options.alpha,
      unfollowProb: options.unfollowProb,
      repostProb: options.repostProb,
      values: options.values,
      epsilon: options.epsilon,
      delta: options.delta,
    )
  )
  Simulator(
    agents: allAgents, 
    topic: options.topic,
    posts: @[],
    screenSize: options.screenSize,
    verbose: options.verbose,
  )