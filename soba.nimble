# Package

version       = "0.1.0"
author        = "Hiro KATAOKA"
description   = "Simulator for Opinions-Beliefs interactions between Agents"
license       = "MIT"
srcDir        = "src"
bin           = @["soba"]


# Dependencies

requires "nim >= 2.0.0"
requires "https://github.com/Azumabashi/intbrg >= 0.2.1"
requires "https://bitbucket.org/maxgrenderjones/therapist/src/master/@#cf1b4b2"
requires "https://github.com/Azumabashi/nimice#ae70640c2c5456feae9a05ca4d0e383bab6e1d30"