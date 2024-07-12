import ../types
import sequtils
import tables
import sets

proc getNeighborList*(simulator: Simulator, id: int): seq[int] =
  if simulator.graph.hasKey(id):
    return simulator.graph[id].items.toSeq
  else:
    return @[]