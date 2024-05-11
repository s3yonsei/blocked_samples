UCC = cc
include ../config/make.def

# Note that COMPILE is also defined in make.common and should
# be the same. We can't include make.common because it has a lot
# of other garbage. 
FCOMPILE = $(FC) -c $(F_INC) $(FFLAGS)

all: setparams 

# setparams creates an npbparam.h file for each benchmark 
# configuration. npbparams.h also contains info about how a benchmark
# was compiled and linked

setparams: setparams.c ../config/make.def
	$(UCC) ${CONVERTFLAG} -g -gdwarf-3 -fno-omit-frame-pointer -Wl,--no-as-needed -ldl -fopenmp -Wl,--rpath=/usr/local/lib/glibc-testing-2.30/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing-2.30/lib/ld-linux.so.2 -o setparams setparams.c


clean: 
	-rm -f setparams setparams.h npbparams.h
	-rm -f *~ *.o

