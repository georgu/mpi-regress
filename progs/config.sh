#!/bin/bash
#
# configuration for servers
#
#---------------------------------------------------

[ -z "$hostname" ] && hostname=$( hostname )

echo "configuring mpi_regress for $hostname"

if [ $hostname = "Caesium" ]; then

  repodir="$HOME/work/shyfem_repo"

  shydir_serial="$repodir/shyfemcm"
  shydir_mpi="$repodir/shyfemcm"
  shyfem_serial="$shydir_mpi/bin/shyfem"
  shyfem_mpi="$shydir_mpi/bin/shyfem"
  check_debug="$shydir_mpi/bin/check_shympi_debug"

  npmax=4

elif [ $hostname = "lagoon" ]; then

  repodir="$HOME/georg/work/shyfem_repo"

  shydir_serial="$repodir/shyfemcm-ismar"
  shydir_mpi="$repodir/shyfemcm-ismar-mpi"
  shyfem_serial="$shydir_mpi/bin/shyfem"
  shyfem_mpi="$shydir_mpi/bin/shyfem"
  check_debug="$repodir/shyfem/bin/check_shympi_debug"

  npmax=16

elif [ $hostname = "stream" ]; then

  repodir="$HOME/georg/work/shyfem_repo"

  shydir_serial="$repodir/shyfemcm-ismar"
  shydir_mpi="$repodir/shyfemcm-ismar-mpi"
  shyfem_serial="$shydir_mpi/bin/shyfem"
  shyfem_mpi="$shydir_mpi/bin/shyfem"
  check_debug="$repodir/shyfem/bin/check_shympi_debug"

  npmax=16

elif [ $hostname = "tide" ]; then

  repodir="$HOME/georg/work/shyfem_repo"

  shydir_serial="$repodir/shyfemcm-ismar"
  shydir_mpi="$repodir/shyfemcm-ismar"
  shyfem_serial="$shydir_mpi/bin/shyfem"
  shyfem_mpi="$shydir_mpi/bin/shyfem"
  check_debug="$repodir/shyfemcm-ismar/bin/check_shympi_debug"

  npmax=32

else
  echo "*** no entry found in config.sh for hostname: $hostname ...aborting"
  exit 1
fi

[ ! -d $repodir ] && echo "*** no such dir: $repodir" && exit 3
[ ! -d $shydir_serial ] && echo "no such dir: $shydir_serial" && exit 5
[ ! -d $shydir_mpi ] && echo "no such dir: $shydir_mpi" && exit 5
[ ! -x $shyfem_serial ] && echo "no such exe: $shyfem_serial" && exit 7
[ ! -x $shyfem_mpi ] && echo "no such exe: $shyfem_mpi" && exit 7
[ ! -x $check_debug ] && echo "no such exe: $check_debug" && exit 7

echo "mpi_regress successfully configured for $hostname"

#---------------------------------------------------

