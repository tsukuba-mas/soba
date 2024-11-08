import types
import randomUtils
import sets
import intbrg
import strutils
import sequtils
import tables
import interactions/utils

iterator pairs[S, T](xs: seq[S], ys: seq[T]): (S, T) =
  ## Yield all of the element of Cartesian product.
  ## The difference between this and the standard `algorithm.product` is that 
  ## this is an iterator.
  for x in xs:
    for y in ys:
      yield (x, y)

proc randomGraphGenerator(vertices: int, edges: int): Table[Id, HashSet[Id]] =
  ## Generate random graph with `vertices` nodes and `edges` edges.
  ## Note that all of the outdegrees of each of the edges are 1 or more.
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

proc generateFollowFrom(agents: seq[Agent], follows: int): seq[Id] =
  ## Returns sequence of the agents corresponding to the network they form.
  ## It is sorted in ascending order by agents' id.
  ## If an agent follow N other agents, its id appears N times.
  ## 
  ## For example, let $G=(V,E)$ where $V=\{1,2,3\}$ and 
  ## $E=\{(1,2),(1,3),(2,3)\}$. Then, this procedure returns the sequence
  ## `@[1,1,2]` because agent 1 follows two other agents, etc.
  result = newSeqWith(follows, Id(-1))
  var idx = 0
  for agent in agents:
    for neighbor in agent.neighbors:
      result[idx] = agent.id
      idx += 1
  assert(result.allIt(it.int >= 0))
  
proc initilizeSimulator*(options: CommandLineArgs): Simulator =
  ## Returns simulator initialized with `options`.
  let agents = options.n
  let atomicProps = options.values.getNumberOfAtomicProps()
  let initialBeliefs = (0..<agents).toSeq.mapIt(rand(1, 255).toBin(1 shl atomicProps).toFormula)
  let graph = randomGraphGenerator(agents, options.follow)
  let opinions = (0..<agents).toSeq.mapIt(rand(0.0, 1.0))
  let allAgents = (0..<agents).toSeq.mapIt(
    Agent(
      id: it.toId, 
      belief: initialBeliefs[it], 
      opinions: @[(options.topics[0], opinions[it])].toTable,  # temporal implementation
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
    topics: options.topics,
    verbose: options.verbose,
    followFrom: allAgents.generateFollowFrom(options.follow),
  )