import ../types
import ../copyUtils
import options
import sequtils
import sets

proc registerPosts*(simulator: Simulator, time: int, targets: HashSet[int]): Simulator =
  let currentPosts = simulator.agents.filterIt(
    targets.contains(it.id)
  ).mapIt(
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