#
# Makefile to build TeamSpeak 3 SDK Client Sample on Mac OS X
#

CFLAGS = -Wall -g -O0

ts3_sdk=../ts3_sdk

all: soundbackends ts3_client_sample

soundbackends:
	ln -s ${ts3_sdk}/bin/mac/soundbackends .

ts3_client_sample: main.o
	gcc -o ts3_client_sample main.o -L${ts3_sdk}/bin/mac -lts3client
	install_name_tool -change /usr/local/lib/libts3client.dylib ${ts3_sdk}/bin/mac/libts3client.dylib ts3_client_sample

main.o: main.c
	gcc -c -I${ts3_sdk}/include main.c $(CFLAGS)

clean:
	rm -rf *.o ts3_client_sample
