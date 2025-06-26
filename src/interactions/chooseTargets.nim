from ../randomUtils import InitRNGs, Rand
import ../types
import options
import sequtils

InitRNGs()

proc chooseTargetsRNGinitializer*(seeds: seq[int]) =
  rngInitializer(seeds)

proc chooseTargets*(agents: seq[Agent]): seq[Id] = 
  ## Choose one or more agents who will act in the iteration randomly.
  for agent in agents:
    agent.withProbability(agent.activationProb):
      result.add(agent.id)
  if result.len == 0:
    agents.chooseTargets()
  else:
    result
