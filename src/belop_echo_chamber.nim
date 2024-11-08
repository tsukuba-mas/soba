import initializer
import types
import interactions/chooseTargets
import interactions/recommendation
import interactions/interactions
import interactions/messageReceiver
import randomUtils
import logger
import argumentParser

let parsedOptions = parseArguments()
initRand(parsedOptions.seed)
initLogger(parsedOptions.dir, parsedOptions.verbose)
var simulator = initilizeSimulator(parsedOptions)
parsedOptions.saveAsToml(simulator.topic)

simulator = simulator.performPrehoc(parsedOptions.prehoc)
simulator.log(0)
for time in 1..parsedOptions.tick:
  # Interactions
  let targets = chooseTargets(simulator.agents)
  let evaluatedMessages = simulator.receiveMessages(targets)
  simulator = simulator.performInteractions(evaluatedMessages, time)
  simulator = simulator.updateNeighbors(evaluatedMessages, time)
  simulator.log(time)