#!/bin/bash
#
# runs and compares shyfem in serial and mpi mode
#
#
# RunSims
#	RunShyfem $np
#		shyfem
#
# CompareSims
#	CompareShyfem $olddir $dir
#		HandleCompareFiles $ext $dir1 $dir2
#			PrepareFiles $ext $dir1
#			PrepareFiles $ext $dir2
#			CompareFiles $ext $dir1 $dir2
#				diff $file1 $file2
#		...
#		HandleCompareDbg $dir1 $dir2
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
nprocs="0 1 4 6"
nprocs="0 1 4 6 17 18 19 47 48 49 50 51 52"
nptype="npmax2"
nptype="custom"
nptype="npmax"
#npmin=10
#npmin=11
#npmax=20
npmax=16
#npmax=11
#npmax=4
npmax=32
npmax=64
npmax=128
npmax=32
npmax=8

hostname=$( hostname )

repodir="$HOME/georg/work/shyfem_repo"

shydir_mpi="$repodir/shyfem-mpi"
shydir_mpi="$repodir/shyfemcm-ismar"
shydir_serial="$repodir/shyfemcm-ismar"
#shydir_serial="$repodir/shyfem"

[ ! -d $shydir_mpi ] && echo "no such dir: $shydir_mpi" && exit 1
[ ! -d $shydir_serial ] && echo "no such dir: $shydir_serial" && exit 1

thisdir=$( dirname $0 )
echo "executing $0 from $thisdir"
[ -z "$basedir" ] && basedir=".."
echo "basedir is $basedir"
. $basedir/progs/config.sh
[ $? -ne 0 ] && echo "*** error reading config.sh" && exit 9

#npwant=4

actdir=$( pwd )
mpi_command="mpirun"
mpi_command="mpirun --oversubscribe"
[ $hostname = "stream" ] && mpi_command="mpirun"
[ $hostname = "storm" ] && mpi_command="mpirun"
[ $hostname = "tide" ] && mpi_command="mpirun"
check_debug=$shydir_mpi/bin/check_shympi_debug
check_debug=$shydir_serial/bin/check_shympi_debug

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

 if [ $maxdiff = "YES" ]; then
   epsdiff=$epsglobal
   echo "overriding local epsdiff with global one"
   echo "epsdiff = $epsdiff"
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
  echo "  -npwant np           run with np processors"
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
  npwant=0

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
        -npwant)        npwant=$2; shift;;
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
        -maxdiff)       maxdiff="YES"; epsglobal=$2; shift;;
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
    [ $npwant -eq 0 ] && npwant=$npmax
    nlist=$( seq $npmin $npwant )
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

  echo "cpus available: $cpus"
  echo "nprocs max: $npmax"
  echo "nprocs want: $npwant"
  echo "nprocs used: $nprocs"
  #exit 0
}

Info()
{
  local dir
  local shybin

  echo "what: $what"
  echo "cpus available: $cpus"
  echo "nprocs max: $npmax"
  echo "nprocs want: $npwant"
  echo "nprocs used: $nprocs"
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
  shybin=$dir/bin/shyfem
  if [ ! -x $shybin ]; then
    echo "*** no such executable: $shybin"
    exit 1
  else
    local version_mpi=$( $shybin | grep version )
    echo "version_mpi: $version_mpi"
  fi
  [ -L shyfem-mpi ] && rm -f shyfem-mpi
  ln -s $dir/bin/shyfem shyfem-mpi

  dir=$shydir_serial
  if [ ! -d $dir ]; then
    echo "*** no such directory: $dir"
    exit 1
  fi
  shybin=$dir/bin/shyfem
  if [ ! -x $shybin ]; then
    echo "*** no such executable: $shybin"
    exit 1
  else
    local version_serial=$( $shybin | grep version )
    echo "version_serial: $version_serial"
  fi
  [ -L shyfem-serial ] && rm -f shyfem-serial
  ln -s $dir/bin/shyfem shyfem-serial
}

PrepareBasins()
{
  export SHYFEMDIR=$shydir_mpi
  for basin in $basins
  do
    [ -f $basin.bas ] && continue
    #mpi_basin.sh $np $basin.grd
    echo "preparing basin $basin"
    $shydir_mpi/bin/shypre -noopti -silent $basin.grd
    [ $? -ne 0 ] && echo "error creating basin $basin" && exit 1
  done
  export SHYFEMDIR=$shydir_serial
  #echo "SHYFEMDIR=$SHYFEMDIR"
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

DeleteFile()
{
  local file=$1
  [ -f $file ] && rm -f $file
}

CopyFile()
{
  local file=$1
  local dir=$2
  [ -f $file ] && cp $file $dir
}

CopyFiles()
{
  local dir=$1
  local strdir=$strs
  [ -z "$strdir" ] && strdir="."

  cp $strdir/$str $dir
  cp *.bas $dir
  cp *.grd $dir
  CopyFile gotmturb.nml $dir
  CopyFile Makefile $dir
  CopyFile settings.sh $dir
  CopyFile boxes.txt $dir
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
    echo "  running $str of $what with np=$np in $dir"
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

  local options=""
  [ $debug = "YES" ] && options="-debout -mpi_debug"
  #echo "options are $options"

  DeleteFile running_shyfem_ok.log

  local shydir
  local command

  if [ $np -eq 0 ]; then
    shydir=$shydir_serial
    command="$shydir/bin/shyfem $options $str"
  elif [ $np -eq 1 ]; then
    shydir=$shydir_mpi
    command="$shydir/bin/shyfem $options $str"
  else
    shydir=$shydir_mpi
    options="-mpi $options"
    command="$mpi_command -np $np $shydir/bin/shyfem $options $str"
  fi
  echo "$command" > run-command.sh
  chmod +x run-command.sh
  local adir=$( pwd )
  #echo "    running as: $command"
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
    echo "*** running with command: $command"
    echo "*** writing to $LOG and $LLOG"
    echo "*** error running with np = $np" >> $LOG
    echo "*** error running with np = $np" >> $LLOG
    if [ $stop_on_run_error = "YES" ]; then
      exit 1
    else
      return
    fi
  else
    touch running_shyfem_ok.log
    local timeline=$( grep "TIME TO SOLUTION (CPU)  =" logfile.txt )
    echo "   $timeline"
  fi
}

#----------------------------------------------
#----------------------------------------------
#----------------------------------------------

PrepareAllFiles()
{
  local dir=$1

  errortext=""

  errors=0
  DeleteFile files_prepared.log

  if [ ! -f $dir/running_shyfem_ok.log ]; then
    errortext="  *** no valid run of $what in $dir"
    echo "$errortext" >> $LOG
    echo "$errortext" >> $LLOG
    (( errorall += 1 ))
    return
  fi

  echo "  preparing data files in $dir"

  if [ $chkonlydbg = "NO" ]; then
    PrepareFiles "ext" $dir
    PrepareFiles "hydro.shy" $dir
    PrepareFiles "conz.shy" $dir
    PrepareFiles "ts.shy" $dir
  fi

  if [ $errors -gt 0 ]; then
    errortext="  *** errors preparing files in $dir"
    (( errorall += 1 ))
  else
    touch files_prepared.log
  fi
}

PrepareFiles()
{
  local ext=$1
  local dir=$2
  local file=$simname.$ext

  [ $verbose = "YES" ] && echo "    preparing $file with extension $ext in $dir"

  cd $dir

  if [ -f $file ]; then
    if [ $ext = "ext" ]; then
      shyelab -split $file &>> logfile.txt
    else
      shyelab -node $nodes $file &>> logfile.txt
    fi
    tail -1 logfile.txt | grep 'error stop'
    if [ $? -eq 0 ]; then
      errortext="*** errors preparing files in $dir for $file"
      echo "$errortext"
      (( errors += 1 ))
      files=""
    else
      files=$( ls *.[23]d.[0-9]* )
    fi
  else
    files=""
  fi

  cd ..
}

CompareFiles()
{
  local dir1=$1
  local dir2=$2

  error=0
  nfile=0

  cd $dir1
  files1=$( ls *.[23]d.[0-9]* 2> /dev/null )
  cd ..
  cd $dir2
  files2=$( ls *.[23]d.[0-9]* 2> /dev/null )
  cd ..

  if [ "$files1" != "$files2" ]; then
    echo "files in $dir1 and $dir2 are different"
    (( error += 1 ))
    files=""
  else
    files=$files1
  fi

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
  echo "  $nfile data files compared - errors found: $error"
}

CompareDbg()
{
  local dir1=$1
  local dir2=$2

  dbglog=$PWD/auxlog.txt
  [ -f $dbglog ] && rm -f $dbglog

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

    cd $dir2
    command="$check_debug $option ../$dir1/$file $file"
    echo "$command" > dbg-command.sh
    chmod +x dbg-command.sh
    $command > $dbglog
    status=$?
    cd ..

    if [ $verbose = "YES" -o $status -ne 99 ]; then
      echo "   comparing dbg as: $command"
      cat $dbglog
    fi
    if [ $status -eq 99 ]; then
      echo "  2 dbg files compared - errors found: 0"
    elif [ $status -eq 0 ]; then
      echo "  2 dbg files compared - generic error"
      error=1
    else
      echo "  2 dbg files compared - errors found: $status"
      error=$status
    fi
  else
    echo "  0 dbg files compared - errors found: 0"
  fi

  (( error_compare += error ))
}

CompareShyfem()
{
  dir1=$1
  dir2=$2

  #echo "----------------------------------------"
  echo "  comparing directories $dir1 and $dir2"
  #echo "----------------------------------------"

  [ -z "$dir1" ] && echo "directory $dir1 is missing..." && exit 1
  [ -z "$dir2" ] && echo "directory $dir2 is missing..." && exit 1

  error_compare=0

  #--------------------------------------------

  if [ $chkonlydbg = "NO" ]; then
    CompareFiles $dir1 $dir2
  fi

  CompareDbg $dir1 $dir2

  #--------------------------------------------

  if [ $error_compare -ne 0 ]; then
    echo "  *** a total of $error_compare errors found"
    echo "*** error comparing between $firstnp - $np" >> $LOG
    echo "*** error comparing between $firstnp - $np" >> $LLOG
    (( errorall += error_compare ))
  fi
}

#----------------------------------------------

CompareSims()
{
  ndir=0
  error=0
  errorall=0
  firstdir=
  firstnp=

  for np in $nprocs
  do
    (( ndir += 1 ))
    dir="mpisim.$np"
    echo "----------------------------------------"
    echo "comparing $what in directory $dir"
    echo "----------------------------------------"
    PrepareAllFiles $dir
    if [ -n "$errortext" ]; then
      echo "$errortext"
      continue
    elif [ -n "$firstdir" ]; then
      CompareShyfem $firstdir $dir
    fi
    [ -z "$firstdir" ] && firstdir=$dir		#this is first good dir
    [ -z "$firstnp" ] && firstnp=$np		#this is first good np
  done

  echo "----------------------------------------"
  echo "finished comparing directories"
  echo "----------------------------------------"

  echo "    $ndir directories of $what compared - errors found: $errorall"
  if [ $errorall -ne 0 ]; then
    echo "error summary:"
    cat $LLOG
  fi
}

#----------------------------------------------
#----------------------------------------------
#----------------------------------------------

CleanSims()
{
  local basedir=$( pwd )

  echo "cleaning in $basedir"
  make cleanall > /dev/null

  for np in $nprocs
  do
    dir="mpisim.$np"
    [ ! -d $dir ] && continue
    [ $verbose = "YES" ] && echo "cleaning in basedir subdirectory $dir"
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
  Info
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

