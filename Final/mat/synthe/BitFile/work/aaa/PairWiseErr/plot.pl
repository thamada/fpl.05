#!/usr/bin/perl  

use PGPLOT;  # Load PGPLOT module

my $GL;
my @files=("log.list16.NP1.100MHz","log.tmp");
#my @files=("log.11","log.13","log.14","log.16","log.18","log.19","log.20","log.21","log.22");
$GL->{NFILES} = @files;

print "PGPLOT module version $PGPLOT::VERSION\n\n";
pgqinf("VERSION",$val,$len);
print "PGPLOT $val library\n\n";

my $dev='/xwin';
#my $dev='output.ps/vps';

$dev = "?" unless defined $dev; # "?" will prompt for device
#pgbegin(0,$dev,4,($GL->{NFILES})/4);
pgbegin(0,$dev,2,1);
pgbbuf();
pgsave();
#-----------------------------
for(my $i=0;$i<$GL->{NFILES};$i++){
    generate_a_graph($files[$i],$i);
}
#-----------------------------
pgunsa();
pgebuf();
pgend;    # Close plot



sub generate_a_graph{
    my ($fname)=shift;
    my ($gnum)=shift;
    my ($xp,$yp);
    my ($n0,$n1);
    ($n0,$xp,$yp)=&set_xy($fname);
    my @x0=@{$xp}; 
    my @y0=@{$yp};
    pgscf(2);                       # Set character font
    pgslw(2);
    pgsch(2.2);                     # Set character height
    pgenv(-8.0,-0.5,0,0.01,0,0);         # Define data limits and plot axes
    {
	my (undef,$title)=split(/\./,$fname);
	$title = $title . ' stages';
	pglabel("log(r/RMAX)","Sr","$title");    # Labels
    }
    pgsci(7);                       # Change colour
    pgpoint($n0,\@x0,\@y0,1);       # Plot points
    pgline($n0,\@x0,\@y0);          # Draw Lines
    pgsci(1);                       # Change colour(defualt)
}


#-----------------------------

sub set_xy{
    my ($fname) = shift;
    my @c_x=();
    my @c_y=();
    my $i=0;
    open(DATA,$fname);
    while(<DATA>){               
	# Read data in 2 columns from file handle
	# and put in two perl arrays
	my @cols = split("\t");
	$c_x[$i] = $cols[0];
	$c_y[$i] = $cols[1];
	$i++;
    }
    close(DATA);
    return($i,\@c_x,\@c_y);
}
