import utils
import sequtils
import sets
import algorithm
import options
import ../types

proc chooseTargets*(agents: int): Option[seq[Id]] = 
  # use takeN intentionally
  (0..<agents).toSeq.map(toId).takeN(1)