
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
	@echo "  info                info on simulations"
	@echo "  collect             collects essential files from subdirs"
	@echo "  distribute          distributes essential files to subdirs"
	@echo "  link                links Makefile, run_test.sh to progs"
	@echo "  clean               cleans log files"
	@echo "  cleanall            also cleans regress dirs"
	@echo "  cleantotal          also cleans regress dirs and mpidir.*"
	@echo "  zip, tar            creates tar file of dir"
	@echo "  dist                creates zip file of essential files"

regress:
	./run-regress.sh short

regress_long:
	./run-regress.sh long

regress_short:
	./run-regress.sh short

info:
	./run-regress.sh info

collect:
	./run-regress.sh collect

distribute:
	./run-regress.sh distribute

diff:
	@cd progs/settings; ./diff.sh

partition:
	./run-regress.sh partition

link:
	./run-regress.sh link

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

cleantotal: clean
	./run-regress.sh clean

dist:
	zip -r $(DIR)-dist.zip $(DIST) progs/settings/*

tar: zip
zip: cleantotal
	tar cvhzf $(DIR).tar.gz .

#----------------------------------------------------------

