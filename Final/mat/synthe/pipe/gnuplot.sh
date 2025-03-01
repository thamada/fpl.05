#!/usr/bin/gnuplot

#set log y

set grid 

plot [0:][0:] "lns.txt" u 1:2 w linespo, \
           "fp.txt" u 1:2 w linespo  \




pause -1

set term tgif
set output "tmp.obj"
replot

