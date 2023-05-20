
 if [ $what = "venlag" ]; then
  basins="venlag62 venlag62u"
  simname=mpi_test
  nodes="1000,2000"
  strs=strs
  forcings="data"
  str_regress="mpitest007.str"
 fi

 if [ $what = "medi" ]; then
  basins="medi_163153_c"
  simname=rea_ERA5_IBI_twl_2016
  nodes="1000,2000"
  strs=.
  forcings="vel_lateral_bc.fem lateral_bc.fem meteo.fem"
 fi

 if [ $what = "mpi_med" ]; then
  basins="med_grid"
  simname=Ulisse_test29
  nodes="1000,2000"
  strs=.
  forcings="input"
  str_regress="georg04.str"
  str_regress="georg03.str"
 fi

 if [ $what = "marmenor" ]; then
  basins="Mar_Menor"
  simname=marmenor
  nodes="1000,2000"
  idtshort=100
  strs=.
  forcings="input"
  str_regress="mmn13.str"
  epsdiff=0
  epsdiff=0.000001
 fi

 if [ $what = "vistula" ]; then
  basins="vistula"
  simname=vistula04rmpi
  nodes="1000,2000"
  strs=.
  forcings=input
  #cpfiles=boxes.txt
 fi

