import ../types
import sequtils
import sets
import options

proc postSelector*(agent: Agent, posts: seq[Message]): seq[Message] =
  posts.filterIt(
    agent.neighbors.contains(it.author) or (it.repostedBy.isSome() and agent.neighbors.contains(it.repostedBy.get()))
  )