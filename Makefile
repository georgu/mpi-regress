
DIR = regress-mpi

SPECIAL = README Makefile License
DIST = $(SPECIAL) run-regress.sh \
	progs/Makefile progs/run_test.sh progs/test_partition.sh

#----------------------------------------------------------

default:
	@echo "available targets:"
	@echo "  regress             runs default regression test (short)"
	@echo "  regress_long        runs long regression test"
	@echo "  regress_short       runs short regression test"
	@echo "  regress_restart     runs restart regression test"
	@echo "  regress_long_bg     runs long regression test in background"
	@echo "  regress_short_bg    runs short regression test in background"
	@echo "  compare             only compares regression tests"
	@echo "  partition           runs regression only on partitioning"
	@echo "  info                info on simulations"
	@echo "  collect             collects files from subdirs to settings"
	@echo "  distribute          distributes files in settings to subdirs"
	@echo "  diff                looks for differences in settings and str"
	@echo "  link                links Makefile, run_test.sh to progs"
	@echo "  init                links Makefile, run_test.sh to progs"
	@echo "  clean               cleans log files"
	@echo "  cleanall            also cleans regress dirs"
	@echo "  cleantotal          also cleans regress dirs and mpidir.*"
	@echo "  zip, tar            creates tar file of dir"
	@echo "  dist                creates zip file of essential files"
	@echo "  npwant=np	     set desired processors to np"

regress:
	./run-regress.sh short

regress_restart:
	./run-regress.sh restart

regress_long:
	./run-regress.sh long

regress_long_bg:
	@echo "running in background - log in bg_long.log"
	@echo "using $(npwant) processors"
	nohup ./run-regress.sh long > bg_long.log 2>&1 &

regress_short:
	./run-regress.sh short

regress_short_bg:
	@echo "running in background - log in bg_short.log"
	@echo "using $(npwant) processors"
	nohup ./run-regress.sh short > bg_short.log 2>&1 &

compare:
	./run-regress.sh compare

partition:
	./run-regress.sh partition

info:
	./run-regress.sh info

collect:
	./run-regress.sh collect

distribute:
	./run-regress.sh distribute

diff:
	@cd progs/settings; ./diff.sh

init:
	./run-regress.sh link

link:
	./run-regress.sh link

stats:
	./progs/stats.sh

#----------------------------------------------------------

clean:
	-rm -f *.log
	-rm -f *.zip
	-rm -f *.tar
	-rm -f *.tar.gz
	-rm -f fort.*
	-rm -f errors.txt
	-rm -f domain_error_*.grd

cleanall: clean
	./run-regress.sh clean
	-rm -f part_error[12].grd
	-rm -f regression.log
	-rm -f *.zip
	-rm -f *.tar.gz

cleantotal: cleanall

dist:
	zip -r $(DIR)-dist.zip $(DIST) progs/settings/*

tar: zip
zip: cleantotal
	tar cvhzf $(DIR).tar.gz .

#----------------------------------------------------------

