# Package

version       = "0.1.0"
author        = "Hiro KATAOKA"
description   = "Echo chamber simulator through opinion-belief interactions"
license       = "MIT"
srcDir        = "src"
bin           = @["belop_echo_chamber"]


# Dependencies

requires "nim >= 2.0.0"
requires "https://github.com/Azumabashi/intbrg >= 0.2.1"
requires "https://github.com/iffy/nim-argparse >= 4.0.1"
requires "parsetoml >= 0.7.1"