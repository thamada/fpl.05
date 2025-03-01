# Pamette runtime makefile
# Last modified by mencer

CLIB = -lPamRT -lrt
CC = cc 

NAME = cordic

OBJ_FILES = $(NAME).o $(NAME)_pam.o

#************************************************************
# Global Entry

all: $(NAME)


$(NAME): $(OBJ_FILES) $(NAME)_pam.c
	$(CC) $(CFLAGS) $(OBJ_FILES) $(CLIB) -o $(NAME)

#************************************************************
# Dependencies
# Run "make depend" and paste the result at the end of this file

depend:
	$(CC) $(CFLAGS) -M *.c | fgrep './' | sed 's+\./++g'


#************************************************************
tidy:
	rm -f ,* .,* *~ a.out core 

clean: tidy
	rm *.o $(NAME)

# ***************************************************************
# Paste here the result of "make depend"
