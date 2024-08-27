import initializer
import types
import interactions/opinionDynamics
import interactions/brg
import interactions/registerPosts
import interactions/chooseTargets
import interactions/recommendation
import interactions/relaxDissonance
import interactions/utils
import randomUtils
import logger
import argumentParser
import sequtils

let parsedOptions = parseArguments()
initRand(parsedOptions.seed)
initLogger(parsedOptions.dir, parsedOptions.verbose)
var simulator = initilizeSimulator(parsedOptions)
parsedOptions.saveAsToml(simulator.topic)

simulator.log(0)
for time in 1..parsedOptions.tick:
  # Interactions
  let targets = chooseTargets(simulator.agents)
  let evaluatedPosts = targets.mapIt(simulator.agents[int(it)]).readTimeline(simulator.posts, simulator.screenSize)
  simulator = simulator.opinionDynamics(evaluatedPosts, time)
  simulator = simulator.beliefRevisionGames(evaluatedPosts, time)
  simulator = simulator.relaxDissonance(evaluatedPosts, time)
  simulator = simulator.updateNeighbors(evaluatedPosts, time)
  simulator = simulator.registerPosts(evaluatedPosts, time)
  simulator.log(time)