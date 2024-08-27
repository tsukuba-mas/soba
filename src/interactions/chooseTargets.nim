import sequtils
import options
import ../types

proc chooseTargets*(agents: int): Option[seq[Id]] = 
  (0..<agents).toSeq.map(toId).some()