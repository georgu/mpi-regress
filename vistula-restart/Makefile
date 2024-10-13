
#--------------------------------------------------------

BASIN = Vistula_Preg_Dejma_3Opend

BASE=$(HOME)/work/shyfem_repo

#--------------------------------------------------------

default:

basin:
	shypre -silent $(BASIN).grd

regress_restart: regress
regress_long: regress
regress_short: regress
regress: cleanall init
	./run_regress.sh

init: input nothing
input:
	ln -s ../vistula/input

link:
	-ln -fs $(BASE)/shyfem/fem3d/shyfem shyfem
	-ln -fs $(BASE)/shyfem-mpi/fem3d/shyfem shyfem-mpi
	-ln -fs $(BASE)/shyfem-mpi/fem3d/check_shympi_debug check_shympi_debug

cleanrun: cleanall

compare:

nothing:
	@true

#--------------------------------------------------------

clean:
	-rm -f errout.dat
	-rm -f *.ext *.shy *.flx *.inf *.log
	-rm -f *.dbg *.rst
	-rm -f mpi_debug_*.txt
	-rm -f fort.*
	-rm -f log*.txt
	-rm -f gmon.out

cleanall: clean
	-rm -f *.bas

cleantotal: cleanall
	-rm -f shyfem shyfem-mpi shyfem-serial check_shympi_debug
	-rm -rf tmp
	-rm -f input

#--------------------------------------------------------

