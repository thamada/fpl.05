#!/usr/bin/gnuplot

#set log y

set xtics 1
set grid 


# SLICES
plot [0:11][0:] "log.itp" u 2:3 w linespo 5 ,\
              "log.noitp" u 2:3 w linespo 7

# MHz
#plot [0:11][0.0;] "log.itp" u 2:4 w linespo 5 ,\
#              "log.noitp" u 2:4 w linespo 7






pause -1

set term tgif
set output "tmp.obj"
replot

