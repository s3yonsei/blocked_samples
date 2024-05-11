CC=gcc
CFLAGS=-g -gdwarf-4 -fno-omit-frame-pointer -Wl,--no-as-needed -ldl -lpthread -Wl,--rpath=/usr/local/lib/glibc-testing/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing/lib/ld-linux.so.2

all: $(SRC)
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case1 test_motivational_case1.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case2 test_motivational_case2.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case1_bcoz test_motivational_case1_bcoz.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case2_bcoz test_motivational_case2_bcoz.c
clean:
	rm test_motivational_case1 test_motivational_case2 test_motivational_case1_bcoz test_motivational_case2_bcoz
