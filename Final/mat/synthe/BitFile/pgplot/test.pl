#!/usr/bin/perl  

use PGPLOT;  # Load PGPLOT module
# File
my $fname = $ARGV[0];

my ($xp,$yp);
my ($n0,$n1);
($n0,$xp,$yp)=&set_xy($ARGV[0]);
my @x0=@{$xp}; 
my @y0=@{$yp}; 

($n1,$xp,$yp)=&set_xy($ARGV[1]);
my @x1=@{$xp};
my @y1=@{$yp};

print "PGPLOT module version $PGPLOT::VERSION\n\n";
pgqinf("VERSION",$val,$len);
print "PGPLOT $val library\n\n";
my $dev='/xwin';
$dev = "?" unless defined $dev; # "?" will prompt for device
pgbegin(0,$dev,1,1);            # Open plot device 
pgscf(1);                       # Set character font
pgslw(6);
pgsch(1.6);                     # Set character height
pgenv(0.0,10.0,-9,-3,0,20);     # Define data limits and plot axes
pglabel("Tdyn","Sr","b3g5");    # Labels
pgsci(5);                       # Change colour
pgpoint($n0,\@x0,\@y0,1);       # Plot points
pgsci(7);                       # Change colour
pgpoint($n1,\@x1,\@y1,1);       # Plot points
pgend;    # Close plot

#-----------------------------

sub set_xy{
    my ($fname) = shift;
    my @x=();
    my @y=();
    my $i=0;
    open(DATA,$fname);
    while(<DATA>){               
	# Read data in 2 columns from file handle
	# and put in two perl arrays
	my ($xi, $yi) = split("\t");
	$x[$i] = $xi;
	$y[$i] = log($yi)/log(10.0);
	$i++;
    }
    close(DATA);
    return($i,\@x,\@y);
}
