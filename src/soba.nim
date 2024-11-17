import initializer
import types
import interactions/chooseTargets
import interactions/recommendation
import interactions/interactions
import interactions/messageReceiver
import logger
import argumentParser

let parsedOptions = parseArguments()
initLogger(parsedOptions.dir, parsedOptions.verbose, parsedOptions.topics.len)
setPrec(parsedOptions.prec)
var simulator = initilizeSimulator(parsedOptions)

simulator = simulator.performPrehoc(parsedOptions.prehoc)
simulator.log(0)
for time in 1..parsedOptions.tick:
  # Interactions
  let targets = chooseTargets(simulator.agents)
  let evaluatedMessages = simulator.receiveMessages(targets)
  simulator = simulator.performInteractions(evaluatedMessages, time)
  simulator = simulator.updateNeighbors(evaluatedMessages, time)
  simulator.log(time)