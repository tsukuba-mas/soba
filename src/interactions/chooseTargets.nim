import ../randomUtils
import ../types
import options
import sequtils

proc chooseTargets*(agents: seq[Agent], n: int): seq[Id] = 
  ## Choose one or more agents who will act in the iteration randomly.
  ## If n is positive, n agents are chosen; when agents.len < n, @[] is returned.
  ## Otherwise, agents are activated probabilistically.
  if 0 < n:
    # take exactly n agents
    let taken = agents.takeN(n)
    if taken.isSome():
      return taken.get().mapIt(it.id)
    else:
      return @[]
  
  for agent in agents:
    agent.withProbability(agent.activationProb):
      result.add(agent.id)
  if result.len == 0:
    agents.chooseTargets(n)
  else:
    result