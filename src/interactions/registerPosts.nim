import ../types
import ../copyUtils
import options
import sequtils
import sets
import ../randomUtils
import utils
import ../logger
import strformat
import tables

proc generateNewPost(agent: Agent, evaluatedPosts: EvaluatedTimeline, time: int): Message =
  withProbability(agent.repostProb):
    let timelines = evaluatedPosts.acceptables
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

proc registerPosts*(simulator: Simulator, time: int, evaluatedPosts: Table[Id, EvaluatedTimeline]): Simulator =
  let currentPosts = simulator.agents.filterIt(
    evaluatedPosts.hasKey(it.id)
  ).mapIt(
    it.generateNewPost(evaluatedPosts[it.id], time)
  )
  simulator.updatePosts(concat(simulator.posts, currentPosts))