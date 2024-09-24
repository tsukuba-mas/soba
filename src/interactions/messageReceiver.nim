import ../types
import tables
import sequtils
import sets

proc receiveMessages*(simulator: Simulator): Table[Id, seq[Message]] =
  let messages = simulator.agents.mapIt(
    Message(
      author: it.id,
      belief: it.belief,
      opinion: it.opinion,
    )
  )
  var id2msgs = initTable[Id, seq[Message]]()
  for agent in simulator.agents:
    id2msgs[agent.id] = agent.neighbors.toSeq.mapIt(messages[int(it)])
  return id2msgs
