# Pamette runtime makefile
# Last modified  by oskar

CLIB = -lPamRT -lrt
CC = cc 

OBJ_FILES = des.o des_pam.o

NAME = des
UTIL = text2bin bin2text

#************************************************************
# Global Entry

all: $(NAME) $(UTIL)


$(NAME): $(OBJ_FILES) $(NAME)_pam.c
	$(CC) $(CFLAGS) $(OBJ_FILES) $(CLIB) -o $(NAME)

text2bin: text2bin.c
	$(CC) $(CFLAGS) -o text2bin text2bin.c

bin2text: bin2text.c
	$(CC) $(CFLAGS) -o bin2text bin2text.c

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
