#!/bin/sh
#
# runs restart test
#
# with gotm runs well
# with ibarcl=1 diverges after first time step (10800 is ok, 11100 not)
#
#------------------------------------------------

bindir=$HOME/georg/work/shyfem_repo/shyfemcm/bin

shyfem_serial=$HOME/georg/work/shyfem_repo/shyfem/bin/shyfem
shyfem_mpi=$HOME/georg/work/shyfem_repo/shyfemcm/bin/shyfem
#check=$HOME/georg/work/shyfem_repo/shyfemcm/bin/check_shympi_debug
#rstinf=$HOME/georg/work/shyfem_repo/shyfemcm/bin/rstinf
check=$HOME/georg/work/shyfem_repo/shyfem/bin/check_shympi_debug
rstinf=$HOME/georg/work/shyfem_repo/shyfem/bin/rstinf

post="nogotm"
post=""
post="barc"
post="all"

sim1="vistula04r$post"
sim2="vistula04rr$post"

. $bindir/colors.sh

#------------------------------------------------

CheckStatus()
{
  local status=$1
  local exe=$2
  local text=$3

  if [ $status -ne 99 ]; then
     echo "${red}*** error running $2 ($text)${normal}" 
     exit 1
  fi
}

RegressTest()
{
  local command1=$1
  local command2=$2
  local description=$3

  echo "================================================="
  echo "running $command1 - $command2 - $description"
  echo "================================================="

  echo "running $command1 $sim1.str"
  $command1 -debout $sim1.str > log1.txt 2>&1
  status=$?
  CheckStatus $status $command1 log1.txt

  echo "running $command2 $sim2.str"
  $command2 -debout $sim2.str > log2.txt 2>&1
  status=$?
  CheckStatus $status $command2 log2.txt

  check_shympi_debug -nodiff vistula04r.dbg vistula04rr.dbg > log3.txt
  status=$?
  CheckStatus $status check_shympi_debug log3.txt

  echo "${green}restart test $description is ok${normal}"
}

CheckRst()
{
  $rstinf vistula04r.rst
  mv fort.66 fort.1
  $rstinf tmp/vistula_orig.rst
  mv fort.66 fort.2
  echo "looking for differences..."
  diff fort.1 fort.2
}

CheckExe()
{
  local exe=$1

  if [ ! -x $exe ]; then
    echo "*** no such executable: $exe" 
    error=$(( error + 1 ))
  fi
}

CheckExes()
{
  error=0

  CheckExe $shyfem_serial
  CheckExe $shyfem_mpi
  CheckExe $check
  CheckExe $rstinf

  if [ $error -gt 0 ]; then
    echo "${red}*** error checking executables: $error${normal}"
    exit 7
  fi
}

#------------------------------------------------

echo "running regression tests for vistula restart"

CheckExes

make basin
mkdir -p tmp

RegressTest $shyfem_serial $shyfem_serial "serial - serial"
RegressTest $shyfem_mpi $shyfem_serial "mpi1 - serial"
RegressTest "mpirun -np 4 $shyfem_mpi" $shyfem_serial "mpi4 - serial"
RegressTest "mpirun -np 4 $shyfem_mpi" $shyfem_mpi "mpi4 - mpi1"
RegressTest "mpirun -np 4 $shyfem_mpi" "mpirun -np 4 $shyfem_mpi" "mpi4 - mpi4"

echo "${green}all regression tests passed${normal}"

exit 0

#------------------------------------------------

