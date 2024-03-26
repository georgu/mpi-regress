#!/bin/bash
#
# run mpi regression tests
#
#----------------------------------------------------

regdirs="medimms medi2d vistula venlast marmenor cucco goro"
stop_on_error="YES"
stop_on_error="NO"
errors=0
npmax=64
npmax=4
#npmax=8
#npmax=12

basedir=$( pwd )

progsdir=$basedir/progs
mkdir -p $progsdir/settings

export LOG=$basedir/regression.log

bindir=$HOME/work/shyfem_repo/shyfemcm/bin

. $bindir/colors.sh

#----------------------------------------------------

RegressRun()
{
  what=$1

  [ ! -d $what ] && echo "no such directory $what" && exit 1
  cd $what

  echo "-------------------------------------------------" | tee -a $LOG
  echo "running regression test $what" | tee -a $LOG

  make $target
  if [ $? -ne 0 ]; then
    errors=$(( errors + 1 ))
    echo "*** error running simulation $what" | tee -a $LOG
    if [ $stop_on_error = "YES" ]; then
      cat $LOG
      exit 1
    else
      echo "-------------------------------------------------" | tee -a $LOG
      cd $basedir
      return
    fi
  fi

  sync; sync; sync
  sleep 1

  echo "comparing regression test $what" | tee -a $LOG

  make compare > compare.log
  if [ $? -ne 0 ]; then
    errors=$(( errors + 1 ))
    cat compare.log
    echo "${red}*** errors comparing simulation $what${normal}" | tee -a $LOG
    if [ $stop_on_error = "YES" ]; then
      cat $LOG
      exit 1
    else
      echo "-------------------------------------------------" | tee -a $LOG
      cd $basedir
      return
    fi
  fi

  echo "${green}successful regression test $what${normal}" | tee -a $LOG
  echo "-------------------------------------------------" | tee -a $LOG
  cd $basedir
}

RegressCollect()
{
  cd $1
  newdir=$progsdir/settings/$1
  mkdir -p $newdir
  echo "settings.sh -> $newdir"
  cp -f settings.sh $newdir
  echo "*.str -> $newdir"
  cp -f *.str $newdir
  cd $basedir
}

RegressDistribute()
{
  cd $1
  newdir=$progsdir/settings/$1
  mkdir -p $newdir
  new=$newdir/settings.sh
  echo "$new -> settings.sh"
  cp -f $new .
  new="$newdir/*.str"
  echo "$new -> settings.sh"
  cp -f $new .
  cd $basedir
}

RegressPartition()
{
  cd $1
  basins=$( grep basins settings.sh )
  basin=$( echo $basins | sed -e 's/.*=//' | sed -e 's/"//g' )
  #echo $basin
  script=$progsdir/test_partition.sh
  $script $npmax $basin
  [ $? -ne 0 ] && errors=$(( errors + 1 ))
  cd $basedir
}

RegressClean()
{
  cd $1
  make cleantotal
  cd $basedir
}

RegressLink()
{
  cd $1
  rm -f Makefile run_test.sh
  ln -sf $progsdir/Makefile
  ln -sf $progsdir/run_test.sh
  cd $basedir
}

RegressInfo()
{
  cd $1
  make info
  cd $basedir
}

#----------------------------------------------------

Usage()
{
  #echo "Usage: ./run-regress.sh target"
  echo "Usage: ./run-regress.sh [short|long|clean|link]"
}

#----------------------------------------------------

if [ $# -eq 0 ]; then
  Usage
  exit 0
fi

tstart=$(date)
tsstart=$(date +%s)

target=$1
if [ "$1" = "short" ]; then
  target=regress_short
elif [ "$1" = "long" ]; then
  target=regress_long
  regdirs="vistula-restart $regdirs"
elif [ "$1" = "restart" ]; then
  target=regress_restart
  regdirs="vistula-restart"
elif [ "$1" = "clean" ]; then
  target=clean
  regdirs="vistula-restart $regdirs"
elif [ "$1" = "link" ]; then
  target=link
elif [ "$1" = "collect" ]; then
  target=collect
elif [ "$1" = "distribute" ]; then
  target=distribute
elif [ "$1" = "partition" ]; then
  target=partition
elif [ "$1" = "info" ]; then
  target=info
else
  echo "no such target: $1"
  exit 1
fi
  
date=$( date )
echo "running regression tests: $date" | tee $LOG
echo "using target $target" | tee -a $LOG
echo "using regdirs $regdirs" | tee -a $LOG

for regdir in $regdirs
do
  echo '------------------------------'
  echo $regdir
  echo '------------------------------'
  if [ $target = "clean" ]; then
    make clean
    RegressClean $regdir
  elif [ $target = "link" ]; then
    RegressLink $regdir
  elif [ $target = "collect" ]; then
    RegressCollect $regdir
  elif [ $target = "distribute" ]; then
    RegressDistribute $regdir
  elif [ $target = "info" ]; then
    RegressInfo $regdir
  elif [ $target = "partition" ]; then
    RegressPartition $regdir
  else
    RegressRun $regdir
  fi
done

echo "==============================================="
if [ $errors -eq 0 ]; then
  echo "${green}all regression tests were successful...${normal}" \
			| tee -a $LOG
else
  echo "${red}errors found in $errors regression tests...${normal}" \
			| tee -a $LOG
fi

echo "==============================================="
echo "Summary of log information:" 
cat $LOG
echo "==============================================="

tend=$(date)
tsend=$(date +%s)
ttot=$(( tsend - tsstart ))
echo "start time: $tstart"
echo "end time: $tend"
echo "running time: $ttot"

#----------------------------------------------------

