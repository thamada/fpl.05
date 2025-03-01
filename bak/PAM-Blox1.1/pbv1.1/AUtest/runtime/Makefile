# PAM runtime library
# Copyright 1993, 1994 Digital Equipment Corporation.
# Distributed only by permission.
# Last mod on 6/6/1998 by mencer 
#      modified on Mon Jun 17 19:40:39 MET DST 1996 by moll  
#      modified on Wed Jun 12 19:40:54 MET DST 1996 by bertin
#***************************************************************

CC = cc -std1
# Should add the proper place where to find pamio.h - today uses a local copy
CFLAGS = -g -I. -I/proj/system/include
LDFLAGS = -g -L/proj/system/shlib
RT=-lPamRT
APPL=autest

OBJECTS = autest_pam.o 
LIB = libPamDesigns.a
SHLIB = libPamDesigns.so

all: $(APPL)

#***************************************************************
# Compilation rules

$(APPL): $(APPL).o $(APPL)_pam.o
	$(CC) $(LDFLAGS) $(APPL).o $(APPL)_pam.o $(RT) -o $(APPL)


# ***************************************************************
# Cleanup

# Take out DOS CR's
filter-cr:
	for file in *.c *.h Makefile; do \
	  sed 's///g' $$file >$$file.nocr; \
	  if cmp -s $$file $$file.nocr; then \
	    rm $$file.nocr; else mv $$file.nocr $$file; fi; \
	done

clean:
	rm *.o
tidy:
	rm -f ,* .,* *~ .emacs_[0-9]* core a.out

scratch: tidy
	rm -f *.o *.a *.so $(PROGRAM)
	rm -f makeLcaStateTable Pam40*StateTable.c





