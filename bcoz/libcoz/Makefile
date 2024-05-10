ROOT 		 := ..
TARGETS  := libcoz.so
LIBS     := -ldl -lrt -lpthread -Wl,--no-as-needed -ldl -Wl,--rpath=/usr/local/lib/glibc-testing-2.30/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing-2.30/lib/ld-linux.so.2 $(shell pkg-config --libs libelf++ libdwarf++)
#LIBS     := -ldl -lrt -lpthread -Wl,--rpath=/usr/local/lib/glibc-testing-frame -Wl,--dynamic-linker=/usr/local/lib/glibc-testing-frame/lib/ld-linux.so.2 -L/usr/local/lib/glibc-testing-frame/lib/ -lelf++ -ldwarf++
CXXFLAGS := -gdwarf-3 --std=c++0x -g -O2 -fno-omit-frame-pointer -fPIC -I$(ROOT)/include -I. \
            $(shell pkg-config --cflags libelf++ libdwarf++)

include $(ROOT)/common.mk

check:: libcoz.so
	printf "int main(int argc, char *argv[])\n{\nreturn (0);\n}\n" > x.c
	gcc -g -o x x.c || ( $(RM) x x.c ; exit 1)
	../coz run --- ./x
	if grep -q time= profile.coz; then echo success: coz profiler ran as it should.; fi
	$(RM) -f x.c x profile.coz
