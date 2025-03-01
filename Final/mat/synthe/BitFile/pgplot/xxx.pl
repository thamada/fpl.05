#!/usr/bin/perldl

#use PDL::Graphics::PGPLOT;

$ENV{PGPLOT_XW_WIDTH}=0.3;
dev('/XSERVE');
$x=sequence(10);
$y=2*$x**2;

points $x, $y;
line $x, $y;




