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
# setPrec(parsedOptions.prec)
var simulator = initilizeSimulator(parsedOptions)

simulator.performPrehoc(parsedOptions.prehoc, parsedOptions.maximalOpinionChange)
simulator.log(0)
for time in 1..parsedOptions.tick:
  # Interactions
  let targets = chooseTargets(simulator.agents)
  let evaluatedMessages = simulator.receiveMessages(targets)
  simulator.performInteractions(evaluatedMessages, time, parsedOptions.maximalOpinionChange)

  let msgAfterCognitiveStateUpdates = if parsedOptions.reevaluateBeforeRewiring:
    simulator.receiveMessages(targets)
  else:
    # For backward compatible
    evaluatedMessages
  simulator.updateNeighbors(msgAfterCognitiveStateUpdates, time)
  simulator.log(time)

flushToFiles()