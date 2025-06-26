import ../types
import ../logger
import sequtils
import strformat
import tables
import intbrg
import utils

proc takeOpinions(acceptablePosts: seq[Message]): Table[Formulae, seq[Opinion]] =
  result = initTable[Formulae, seq[Opinion]]()
  let opinions = acceptablePosts.mapIt(it.opinions)
  for opinion in opinions:
    for topic, op in opinion.pairs():
      if result.hasKey(topic):
        result[topic].add(op)
      else:
        result[topic] = @[op]

proc opinionDynamicsDeGrootmodel*(agent: var Agent, topics: seq[Formulae], acceptablePosts: seq[Message], tick: int) =
  ## Perform opinion dynamics based on the DeGroot model.
  ## Here, the weight for the agent itself and its neighbors are the same.
  let neighbors = acceptablePosts.takeOpinions()
  let updatedOpinion = topics.mapIt((it, mean(@[agent.opinions[it]].concat(neighbors.getOrDefault(it))))).toTable()
  verboseLogger(
    fmt"ODDG {tick} {agent.id} {agent.opinions} -> {updatedOpinion}",
    tick
  )
  agent.opinions = updatedOpinion

proc getNewOpinionByDW(mine: Opinion, others: seq[Opinion], ratio: DecimalType): Opinion =
  if others.len > 0: 
    (newDecimal(1) - ratio) * mine + ratio * mean(others)
  else:
    mine

proc opinionDynamicsDWmodel*(agent: var Agent, topics: seq[Formulae], acceptablePosts: seq[Message], tick: int) =
  ## Perform opinion dynamics based on a bounded confidence model.
  let neighbors = acceptablePosts.takeOpinions()
  let updatedOpinion = topics.mapIt(
    (it, getNewOpinionByDW(agent.opinions[it], neighbors.getOrDefault(it), agent.mu))
  ).toTable
    
  verboseLogger(
    fmt"ODDW {tick} {agent.id} {agent.opinions} -> {updatedOpinion}",
    tick
  )
  agent.opinions = updatedOpinion
