import ../types
import ../copyUtils
import options
import sequtils

proc registerPosts*(simulator: Simulator, time: int): Simulator =
  let currentPosts = simulator.agents.mapIt(
    Message(
      author: it.id,
      belief: it.belief,
      opinion: it.opinion,
      postedAt: time,
      repostedAt: none(int),
      repostedBy: none(int),
    )
  )
  simulator.updatePosts(concat(simulator.posts, currentPosts))