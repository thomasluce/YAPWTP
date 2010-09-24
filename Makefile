EXAMPLES = syntax

CFLAGS = -g -O3 -std=gnu99
all : $(EXAMPLES)

syntax : .FORCE
	`which leg` -o syntax.leg.c syntax.leg
	$(CC) $(CFLAGS) -o bin/parser syntax.leg.c


clean : .FORCE
	rm -f *~ *.o *.[pl]eg.[cd] $(EXAMPLES)

.FORCE :
