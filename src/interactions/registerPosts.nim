import ../types
import options
import sequtils

proc registerPosts*(simulator: var Simulator, time: int) =
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
  simulator.posts = concat(simulator.posts, currentPosts)