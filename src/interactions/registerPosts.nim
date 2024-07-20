import ../types
import ../copyUtils
import options
import sequtils
import sets
import ../randomUtils
import utils
import ../logger
import strformat

proc generateNewPost(simulator: Simulator, agent: Agent, time: int): Message =
  withProbability(agent.repostProb):
    let timelines = agent.getAcceptablePosts(simulator.posts, simulator.screenSize)
    let reposted = timelines.choose()
    if reposted.isSome():
      let repost = Message(
        author: reposted.get.author,
        belief: reposted.get.belief,
        opinion: reposted.get.opinion,
        postedAt: reposted.get.postedAt,
        repostedAt: some(time),
        repostedBy: some(agent.id),
      )
      simulator.verboseLogger(
        fmt"REPOST {time} {agent.id} {repost.author} {repost.belief} {repost.opinion}",
        time
      )
      return repost
  
  let post = Message(
    author: agent.id,
    belief: agent.belief,
    opinion: agent.opinion,
    postedAt: time,
    repostedAt: none(int),
    repostedBy: none(Id),
  )
  simulator.verboseLogger(
    fmt"POST {time} {agent.id} {post.belief} {post.opinion}",
    time
  )
  return post

proc registerPosts*(simulator: Simulator, time: int, targets: HashSet[Id]): Simulator =
  let currentPosts = simulator.agents.filterIt(
    targets.contains(it.id)
  ).mapIt(
    simulator.generateNewPost(it, time)
  )
  simulator.updatePosts(concat(simulator.posts, currentPosts))