import ../types
import ../copyUtils
import options
import sequtils
import sets
import ../randomUtils
import utils

proc generateNewPost(simulator: Simulator, agent: Agent, time: int): Message =
  withProbability(agent.repostProb):
    let timelines = agent.postSelector(simulator.posts, simulator.screenSize)
    let reposted = timelines.choose()
    if reposted.isSome():
      return Message(
        author: reposted.get.author,
        belief: reposted.get.belief,
        opinion: reposted.get.opinion,
        postedAt: reposted.get.postedAt,
        repostedAt: some(time),
        repostedBy: some(agent.id),
      )
  
  Message(
    author: agent.id,
    belief: agent.belief,
    opinion: agent.opinion,
    postedAt: time,
    repostedAt: none(int),
    repostedBy: none(Id),
  )

proc registerPosts*(simulator: Simulator, time: int, targets: HashSet[Id]): Simulator =
  let currentPosts = simulator.agents.filterIt(
    targets.contains(it.id)
  ).mapIt(
    simulator.generateNewPost(it, time)
  )
  simulator.updatePosts(concat(simulator.posts, currentPosts))