#!/bin/bash

# Wrapper for script used to load and sync BETYdb servers
# Documentation: https://github.com/PecanProject/pecan/wiki/Database-Synchronization

wget https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/load.bety.sh -o load.bety.sh
chmod +x load.bety.sh
./load.bety.sh $*
