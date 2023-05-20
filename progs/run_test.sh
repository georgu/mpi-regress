#!/bin/bash
#
# runs and compares shyfem in serial and mpi mode
#
#----------------------------------------------

what=unknown

#----------------------------------------------

version='2.4 - 22.03.2023'

nprocs="1 4"
nprocs="0 1 4"
nprocs="0 1 4 8 16"
nprocs="19 20 21 22"
nprocs="11 12 13 14 15"
nprocs="0 1 2 3 4 5 6 7 8"
nprocs="0 1 10 11 12 13 14"
nprocs="0 1 2 3 4 8 10 11 12 13 14"
nptype="npmax2"
nptype="custom"
nptype="npmax"
#npmin=10
#npmin=11
#npmax=20
npmax=16
npmax=11
npmax=4

hostname=$( hostname )
repodir="$HOME/georg/work/shyfem_repo"

[ ! -d $repodir ] && echo "no such dir: $repodir" && exit 1

shydir_mpi="$repodir/shyfem-mpi"
shydir_serial="$repodir/shyfem"

actdir=$( pwd )
mpi_command="mpirun"
mpi_command="mpirun --oversubscribe"
check_debug=$shydir_mpi/fem3d/check_shympi_debug

stop_on_run_error="YES"
stop_on_run_error="NO"
stop_on_compare_error="YES"
stop_on_compare_error="NO"
double_compare="NO"

basedir=$( pwd )
if [ -z "$LOG" ]; then
  LOG=$basedir/regression.log
fi
LLOG=$basedir/regression_local.log
[ -f $LLOG ] && rm -f $LLOG

#----------------------------------------------

SetApplication()
{

 if [ -f settings.sh ]; then
   . ./settings.sh
   echo "settings for $what has been read"
 fi

 if [ -z "$basins" ]; then
  echo "application not recognized: $what"
  exit 1
 else
  echo "running application $what"
 fi
}

#----------------------------------------------

Usage()
{
  echo "Usage: run_test.sh [-h|-help] [-options] [str-file]"
}

FullUsage()
{
  echo ""

  Usage

  echo ""
  echo "Available options:"
  echo "  -h|-help             this help"
  echo "  -quiet               be quiet"
  echo "  -nodiff              do not show differences"
  echo "  -nostop              do not stop at first difference"
  echo "  -summary             only write summary for time record"
  echo "  -verbose             be verbose"
  echo "  -application what    set application to what"
  echo "  -regress             runs regression test"
  echo "  -run                 run simulations"
  echo "  -compare             compare simulations"
  echo "  -compile             compile the models"
  echo "  -info                get info on settings"
  echo "  -clean               cleans simulation directories"
  echo "  -short               make short simulations (default)"
  echo "  -long                make long simulations"
  echo "  -debug               write debug information"
  echo "  -chkonlydbg          check only debug file information"
  echo "  -maxdiff eps         error only if difference is above eps"
}

HandleOptions()
{
  quiet="NO"
  nodiff="NO"
  nostop="NO"
  summary="NO"
  verbose="NO"
  regress="NO"
  run="NO"
  compare="NO"
  compile="NO"
  info="NO"
  clean="NO"
  short="UNKNOWN"
  debug="NO"
  chkonlydbg="NO"
  maxdiff="NO"

  while [ -n "$1" ]
  do
    case $1 in
        -h|-help)       FullUsage; exit 0;;
        -quiet)         quiet="YES";;
        -nodiff)        nodiff="YES";;
        -nostop)        nostop="YES";;
        -summary)       summary="YES";;
        -verbose)       verbose="YES";;
        -application)   what=$2; shift;;
        -regress)       regress="YES";;
        -run)           run="YES";;
        -compare)       compare="YES";;
        -compile)       compile="YES";;
        -info)          info="YES";;
        -clean)         clean="YES";;
        -short)         short="YES";;
        -long)          short="NO";;
        -debug)         debug="YES";;
        -chkonlydbg)    chkonlydbg="YES";;
        -maxdiff)       maxdiff="YES"; epsdiff=$2; shift;;
        -*)             echo "No such option: $1"; exit 1;;
        *)              break;;
    esac
    shift
  done

  if [ $verbose = "YES" ]; then
    quiet="NO"
  fi

  if [ $short = "UNKNOWN" ]; then
    if [ $debug = "YES" ]; then
      short="YES"
    else
      short="NO"
    fi
  fi

  str=$1
  if [ -z "$str" -a $run = "YES" ]; then
    echo "option -run needs str-file"
    Usage
    exit 1
  fi
}

#----------------------------------------------

SetProcs()
{
  local dir

  cpus=$( lscpu | grep '^\s*CPU(s):' | sed -E 's/.*:\s*//' )
  #cpus=$( lscpu | grep '^\s*CPU(s):' )
  #cpus=$( lscpu | grep '^\s*CPU(s):' )

  if [ $nptype = "custom" ]; then
    :	#leave standard
  elif [ -n "$npmin" -o -n "$npmax" ]; then
    [ -z "$npmin" ] && npmin=2
    [ $npmin -lt 2 ] && npmin=2
    [ -z "$npmax" ] && npmax=$cpus
    [ $npmax -gt $cpus ] && npmax=$cpus
    nlist=$( seq $npmin $npmax )
    nprocs="0 1 $nlist"
  elif [ $nptype = "npmax" ]; then
    nprocs=$( seq 0 $cpus )
  elif [ $nptype = "npmax2" ]; then
    nprocs="0 1"
    np=1
    while :
    do
      np=$(( np * 2 ))
      [ $np -gt $cpus ] && break
      nprocs="$nprocs $np"
    done
  else
    echo "value not recognized: nptype = $nptype"
    exit 1
  fi

  nprocs=$( echo $nprocs | tr '\n' ' ' )	#get rid of newlines

  echo "cpus: $cpus"
  echo "nprocs: $nprocs"
  #exit 0
}

Info()
{
  local dir

  echo "what: $what"
  echo "cpus: $cpus"
  echo "nprocs: $nprocs"
  echo "nodes: $nodes"
  echo "basins: $basins"
  echo "simname: $simname"
  echo "str: $str_regress"
  echo "repodir: $repodir"
  echo "shydir_mpi: $shydir_mpi"
  echo "shydir_serial: $shydir_serial"

  dir=$shydir_mpi
  if [ ! -d $dir ]; then
    echo "*** no such directory: $dir"
    exit 1
  fi
  [ -f shyfem-mpi ] && rm -f shyfem-mpi
  ln -s $dir/fem3d/shyfem shyfem-mpi

  dir=$shydir_serial
  if [ ! -d $dir ]; then
    echo "*** no such directory: $dir"
    exit 1
  fi
  [ -f shyfem-serial ] && rm -f shyfem-serial
  ln -s $dir/fem3d/shyfem shyfem-serial
}

PrepareBasins()
{
  export SHYFEMDIR=$shydir_mpi
  for basin in $basins
  do
    [ -f $basin.bas ] && continue
    #mpi_basin.sh $np $basin.grd
    echo "preparing basin $basin"
    shypre -noopti -silent $basin.grd
    [ $? -ne 0 ] && echo "error creating basin $basin" && exit 1
  done
  export SHYFEMDIR=$shydir_serial
  echo "SHYFEMDIR=$SHYFEMDIR"
}

LinkForcing()
{
  #if [ -d ../data ]; then
  #  [ -d data ] || ln -s ../data
  #fi

  for file in $forcings
  do
    if [ -d $file ]; then
      [ -d $file ] || ln -s ../$file
    else
      [ -f $file ] || ln -s ../$file
    fi
  done
}

CopyFiles()
{
  local dir=$1
  local strdir=$strs
  [ -z "$strdir" ] && strdir="."

  cp $strdir/$str $dir
  cp *.bas $dir
  cp *.grd $dir
  [ -f gotmturb.nml ] && cp gotmturb.nml $dir
  [ -f Makefile ] && cp Makefile $dir
  [ -f settings.sh ] && cp settings.sh $dir
  [ -n "$cpfiles" ] && cp $cpfiles $dir
}

CheckSTR()
{
  local strdir=$strs
  [ -z "$strdir" ] && strdir="."

  if [ ! -f $strdir/$str ]; then
    if [ -f $strdir/$str.str ]; then
      str=$str.str
      echo "using str file: $str"
    else
      echo "no such str file: $str"
      exit 1
    fi
  fi
}

MakeShort()
{
  [ -z "$idtshort" ] && idtshort=300
  [ -z "$iteshort" ] && iteshort=900

  if [ $short = "YES" ]; then
    cp $str orig.str
    sed -E "s/itend = [0-9]+/itend = $iteshort/" $str > aux.str
    mv aux.str $str
    sed -E "s/idtdbg = [0-9]+/idtdbg = $idtshort/" $str > aux.str
    mv aux.str $str
  fi

  itend=$( grep itend $str )
  idtdbg=$( grep idtdbg $str )
  echo "    time parameters: $itend $idtdbg"
}

Compile()
{
  local dir

  dir=$shydir_mpi
  echo "========================================="
  echo "compiling in $dir"
  echo "========================================="
  cd $dir
  make fem
  make fem

  dir=$shydir_serial
  echo "========================================="
  echo "compiling in $dir"
  echo "========================================="
  cd $dir
  make fem
  make fem

  dir=$actdir
  echo "========================================="
  echo "returning to $dir"
  echo "========================================="
  cd $dir
}

#----------------------------------------------
#----------------------------------------------
#----------------------------------------------

RunSims()
{
  ndir=0
  error_run=0
  echo "================================================"
  echo "running simulation $str" of $what
  echo "================================================"
  for np in $nprocs
  do
    dir="mpisim.$np"
    [ $np -ne 0 ] && echo "---------------------------"
    echo "  running $str with $np in $dir"
    (( ndir += 1 ))
    mkdir -p $dir
    CopyFiles $dir
    cd $dir
    make clean cleansims &> logfile.txt
    LinkForcing
    MakeShort
    RunShyfem $np
    cd ..
  done

  echo "----------------------------------------"
  echo "finished running simulations"
  echo "----------------------------------------"

  echo "    $ndir simulations run - errors found: $error_run"
  if [ $error_run -ne 0 ]; then
    cat $LLOG
  fi
}

RunShyfem()
{
  local np=$1

  options=""
  [ $debug = "YES" ] && options="-debout -mpi_debug"
  #echo "options are $options"

  if [ $np -eq 0 ]; then
    command="$repodir/shyfem/bin/shyfem $options $str"
  elif [ $np -eq 1 ]; then
    command="$repodir/shyfem-mpi/bin/shyfem $options $str"
  else
    options="-mpi $options"
    command="$mpi_command -np $np $repodir/shyfem-mpi/bin/shyfem $options $str"
  fi
  echo "$command" > command.sh
  chmod +x command.sh
  adir=$( pwd )
  echo "    running as: $command"
  $command &>> logfile.txt
  status=$?
  #echo "exit code = $status"
  if [ $status -ne 99 ]; then
    cat logfile.txt
    (( error_run += 1 ))
    echo "*** error running shyfem... aborting"
    echo "*** number of processes: $np"
    echo "*** executing command: $command"
    echo "*** running in directory: $adir"
    echo "*** writing to $LOG and $LLOG"
    echo "*** error running with np = $np" >> $LOG
    echo "*** error running with np = $np" >> $LLOG
    if [ $stop_on_run_error = "YES" ]; then
      exit 1
    else
      return
    fi
  fi
  timeline=$( grep "MPI_TIME =" logfile.txt )
  timeline=$( grep "TIME TO SOLUTION (CPU)  =" logfile.txt )
  echo "   $timeline"
}

#----------------------------------------------
#----------------------------------------------
#----------------------------------------------

PrepareFiles()
{
  local ext=$1
  local dir=$2
  local file=$simname.$ext

  echo "preparing $ext $dir $file"

  cd $dir

  #make clean &>> logfile.txt
  #nf1=$( ls *.[23]d.[0-9]* 2> /dev/null | wc -l )
  #echo "  preparing file $file with extension $ext"
  if [ -f $file ]; then
    if [ $ext = "ext" ]; then
      shyelab -split $file &>> logfile.txt
    else
      shyelab -node $nodes $file &>> logfile.txt
    fi
    tail -1 logfile.txt | grep 'error stop'
    if [ $? -eq 0 ]; then
      errortext="*** errors preparing files in $dir for $file"
      files=""
      return
    else
      files=$( ls *.[23]d.[0-9]* )
    fi
  else
    #echo "  no file $file available... skipping"
    files=""
  fi

  #nf2=$( echo $files | wc -w )
  #echo "files before: $nf1"
  #echo "files after : $nf2"

  cd ..
}

CompareFiles()
{
  local ext=$1
  local dir1=$2
  local dir2=$3
  local file=$simname.$ext

  echo "    comparing $file files..."
  error=0
  nfile=0
  [ -f auxlog.txt ] && rm -f auxlog.txt
  for file in $files
  do
    #echo "comparing file $file"
    (( nfile ++ ))
    #cmp $dir1/$file $dir2/$file >> auxlog.txt
    diff $dir1/$file $dir2/$file >> auxlog.txt
    status=$?
    if [ $status -ne 0 ]; then
      status=1
      (( error += 1 ))
      echo "error comparing file $file"
    fi
  done
  [ $quiet = "NO" -a -f auxlog.txt ] && cat auxlog.txt
  [ $error -gt 0 ] && errortext="error comparing files"
  echo "    $nfile files compared - errors found: $error"
}

HandleCompareFiles()
{
  local ext=$1
  local dir1=$2
  local dir2=$3

  errortext=""

  PrepareFiles $ext $dir1
  files1=$files
  [ "$errortext" != "" ] && (( error_compare += 1 )) && return

  PrepareFiles $ext $dir2
  files2=$files
  [ "$errortext" != "" ] && (( error_compare += 1 )) && return

  if [ "$files1" != "$files2" ]; then
    echo "files1:"
    echo "$files1"
    echo "files2:"
    echo "$files2"
    echo $errortext
    [ "$errortext" != "" ] && (( error_compare += 1 )) && return
  fi

  CompareFiles $ext $dir1 $dir2
  [ -n "$errortext" ] && (( error_compare += 1 )) && return
}

HandleCompareDbg()
{
  local dir1=$1
  local dir2=$2

  error=0
  file=$simname.dbg
  if [ -f $dir1/$file ]; then
    #echo "    comparing: $check_debug $dir1/$file $dir2/$file"
    option=""
    [ $verbose = "YES" ] && option="$option -verbose"
    [ $nodiff = "YES" ] && option="$option -nodiff"
    [ $nostop = "YES" ] && option="$option -nostop"
    [ $summary = "YES" ] && option="$option -summary"
    [ $maxdiff = "YES" ] && option="$option -maxdiff $epsdiff"
    [ -n "$epsdiff" ] && option="$option -maxdiff $epsdiff"
    command="$check_debug $option $dir1/$file $dir2/$file"
    echo "    comparing as: $command"
    #$check_debug $option $dir1/$file $dir2/$file > auxlog.txt
    $command > auxlog.txt
    status=$?
    [ $quiet = "NO" ] && cat auxlog.txt
    if [ $status -eq 99 ]; then
      echo "    2 files compared - errors found: 0"
    elif [ $status -eq 0 ]; then
      echo "    2 files compared - generic error"
      error=1
    else
      echo "    2 files compared - errors found: $status"
      error=$status
    fi
  else
    echo "    0 files compared - errors found: 0"
  fi

  (( error_compare += error ))
}

CompareShyfem()
{
  dir1=$1
  dir2=$2

  echo "----------------------------------------"
  echo "comparing directories $dir1 and $dir2"
  echo "----------------------------------------"

  [ -z "$dir2" ] && echo "directories are missing..." && exit 1

  error_compare=0

  #--------------------------------------------

  if [ $chkonlydbg = "NO" ]; then

  #--------------------------------------------

  ext="ext"
  HandleCompareFiles $ext $dir1 $dir2

  #--------------------------------------------

  ext="hydro.shy"
  HandleCompareFiles $ext $dir1 $dir2

  #--------------------------------------------

  ext="conz.shy"
  HandleCompareFiles $ext $dir1 $dir2

  #--------------------------------------------

  ext="ts.shy"
  HandleCompareFiles $ext $dir1 $dir2

  #--------------------------------------------

  fi

  #--------------------------------------------

  HandleCompareDbg $dir1 $dir2

  #--------------------------------------------

  if [ $error_compare -ne 0 ]; then
    echo "    *** a total of $error_compare errors found"
    echo "*** error comparing between $oldnp - $np" >> $LOG
    echo "*** error comparing between $oldnp - $np" >> $LLOG
    (( errorall += error_compare ))
  fi
}

#----------------------------------------------

CompareSims()
{
  ndir=0
  error=0
  errorall=0
  olddir=
  oldnp=
  for np in $nprocs
  do
    (( ndir += 1 ))
    dir="mpisim.$np"
    if [ -n "$olddir" ]; then
      CompareShyfem $olddir $dir
      #[ $error -ne 0 ] && return
    fi
    olddir=$dir
    oldnp=$np
  done

  echo "----------------------------------------"
  echo "finished comparing directories"
  echo "----------------------------------------"

  echo "    $ndir directories compared - errors found: $errorall"
  if [ $errorall -ne 0 ]; then
    cat $LLOG
  fi
  #exit $errorall
}

#----------------------------------------------
#----------------------------------------------
#----------------------------------------------

CleanSims()
{
  echo "cleaning in main dir"
  make cleanall > /dev/null

  for np in $nprocs
  do
    dir="mpisim.$np"
    [ ! -d $dir ] && continue
    echo "cleaning in dir $dir"
    cd $dir
    make cleanall > /dev/null
    cd ..
  done
}

#----------------------------------------------
#----------------------------------------------
#----------------------------------------------

HandleOptions $*

SetApplication
SetProcs

#----------------------------------------------

action="none"

if [ $regress = "YES" ]; then
  action="regress"
  run="YES"
  compare="YES"
  short="NO"
  debug="YES"
  str=$str_regress
fi
if [ $info = "YES" ]; then
  action="info"
  Info
fi
if [ $compile = "YES" ]; then
  action="compile"
  Compile
fi
if [ $run = "YES" ]; then
  action="run"
  CheckSTR
  PrepareBasins
  RunSims
fi
if [ $compare = "YES" ]; then
  action="compare"
  CompareSims
  [ $errorall -ne 0 -a $double_compare = "YES" ] && CompareSims	# try again
  [ $errorall -ne 0 ] && echo "*** errors found" && exit 1
  echo "no errors found..."
fi
if [ $clean = "YES" ]; then
  action="clean"
  CleanSims
fi

if [ $action = "none" ]; then
  echo "no action requested..."
  Usage
fi

#----------------------------------------------

