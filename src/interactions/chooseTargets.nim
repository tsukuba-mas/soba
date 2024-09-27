import ../randomUtils
import ../types

proc chooseTargets*(agents: seq[Agent]): seq[Id] = 
  ## Choose one or more agents who will act in the iteration randomly.
  for agent in agents:
    withProbability(agent.activationProb):
      result.add(agent.id)
  if result.len == 0:
    agents.chooseTargets()
  else:
    result