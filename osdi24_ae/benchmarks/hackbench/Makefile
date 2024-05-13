hackbench: hackbench.c
	$(CC) $(CFLAGS) -o hackbench hackbench.c -g -gdwarf-4 -fno-omit-frame-pointer -O3 -Wl,--no-as-needed -ldl -lpthread -Wl,--rpath=/usr/local/lib/glibc-testing/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing/lib/ld-linux.so.2

clean :
	rm -f hackbench
