#!/bin/sh
#
#------------------------------------------------------------

server=storm

echo "getting log files from $server"

server.sh -s $server -command \
"cd ~/georg/work/mpi/regress; zip logs *.log; cp logs.zip ~/georg/trans"

server.sh -s $server -f logs.zip

unzip -o logs.zip

#------------------------------------------------------------

