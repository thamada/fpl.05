#CC = gcc -O4 -Wall -static
CC = gcc -g -Wall -static
#CC = icc -O -Wall -static
#LDLIBS = -lglut -lGL -lGLU -lm 
LDLIBS = -lm
HEADER = nbodysim.h

EMUDIR = ./pgpg

OBJS = main.o force.o debug_func_force.o \
       debug_position.o energy.o init_particles.o \
       leapflog.o leapflog_half.o \
       writelog.o \
       pg_module.o pg_pipe.o \
       pg_pipev.o libb3.a \

test.exe: $(OBJS) $(HEADER)
	$(CC)	$(OBJS)  -o run.x $(LDLIBS)

show:
	gcc showAnim.c -o aho -lglut -lglut -lm -lX11 \
              -L/home/hamada/home2/Mesa-5.1/lib -L/usr/X11R6/lib -L/usr/lib  \
              -I/home/hamada/home2/Mesa-5.1/include

#	./aho ./log.tmp
#	rm -rf ./aho
clean: 
	rm -rf *.o pgpg/*.o *~ .*~ run.x
