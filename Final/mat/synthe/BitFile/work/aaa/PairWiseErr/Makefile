#CC = gcc -O4 -Wall -static
CC = gcc -g -Wall -static
#CC = icc -O -Wall -static
#LDLIBS = -lglut -lGL -lGLU -lm 
LDLIBS = -lm
HEADER = nbodysim.h

EMUDIR = ./pgpg

OBJS = main.o force.o debug_func_force.o \
       debug_position.o energy.o init_particles.o \
       force_2ji.o euler_2ji.o leapflog.o leapflog_half.o \
       writelog.o force_LJ.o \
       $(EMUDIR)/pg_module.o $(EMUDIR)/pg_pipe.o \
       force_gravity_on_b3.o libb3grav.a \
       force_gravity_on_b3_dbg.o \
       b3_force_sepaj4.o 

#       force_gravity_on_pg2.o check_pg2emu.o \
#       pglib.o \
#       libg6a.a

#       libpgsim.a \

test.exe: $(OBJS) $(HEADER)
	$(CC)	$(OBJS)  -o test.exe $(LDLIBS)

show:
	gcc showAnim.c -o aho -lglut -lglut -lm -lX11 \
              -L/home/hamada/home2/Mesa-5.1/lib -L/usr/X11R6/lib -L/usr/lib  \
              -I/home/hamada/home2/Mesa-5.1/include

#	./aho ./log.tmp
#	rm -rf ./aho
clean: 
	rm -rf *.o pgpg/*.o *~ .*~ test.exe
