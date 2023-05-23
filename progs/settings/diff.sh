#!/bin/bash
#
# diffs in settings
#
#--------------------------------------

basedir=../../..
verbose="YES"
verbose="NO"
diff=0
error=0
exitcode=0

dirs=$( ls )

for dir in $dirs
do
  [ ! -d $dir ] && continue
  [ $verbose = "YES" ] && echo "$dir"
  cd $dir
  files=$( ls )
  for file in $files
  do
    [ $file = "log.log" ] && continue
    file2=$basedir/$dir/$file
    if [ ! -f $file2 ]; then
      echo "  *** no such file $file2"
      (( error++ ))
      continue
    fi
    diff $file $file2 > log.log
    status=$?
    [ $verbose = "YES" ] && echo "  $file"
    if [ $status -ne 0 ]; then
      echo "  *** difference in dir $dir between $file $file2"
      (( diff++ ))
      cat log.log
    fi
  done
  cd ..
done

rm -f log.log

if [ $error -ne 0 -o $diff -ne 0 ]; then
  echo "*** errors = $error   differences = $diff"
  (( exitcode = error + diff ))
else
  echo "no differences found..."
fi

exit $exitcode

#--------------------------------------

