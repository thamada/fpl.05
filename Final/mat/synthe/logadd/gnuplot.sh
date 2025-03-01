#!/usr/bin/gnuplot

#set log y

set grid 

plot [0:11][] "log.txt" u 2:3 w linespo







#              "log.txt" u 1:2 w po \




pause -1

set term tgif
set output "tmp.obj"
replot

