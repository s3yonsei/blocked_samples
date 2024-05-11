CC=gcc
CFLAGS=-g -gdwarf-4 -fno-omit-frame-pointer -Wl,--no-as-needed -ldl -lpthread -Wl,--rpath=/usr/local/lib/glibc-testing-temp/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing-temp/lib/ld-linux.so.2

all: $(SRC)
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case1 test_motivational_case1.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case2 test_motivational_case2.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case1_coz test_motivational_case1_coz.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -o test_motivational_case2_coz test_motivational_case2_coz.c
clean:
	rm test_motivational_case1 test_motivational_case2 test_motivational_case1_coz test_motivational_case2_coz
