import ../types
import ../copyUtils
import options
import sequtils
import sets
import ../randomUtils
import utils

proc generateNewPost(simulator: Simulator, agent: Agent, time: int): Message =
  withProbability(agent.repostProb):
    let timelines = agent.postSelector(simulator.posts)
    let reposted = timelines.takeN(1)
    if reposted.len > 0:
      return Message(
        author: reposted[0].author,
        belief: reposted[0].belief,
        opinion: reposted[0].opinion,
        postedAt: reposted[0].postedAt,
        repostedAt: some(time),
        repostedBy: some(agent.id),
      )
  
  Message(
    author: agent.id,
    belief: agent.belief,
    opinion: agent.opinion,
    postedAt: time,
    repostedAt: none(int),
    repostedBy: none(int),
  )

proc registerPosts*(simulator: Simulator, time: int, targets: HashSet[int]): Simulator =
  let currentPosts = simulator.agents.filterIt(
    targets.contains(it.id)
  ).mapIt(
    simulator.generateNewPost(it, time)
  )
  simulator.updatePosts(concat(simulator.posts, currentPosts))