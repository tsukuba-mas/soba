import ../types
import recommendation
import tables
import sequtils
import sets
import utils

proc receiveMessages*(simulator: Simulator, activated: seq[Id]): Table[Id, EvaluatedMessages] =
  let messages = simulator.agents.writeMessage()
  var id2msgs = initTable[Id, EvaluatedMessages]()
  for agent in simulator.agents:
    if not activated.contains(agent.id):
      continue
    let messagesFromNeighbors = agent.neighbors.toSeq.mapIt(messages[int(it)])
    id2msgs[agent.id] = agent.evaluateMessages(messagesFromNeighbors)
  return id2msgs
