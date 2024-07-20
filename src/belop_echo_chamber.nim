import initializer
import types
import interactions/opinionDynamics
import interactions/brg
import interactions/registerPosts
import interactions/chooseTargets
import interactions/recommendation
import interactions/relaxDissonance
import interactions/utils
import sets
import randomUtils
import logger
import options
import argumentParser

let parsedOptions = parseArguments()
initRand(parsedOptions.seed)
initLogger(parsedOptions.dir)
initializeThresholds(parsedOptions.epsilon, parsedOptions.delta)
var simulator = initilizeSimulator(parsedOptions)

simulator.log(0)
for time in 1..parsedOptions.tick:
  # Interactions
  let targets = chooseTargets(parsedOptions.n).get().toHashSet()
  simulator = simulator.opinionDynamics(targets, time)
  simulator = simulator.beliefRevisionGames(targets, time)
#  simulator = simulator.opinionFormation(targets, time)
  simulator = simulator.beliefAlignment(targets, time)
  simulator = simulator.updateNeighbors(targets, time)
  simulator = simulator.registerPosts(time, targets)
  simulator.log(time)