import parseopt
import types
import strutils

proc parseArguments*(): CommandLineArgs =
  var p = initOptParser()
  var options = CommandLineArgs(
    seed: 42,
    dir: "test",
    n: 100,
    follow: 400,
    tick: 100,
    filter: FilterStrategy.all,
    update: UpdatingStrategy.independent,
    rewriting: RewritingStrategy.random,
    verbose: false,
  )

  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case p.key
      of "seed", "s":
        options.seed = p.val.parseInt
      of "dir", "d":
        options.dir = p.val
      of "n", "agents":
        options.n = p.val.parseInt
      of "follow", "f":
        options.follow = p.val.parseInt
      of "tick", "t":
        options.tick = p.val.parseInt
      of "filter", "fs":
        options.filter = parseEnum[FilterStrategy](p.val)
      of "update", "u":
        options.update = parseEnum[UpdatingStrategy](p.val)
      of "rewriting", "r":
        options.rewriting = parseEnum[RewritingStrategy](p.val)
      of "verbose", "v":
        options.verbose = true
      else:
        discard
    of cmdArgument:
      discard
  
  options