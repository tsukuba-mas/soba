import utils
import sequtils
import sets
import algorithm

proc chooseTargets*(agents: int): seq[int] = 
  (0..<agents).toSeq.takeN(1)