import utils
import sequtils
import sets
import algorithm
import options

proc chooseTargets*(agents: int): Option[seq[int]] = 
  # use takeN intentionally
  (0..<agents).toSeq.takeN(1)