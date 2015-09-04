#!/bin/bash

# Wrapper for script used to load and sync BETYdb servers
# Documentation: https://github.com/PecanProject/pecan/wiki/Database-Synchronization

if [ ! -e load.bety.sh ];
  wget https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/load.bety.sh -o load.bety.sh
  chmod +x load.bety.sh
fi
./load.bety.sh $*
