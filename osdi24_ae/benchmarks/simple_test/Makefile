CC=gcc
CFLAGS=-g -fno-omit-frame-pointer -Wl,--no-as-needed -ldl -Wl,--rpath=/usr/local/lib/glibc-testing-temp/lib -Wl,--dynamic-linker=/trusted/local/lib/glibc-testing-temp/lib/ld-linux.so.2 -lpthread

TARGET=test_io
SRC=test_io.c

TARGET2=test_io_coz
SRC2=test_io_coz.c

all: $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET2) $(SRC2)

clean:
	rm $(TARGET) $(TARGET2)
