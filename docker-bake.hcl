## HOW TO RUN: ##
#
# https://docs.docker.com/build/bake/
#

variable "TAG" {
  default = "dev"
}

group "default" {
  targets = ["suite"]
}

target "suite" {
  target   = "suite"
  tags     = ["g3wsuite/g3w-suite:${TAG}"]
  args = {
    G3W_SUITE_BRANCH = "dev"
    INSTALL_MSSQL    = "false"
    INSTALL_ORACLE   = "false"
    QGIS_CHANNEL     = "ubuntu-ltr"
  }
}

target "deps" {
  target   = "deps"
  matrix = {
    variant = [
      { name = "deps",            channel = "ubuntu",     mssql = "false", oracle="false" },
      { name = "deps-ltr",        channel = "ubuntu-ltr", mssql = "false", oracle="false" },
      { name = "deps-ltr-mssql",  channel = "ubuntu-ltr", mssql = "true",  oracle="false" },
      { name = "deps-mssql",      channel = "ubuntu",     mssql = "true",  oracle="false" },
      { name = "deps-ltr-oracle", channel = "ubuntu-ltr", mssql = "false", oracle="true"  },
    ]
  }
  name = "${variant.name}"
  tags = ["g3wsuite/g3w-suite-${variant.name}:${TAG}"]
  args = {
    G3W_SUITE_BRANCH = "dev"
    INSTALL_ORACLE   = variant.oracle
    INSTALL_MSSQL    = variant.mssql
    QGIS_CHANNEL     = variant.channel
  }
  cache-from = ["type=gha,scope=${variant.name}"]
  cache-to   = ["type=gha,mode=max,scope=${variant.name}"]
}