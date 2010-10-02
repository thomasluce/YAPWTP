EXAMPLES = syntax

CFLAGS = -g3 -Wall -std=gnu99
all : $(EXAMPLES)

syntax : .FORCE
	`which leg` -o syntax.leg.c syntax.leg
	$(CC) $(CFLAGS) -c bstrlib.c
	$(CC) $(CFLAGS) -c syntax.leg.c
	$(CC) $(CFLAGS) -c list.c
	$(CC) $(CFLAGS) -o bin/parser syntax.leg.o bstrlib.o list.o

testlist: .FORCE
	$(CC) $(CFLAGS) -c bstrlib.c
	$(CC) $(CFLAGS) -c list.c
	$(CC) $(CFLAGS) -c testlist.c
	$(CC) $(CFLAGS) -o bin/testlist testlist.o bstrlib.o list.o

clean : .FORCE
	rm -rf bin/* *~ *.o *.[pl]eg.[cd] $(EXAMPLES)

.FORCE :
