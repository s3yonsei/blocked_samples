CC=gcc
CFLAGS=-g -fno-omit-frame-pointer -Wl,--no-as-needed -ldl -lpthread -Wl,--rpath=/usr/local/lib/glibc-testing-2.30/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing-2.30/lib/ld-linux.so.2
#CFLAGS=-g -fno-omit-frame-pointer
TARGET=test_io
SRC=test_io.c

test: $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

clean:
	rm $(TARGET)
