EXAMPLES = syntax

CFLAGS = -g -O3 -std=gnu99
all : $(EXAMPLES)

syntax : .FORCE
	mkdir -p bin
	`which leg` -o syntax.leg.c syntax.leg
	$(CC) $(CFLAGS) -c bstrlib.c
	$(CC) $(CFLAGS) -c syntax.leg.c
	$(CC) $(CFLAGS) -o bin/parser syntax.leg.o bstrlib.o


clean : .FORCE
	rm -f *~ *.o *.[pl]eg.[cd] $(EXAMPLES)

.FORCE :
