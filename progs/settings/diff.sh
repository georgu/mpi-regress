#!/bin/bash
#
# diffs in settings
#
#--------------------------------------

basedir=../..
settdir=$( pwd )
verbose="YES"
verbose="NO"
diff=0
error=0
exitcode=0

#--------------------------------------

CheckExist()
{
  local file=$1
  if [ ! -f $file ]; then
    echo "  *** no such file: $file"
    (( error++ ))
    return 1
  fi
}

CheckDiff()
{
  local file1=$1
  local file2=$2
  diff $file $file2 > log.log
  status=$?
  [ $verbose = "YES" ] && echo "  $file"
  if [ $status -ne 0 ]; then
    echo "  *** difference in dir $dir between $file $file2"
    (( diff++ ))
    cat log.log
  fi
}

#--------------------------------------

dirs=$( ls )

[ $verbose = "YES" ] && echo "checking in $settdir"

for dir in $dirs
do
  [ ! -d $dir ] && continue
  [ $verbose = "YES" ] && echo "$dir"
  cd $dir
  files=$( ls )
  for file in $files
  do
    [ $file = "log.log" ] && continue
    file2=$basedir/../$dir/$file
    CheckExist $file2
    [ $? -ne 0 ] && continue
    CheckDiff $file $file2
  done
  rm -f log.log
  cd ..
done

cd $basedir

[ $verbose = "YES" ] && echo "checking in $basedir ($PWD)"

for dir in $dirs
do
  [ ! -d $dir ] && continue
  [ $verbose = "YES" ] && echo "$dir in $PWD"
  cd $dir
  files=$( ls *.str )
  for file in $files
  do
    [ $file = "log.log" ] && continue
    file2=$settdir/$dir/$file
    CheckExist $file2
    [ $? -ne 0 ] && continue
    #CheckDiff $file $file2
  done
  rm -f log.log
  cd ..
done

rm -f log.log

#--------------------------------------

if [ $error -ne 0 -o $diff -ne 0 ]; then
  echo "*** errors = $error   differences = $diff"
  (( exitcode = error + diff ))
else
  echo "no differences found..."
fi

exit $exitcode

#--------------------------------------

