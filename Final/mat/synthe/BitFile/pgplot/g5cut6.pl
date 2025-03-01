#!/usr/bin/perl  

use PGPLOT;  # Load PGPLOT module

my $GL;
my @files=("log.11","log.13","log.14","log.16","log.18","log.19","log.20","log.21","log.22","log.23","log.27");
#my @files=("log.11","log.13","log.14","log.16","log.18","log.19","log.20","log.21","log.22");
$GL->{NFILES} = @files;

print "PGPLOT module version $PGPLOT::VERSION\n\n";
pgqinf("VERSION",$val,$len);
print "PGPLOT $val library\n\n";

my $dev='/xwin';
#my $dev='output.ps/vps';

$dev = "?" unless defined $dev; # "?" will prompt for device
#pgbegin(0,$dev,4,($GL->{NFILES})/4);
pgbegin(0,$dev,3,4);
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
    pgenv(0,133,0,300,0,0);         # Define data limits and plot axes
    {
	my (undef,$title)=split(/\./,$fname);
	$title = $title . ' stages';
	pglabel("MHz","Gflop/s","$title");    # Labels
    }
    pgsci(7);                       # Change colour
    pgpoint($n0,\@x0,\@y0,8);       # Plot points
    pgline($n0,\@x0,\@y0);          # Draw Lines
    pgsci(1);                       # Change colour(defualt)
}


#-----------------------------

sub set_xy{
    my ($fname) = shift;
    my @c_fmax=();
    my @c_npip=();
    my $i=0;
    open(DATA,$fname);
    while(<DATA>){               
	# Read data in 2 columns from file handle
	# and put in two perl arrays
	my @cols = split("\t");
	$c_fmax[$i] = $cols[0];
	{
	    my $fmax;
	    if($cols[0] == 33)     {$fmax=100.0 / 3.0;}
	    elsif($cols[0] == 50){$fmax=50.0;}
	    elsif($cols[0] == 66){$fmax= 100.0 * 2.0 / 3.0;}
	    elsif($cols[0] == 83){$fmax= 100.0 * 5.0 / 6.0;}
	    elsif($cols[0] ==100){$fmax= 100.0;}
	    elsif($cols[0] ==117){$fmax= 100.0 * 7.0 / 6.0;}
	    elsif($cols[0] ==133){$fmax= 100.0 * 4.0 / 3.0;}
	    else{ print STDERR "error\n"; exit(0);}
	    $c_npip[$i] = $cols[1]*$fmax*(4.0)*(38.0)*(0.001);
	}
	$i++;
    }
    close(DATA);
    return($i,\@c_fmax,\@c_npip);
}
