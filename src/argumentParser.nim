import parseopt
import types
import strutils
import sequtils
import algorithm

proc parseValue(path: string): seq[float] =
  var f = open(path)
  defer:
    f.close()
  f.readAll().split("\n").map(parseFloat)

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
    mu: 0.5,
    alpha: 0.5,
    unfollowProb: 0.5,
    repostProb: 0.5,
    values: (0..7).toSeq.reversed.mapIt(it.toFloat / 7.0),
    epsilon: 0.5,
    delta: 4,
    atomicProps: 3,
    screenSize: 10,
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
      of "update", "us":
        options.update = parseEnum[UpdatingStrategy](p.val)
      of "rewriting", "rs":
        options.rewriting = parseEnum[RewritingStrategy](p.val)
      of "verbose":
        options.verbose = true
      of "mu":
        options.mu = p.val.parseFloat
      of "alpha":
        options.alpha = p.val.parseFloat
      of "unfollowProb", "up":
        options.unfollowProb = p.val.parseFloat
      of "repostProb", "rp":
        options.repostProb = p.val.parseFloat
      of "values", "v":
        options.values = p.val.parseValue
      of "epsilon":
        options.epsilon = p.val.parseFloat
      of "delta":
        options.delta = p.val.parseInt
      of "screenSize", "l":
        options.screenSize = p.val.parseInt
      else:
        discard
    of cmdArgument:
      discard
  
  options