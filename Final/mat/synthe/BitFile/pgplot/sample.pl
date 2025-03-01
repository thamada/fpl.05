#!/usr/bin/perl

use PGPLOT;
pgbegin(0,"/xserve",1,1);
pgenv(1,10,1,10,1,20);
pglabel('X','Y','Tsuyoshi Hamada');
pgpoint(7,[2..8],[2..8],5);
# etc...
pgend;


