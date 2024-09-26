import types
import randomUtils
import sets
import intbrg
import strutils
import sequtils
import tables

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
  graph

proc generateFollowFrom(agents: seq[Agent], follows: int): seq[Id] =
  result = newSeqWith(follows, Id(-1))
  var idx = 0
  for agent in agents:
    for neighbor in agent.neighbors:
      result[idx] = agent.id
      idx += 1
  assert(result.allIt(it.int >= 0))
  
proc initilizeSimulator*(options: CommandLineArgs): Simulator =
  let agents = options.n
  let atomicProps = options.atomicProps
  let initialBeliefs = (0..<agents).toSeq.mapIt(rand(1, 255).toBin(1 shl atomicProps).toFormula)
  let graph = randomGraphGenerator(agents, options.follow)
  let opinions = (0..<agents).toSeq.mapIt(rand(0.0, 1.0))
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
      activationProb: options.activationProb,
      values: options.values,
      epsilon: options.epsilon,
      delta: options.delta,
    )
  )
  Simulator(
    agents: allAgents, 
    topic: options.topic,
    verbose: options.verbose,
    followFrom: allAgents.generateFollowFrom(options.follow),
  )