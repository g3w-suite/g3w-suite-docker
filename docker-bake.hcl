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

target "oracle" {
  target   = "suite"
  tags     = ["g3wsuite/g3w-suite-qgis-oracle:${TAG}"]
  args = {
    G3W_SUITE_BRANCH = "dev"
    INSTALL_ORACLE   = "true"
    INSTALL_MSSQL    = "false"
    QGIS_CHANNEL     = "ubuntu-ltr"
    QGIS_TAG         = "final-4_2_1"
  }
}

target "ci" {
  target   = "deps"
  matrix = {
    variant = [
      { name = "deps",           suffix = "deps",           channel = "ubuntu",     mssql = "false" },
      { name = "deps-ltr",       suffix = "deps-ltr",       channel = "ubuntu-ltr", mssql = "false" },
      { name = "deps-ltr-mssql", suffix = "deps-ltr-mssql", channel = "ubuntu-ltr", mssql = "true"  },
      { name = "deps-mssql",     suffix = "deps",           channel = "ubuntu",     mssql = "true"  }
    ]
  }
  name = "ci-${variant.name}"
  tags = ["g3wsuite/g3w-suite-${variant.suffix}:${TAG}"]
  args = {
    G3W_SUITE_BRANCH = "dev"
    INSTALL_ORACLE   = "false"
    INSTALL_MSSQL    = variant.mssql
    QGIS_CHANNEL     = variant.channel
  }
}