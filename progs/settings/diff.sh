#!/bin/sh
#
# diffs in settings
#
#--------------------------------------

basedir=../..
basedir=../../..

dirs=$( ls )

for dir in $dirs
do
  [ ! -d $dir ] && continue
  echo "$dir"
  cd $dir
  files=$( ls )
  for file in $files
  do
    file2=$basedir/$dir/$file
    [ ! -f $file2 ] && echo "  *** no such file $file2" && continue
    echo "  $file"
    diff $file $file2
  done
  cd ..
done

