
#-------------------------------------------------------

include ./settings.sh

#-------------------------------------------------------

DIR = $(what)
MPIDIRS = `ls -d mpisim.[0-9]*`
STR = $(str_regress)
BASIN = $(basins)
SHYDIR = $(HOME)/georg/work/shyfem_repo

COMPARE_OPTIONS = -nodiff -nostop
COMPARE_OPTIONS = -nodiff -chkonlydbg

ifeq ("$(wildcard $(SHYDIR))","")
  $(error "Directory does not exist: $(SHYDIR)")
else
  $(info using SHYDIR = $(SHYDIR))
endif

#-------------------------------------------------------

default:
	@echo "possible targets:"
	@echo "  regress         run default regression test (short)"
	@echo "  regress_long    run long regression test"
	@echo "  regress_short   run short regression test"
	@echo "  compare         compare tests"
	@echo "  link_exes       make symbolic links to shyfem exes"

regress: regress_short
regress_long: debug_long
regress_short: debug_short

run: cleanrun
	./run_test.sh -run $(STR)

debug_long: cleanrun
	./run_test.sh -run -debug -long $(STR)

debug: debug_short
debug_short: cleanrun
	./run_test.sh -run -debug $(STR)

cleanrun:
	./run_test.sh -clean

#compare: compare_summary
compare: compare_no_summary

compare_summary:
	./run_test.sh -compare -summary $(COMPARE_OPTIONS)

compare_no_summary:
	./run_test.sh -compare $(COMPARE_OPTIONS)

compare_full:
	./run_test.sh -compare 

info:
	./run_test.sh -info 

link: link_exes
link_exes:
	ln -fs $(SHYDIR)/shyfem/bin/shyfem shyfem
	ln -fs $(SHYDIR)/shyfem-mpi/bin/shyfem shyfem-mpi

basin:
	shypre -noopti $(BASIN).grd

tripple:
	grep 'total numbers of tripple points:' mpisim.*/logfile.txt | \
		sed -e 's/total numbers of//'

#-------------------------------------------------------

clean:
	-rm -f auxlog.txt
	-rm -f compare.log
	-rm -f errout.dat
	-rm -f gmon.out
	-rm -f ggg hhh
	-rm -f fort.*
	-rm -f *.job
	-rm -f mpi_debug_*.txt

cleanall: clean
	-rm -f *.log
	-rm -f *.flx *.shy *.inf *.ext *.dbg *.rst
	-rm -f out.fem
	-rm -f all.[23]d.[1-9]*
	-rm -f all_scal_nodes.[23]d.txt
	-rm -f zeta.[23]d.[1-9]*
	-rm -f velx.[23]d.[1-9]*
	-rm -f vely.[23]d.[1-9]*
	-rm -f vel_p.[23]d.[1-9]*
	-rm -f speed.[23]d.[1-9]*
	-rm -f dir.[23]d.[1-9]*
	-rm -f salt.[23]d.[1-9]*
	-rm -f temp.[23]d.[1-9]*
	-rm -f salt_[sp].[23]d.txt
	-rm -f temp_[sp].[23]d.txt
	-rm -f *.bas
	-rm -f domain[12].grd
	-rm -f domain_error_[0-9]*.grd
	-rm -f part_error[12].grd
	-rm -f *.bas.[0-9]*.node.grd
	-rm -f *.bas.[0-9]*.elem.grd
	-rm -f logfile.txt
	-rm -f boxes_*.txt

cleantotal: cleanall
	@echo "cleaning dirs: $(MPIDIRS)"
	-rm -rf $(MPIDIRS)
	-rm -f shyfem shyfem-mpi

zip: cleantotal
	-zip -r $(DIR).zip *

#-------------------------------------------------------

