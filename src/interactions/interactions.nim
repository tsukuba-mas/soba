import ../types
import ../copyUtils
import sequtils
import opinionDynamics
import brg
import relaxDissonance
import intbrg
import tables

proc performInteractions(agent: Agent, evaluatedPosts: EvaluatedTimeline, topic: Formulae, tick: int): Agent =
  var newAgent = agent
  for strategy in agent.updatingStrategy:
    newAgent = case strategy
    of UpdatingStrategy.od:
      newAgent.opinionDynamics(evaluatedPosts.acceptables, tick)
    of UpdatingStrategy.br:
      newAgent.beliefRevisionGames(evaluatedPosts.acceptables, tick)
    of UpdatingStrategy.ba:
      newAgent.beliefAlignment(topic, tick)
    of UpdatingStrategy.`of`:
      newAgent.opinionFormation(topic, tick)
  return newAgent

proc performInteractions*(simulator: Simulator, evaluatedPosts: Table[Id, EvaluatedTimeline], tick: int): Simulator =
  let newAgents = simulator.agents.mapIt(
    if evaluatedPosts.hasKey(it.id):
      performInteractions(it, evaluatedPosts[it.id], simulator.topic, tick)
    else:
      it
  )
  simulator.updateAgents(newAgents)