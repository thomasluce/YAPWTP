EXAMPLES = syntax

CFLAGS = -g3 -Wall -std=gnu99
all : $(EXAMPLES)

syntax : .FORCE
	mkdir -p bin
	`which leg` -o src/syntax.leg.c src/syntax.leg
	$(CC) $(CFLAGS) -c src/bstrlib.c
	$(CC) $(CFLAGS) -c src/syntax.leg.c
	$(CC) $(CFLAGS) -c src/list.c
	$(CC) $(CFLAGS) -o bin/parser syntax.leg.o bstrlib.o list.o

testlist: .FORCE
	$(CC) $(CFLAGS) -c src/bstrlib.c
	$(CC) $(CFLAGS) -c src/list.c
	$(CC) $(CFLAGS) -c src/testlist.c
	$(CC) $(CFLAGS) -o bin/testlist testlist.o bstrlib.o list.o

clean : .FORCE
	rm -rf bin/* *~ src/*.o src/*.[pl]eg.[cd] $(EXAMPLES)

.FORCE :
