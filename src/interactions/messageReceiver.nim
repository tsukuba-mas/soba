import ../types
import tables
import sequtils
import sets

proc writeMessage(agent: Agent): Message =
  Message(
    author: agent.id,
    belief: agent.belief,
    opinion: agent.opinion,
  )

proc writeMessage*(agents: seq[Agent]): seq[Message] =
  agents.map(writeMessage)

proc receiveMessages*(simulator: Simulator, activated: seq[Id]): Table[Id, seq[Message]] =
  let messages = simulator.agents.writeMessage()
  var id2msgs = initTable[Id, seq[Message]]()
  for agent in simulator.agents:
    if not activated.contains(agent.id):
      continue
    id2msgs[agent.id] = agent.neighbors.toSeq.mapIt(messages[int(it)])
  return id2msgs
