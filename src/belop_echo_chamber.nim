import initializer
import types
import interactions/opinionDynamics
import interactions/brg
import interactions/registerPosts
import interactions/chooseTargets
import interactions/recommendation
import sequtils
import intbrg
import strformat
import sets
import randomUtils
import logger
import options

proc `$`(p: Message): string = fmt"Message({p.author},{p.opinion},{p.belief})"

initRand(42)
initLogger("test")
const agents = 100
var simulator = initilizeSimulator(agents, 4, 400)
for agent in simulator.agents:
  echo agent.neighbors
simulator.log(0)
for time in 1..5000:
  # Interactions
  let targets = chooseTargets(agents).get().toHashSet()
  simulator = simulator.opinionDynamics(targets, time)
#  simulator = simulator.beliefRevisionGames(targets, time)
  simulator = simulator.updateNeighbors(targets, time)
  simulator = simulator.registerPosts(time, targets)
  simulator.log(time)