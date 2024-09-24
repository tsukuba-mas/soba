import initializer
import types
import interactions/registerPosts
import interactions/chooseTargets
import interactions/recommendation
import interactions/utils
import interactions/interactions
import interactions/relaxDissonance
import interactions/messageReceiver
import randomUtils
import logger
import argumentParser
import sequtils
import copyUtils

let parsedOptions = parseArguments()
initRand(parsedOptions.seed)
initLogger(parsedOptions.dir, parsedOptions.verbose)
var simulator = initilizeSimulator(parsedOptions)
parsedOptions.saveAsToml(simulator.topic)

# Make agents' opinions and belief coherent
let conv = 1e-5
var canBreak = false
while not canBreak:
  var aligned = simulator.agents.mapIt(
    it.opinionFormation(simulator.topic, -1).beliefAlignment(simulator.topic, -1)
  )
  canBreak = (0..<aligned.len).toSeq.allIt(
    simulator.agents[it].belief == aligned[it].belief and
    abs(simulator.agents[it].opinion - aligned[it].opinion) <= conv
  )
  simulator = simulator.updateAgents(aligned)


simulator.log(0)
for time in 1..parsedOptions.tick:
  # Interactions
  let targets = chooseTargets(simulator.agents)
  let messages = simulator.receiveMessages(targets)
  let evaluatedPosts = targets.mapIt(simulator.agents[int(it)]).readTimeline(simulator.posts, simulator.screenSize)
  simulator = simulator.performInteractions(evaluatedPosts, time)
  simulator = simulator.updateNeighbors(evaluatedPosts, time)
  simulator = simulator.registerPosts(evaluatedPosts, time)
  simulator.log(time)