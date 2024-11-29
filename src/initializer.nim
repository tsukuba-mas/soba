import types
import sets
import intbrg
import strformat
import sequtils
import tables

proc generateFollowFrom(agents: seq[Agent]): seq[Id] =
  ## Returns sequence of the agents corresponding to the network they form.
  ## It is sorted in ascending order by agents' id.
  ## If an agent follow N other agents, its id appears N times.
  ## 
  ## For example, let $G=(V,E)$ where $V=\{1,2,3\}$ and 
  ## $E=\{(1,2),(1,3),(2,3)\}$. Then, this procedure returns the sequence
  ## `@[1,1,2]` because agent 1 follows two other agents, etc.
  result = @[]
  var idx = 0
  for agent in agents:
    if agent.neighbors.len == 0:
      raise newException(
        SOBADefect,
        fmt"Agent {agent.id} has no neighbors (should have at least one)"
      )
    for neighbor in agent.neighbors:
      result.add(agent.id)
      idx += 1
  if not result.allIt(it.int >= 0):
    raise newException(
      SOBADefect,
      fmt"Agent id should be non-negative"
    )
  
proc initilizeSimulator*(options: CommandLineArgs): Simulator =
  ## Returns simulator initialized with `options`.
  let agents = options.n
  let atoms = options.atoms
  let allIds = (0..<agents).toSeq.map(toId)

  # Verify everything is specified correctly
  let models = 1 shl atoms
  if not options.topics.allIt(($(it)).len == models):
    raise newException(
      SOBADefect,
      fmt"Topics are specified wrongly: expected #atoms is {atoms}, given topics is {options.topics}"
    )
  for id in allIds:
    if not ($(options.beliefs[id])).len == models:
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s beliefs are specified wrongly: expected #atoms is {atoms} but {options.beliefs[id]}"
      ) 
    if not options.opinions[id].len == options.topics.len:
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s opinions are specified wrongly: there are {options.topics.len} topics and {options.opinions[id].len} opinions"
      )
    if not options.topics.allIt(options.opinions[id].contains(it)):
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s opinions are specified wrongly: topics are {options.topics} but opinions are toward {options.opinions[id].keys.toSeq}"
      )
    if not options.values[id].len == models:
      raise newException(
        SOBADefect,
        fmt"Agent {id}'s values are specified wrongly: values are length of {options.values[id].len} but expected length is {models}"
      )

  # initialize agents
  let allAgents = allIds.mapIt(
    Agent(
      id: it, 
      belief: options.beliefs[it], 
      opinions: options.opinions[it],
      neighbors: options.network[it],
      rewritingStrategy: options.rewriting,
      mu: options.mu,
      alpha: options.alpha,
      unfollowProb: options.unfollowProb,
      activationProb: options.activationProb,
      values: options.values[it],
      epsilon: options.epsilon,
      delta: options.delta,
    )
  )
  Simulator(
    agents: allAgents, 
    topics: options.topics,
    verbose: options.verbose,
    followFrom: allAgents.generateFollowFrom(),
    updatingProcesses: options.update,
  )