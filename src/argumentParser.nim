import argparse
import types
import strutils
import sequtils
import algorithm
import parsetoml
import options

proc optionsFromToml(tomlPath: string): CommandLineArgs =
  let toml = parseFile(tomlPath)
  CommandLineArgs(
    seed: toml["seed"].getInt(),
    dir: toml["dir"].getStr(),
    n: toml["agents"].getInt(),
    follow: toml["follow"].getInt(),
    tick: toml["tick"].getInt(),
    filter: parseEnum[FilterStrategy](toml["filter"].getStr()),
    update: parseEnum[UpdatingStrategy](toml["updating"].getStr()),
    rewriting: parseEnum[RewritingStrategy](toml["rewriting"].getStr()),
    verbose: toml["verbose"].getBool(),
    mu: toml["mu"].getFloat(),
    alpha: toml["alpha"].getFloat(),
    unfollowProb: toml["unfollow"].getFloat(),
    repostProb: toml["repost"].getFloat(),
    values: toml["values"].getElems().mapIt(it.getFloat()),
    epsilon: toml["epsilon"].getFloat(),
    delta: toml["delta"].getInt(),
    atomicProps: 3,
    screenSize: toml["screen"].getInt(),
  )

proc parseValue(path: string): seq[float] =
  var f = open(path)
  defer:
    f.close()
  f.readAll().split("\n").map(parseFloat)

proc parseArguments*(): CommandLineArgs =
  var p = newParser:
    help("echo chamber simulator based on opinion dynamics and belief revision")
    option("-s", "--seed", help="seed", default=some("42"))
    option("-d", "--dir", help="directory to save files", default=some("out"))
    option("-a", "--agents", help="the number of agents", default=some("100"))
    option("-f", "--follow", help="the number of follows (i.e., edges)", default=some("400"))
    option("-t", "--tick", help="the number of iterations", default=some("100"))
    option("--fs", "--filter", help="filter strategy", default=some("all"))
    option("--us", "--updating", help="updating strategy", default=some("independent"))
    option("--rs", "--rewriting", help="rewriting strategy", default=some("none"))
    option("--mu", help="parameter in opinion dynamics", default=some("0.5"))
    option("--alpha", help="parameter in opinion formation", default=some("0.5"))
    option("--up", "--unfollow", help="probability of unfollowing agents", default=some("0.5"))
    option("--rp", "--repost", help="probability of reposting", default=some("0.5"))
    option("-v", "--values", help="path to cultural values")
    option("--epsilon", help="threshold for opinions", default=some("0.01"))
    option("--delta", help="threshold for beliefs", default=some("4"))
    option("-l", "--screen", help="set screen size", default=some("10"))
    flag("--verbose", help="verbose mode")
    option("--toml", help="input TOML format file", default=none(string))
  
  try:
    let parsed = p.parse()
    if parsed.toml.len > 0:
      # if --toml is given
      return optionsFromToml(parsed.toml)
    else:
      return CommandLineArgs(
        seed: parsed.seed.parseInt,
        dir: parsed.dir,
        n: parsed.agents.parseInt,
        follow: parsed.follow.parseInt,
        tick: parsed.tick.parseInt,
        filter: parseEnum[FilterStrategy](parsed.filter),
        update: parseEnum[UpdatingStrategy](parsed.updating),
        rewriting: parseEnum[RewritingStrategy](parsed.rewriting),
        verbose: parsed.verbose,
        mu: parsed.mu.parseFloat,
        alpha: parsed.alpha.parseFloat,
        unfollowProb: parsed.unfollow.parseFloat,
        repostProb: parsed.repost.parseFloat,
        values: 
          if parsed.values.len == 0: (0..7).toSeq.reversed.mapIt(it.toFloat / 7.0) 
          else: parsed.values.parseValue,
        epsilon: parsed.epsilon.parseFloat,
        delta: parsed.delta.parseInt,
        atomicProps: 3,
        screenSize: parsed.screen.parseInt,
      )
  except ShortCircuit as err:
    # show help message
    echo err.help
    echo "fs: ", (FilterStrategy.low..FilterStrategy.high).toSeq.join(", ")
    echo "us: ", (UpdatingStrategy.low..UpdatingStrategy.high).toSeq.join(", ")
    echo "rs: ", (RewritingStrategy.low..RewritingStrategy.high).toSeq.join(", ")
    echo "NB: use EITHER --toml OR other parameters. If --toml is used, other parameters will be ignored."
    quit(0)