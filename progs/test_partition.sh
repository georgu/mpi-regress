#!/bin/bash
#
# tests partitioning of a basin with npmax
#
#-------------------------------------------------

npmax=$1
basin=$2

if [ $# -ne 2 ]; then
  echo "Usage: test_partition.sh npmax basin"
  exit 1
fi
if [ ! -f $basin ]; then
  basin="$basin.bas"
fi
if [ ! -f $basin ]; then
  echo "no such file: $basin"
  exit 3
fi

echo "using npmax=$npmax and basin=$basin"

neqs=$( seq 2 $npmax )
#echo $neqs

error=0
[ -f overall.log ] && rm -f overall.log

basedir=.
if [ -z "$LOG" ]; then
  LOG=$basedir/partition.log
fi

#-------------------------------------------------

for np in $neqs
do
  #echo $np
  shyparts -np $np $basin > log.log
  #shyparts -np $np $basin
  last=$( tail -1 log.log )
  echo $last | grep successfully > /dev/null
  status=$?
  #echo "$np: basin=$basin status=$status $last"
  echo "$np: $basin $last"
  if [ $status -ne 0 ]; then
    echo "$np: $basin $last" > overall.log
    error=$(( error + 1 ))
  fi
done

if [ $error -ne 0 ]; then
  echo "*** there were errors in partitioning: $error"
  cat overall.log
  cat overall.log >> $LOG
  exit 1
else
  echo "no errors in partitioning"
  exit 0
fi

#-------------------------------------------------

