import ../types
import sequtils
import sets
import options

proc isRelatedToNeighbors(neighbors: HashSet[int], post: Message): bool =
  let isInitialAuthor = neighbors.contains(post.author)
  let isRepostAuthor = post.repostedBy.isSome() and neighbors.contains(post.repostedBy.get())
  isInitialAuthor or isRepostAuthor

proc postSelector*(agent: Agent, posts: seq[Message]): seq[Message] =
  posts.filterIt(agent.neighbors.isRelatedToNeighbors(it))