#
# Makefile to build TeamSpeak 3 SDK Server Sample on Mac OS X
#

CFLAGS = -Wall -g -O0

ts3_sdk=../ts3_sdk

all: ts3_server_sample

ts3_server_sample: id_io.o main.o
	gcc -o ts3_server_sample id_io.o main.o -L${ts3_sdk}/bin/mac -lts3server
	install_name_tool -change /usr/local/lib/libts3server.dylib ${ts3_sdk}/bin/mac/libts3server.dylib ts3_server_sample

main.o: main.c
	gcc -c -I${ts3_sdk}/include main.c $(CFLAGS)

clean:
	rm -rf *.o ts3_server_sample
