#!/bin/sh
#
#------------------------------------------------------------

server=storm
[ $# -eq 1 ] && server=$1

regressdir=~/georg/work/mpi/regress
transdir=~/georg/trans

#------------------------------------------------------------

echo "getting log files from $server"

server.sh -s $server -command \
"cd $regressdir; zip logs *.log; cp logs.zip $transdir"

server.sh -s $server -f logs.zip

unzip -o logs.zip

#------------------------------------------------------------

