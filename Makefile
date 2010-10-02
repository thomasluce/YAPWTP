EXAMPLES = syntax

CFLAGS = -g3 -Wall -O3 -std=gnu99
all : $(EXAMPLES)

syntax : .FORCE
	`which leg` -o syntax.leg.c syntax.leg
	$(CC) $(CFLAGS) -c bstrlib.c
	$(CC) $(CFLAGS) -c syntax.leg.c
	$(CC) $(CFLAGS) -o bin/parser syntax.leg.o bstrlib.o

testlist: .FORCE
	$(CC) $(CFLAGS) -c bstrlib.c
	$(CC) $(CFLAGS) -c list.c
	$(CC) $(CFLAGS) -c testlist.c
	$(CC) $(CFLAGS) -o testlist testlist.o bstrlib.o list.o

clean : .FORCE
	rm -f *~ *.o *.[pl]eg.[cd] $(EXAMPLES)

.FORCE :
