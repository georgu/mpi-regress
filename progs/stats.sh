#!/bin/sh
#
# gets stats of grd files
#
#----------------------------------------------------

dirs=$( ls )

for dir in $dirs
do
  if [ -d $dir ]; then
    #echo "$dir"
    cd $dir
    grds=$( ls *.grd 2> /dev/null )
    for grd in $grds
    do
      size=$( shybas $grd | grep 'grd file has been read:' | sed -e 's/.*://' )
      echo "$size   $dir  $grd"
    done
    cd ..
  fi
done

#----------------------------------------------------

