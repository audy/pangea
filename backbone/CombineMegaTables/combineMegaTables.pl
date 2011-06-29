# !/usr/bin/perl -w
#	
# combineMegaTables.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: June 30, 2010
###########################################################################
#
#	Parameters:
#		-m megaclustables separated by commas (no spaces)
#		-o output file
#
#	Caution: The megaclustables must have the same number of 
#	barcodes, or else the script will give an error.
#
###########################################################################

use Getopt::Std;

my %parameters;
getopts('m:o:', \%parameters);

unless($parameters{m} && $parameters{o})
{
	print "Please enter the program with -m list of megaclustable files seperated by commas (no spaces) -o output table name.\n";
	exit;
}

$numBars = -1;
%taxa = ();
@megaclustables = split(/,/, $parameters{m});
foreach(@megaclustables)
{
	#tries to open file
	unless (open(MEGA, $_))
	{
		print "Unable to open $_\nMake sure you entered the extension when entering the file name.\n";
		exit;
	}
	$line = <MEGA>;
	check_Number_of_Barcodes($line);
	while($line = <MEGA>)
	{
		chomp($line);
		add_to_hash($line);
	}
	close MEGA;
}
printOut($parameters{o});

###############################################   SUBROUTINES   ###############################################
sub check_Number_of_Barcodes()
{
	my $line = shift;
	my @firstLine = split(/\t/, $line);
	if($numBars == -1)
	{
		$numBars = $firstLine[-1];
	}
	else
	{
		if($numBars != $firstLine[-1])
		{
			print "Number of barcodes in the tables do not match. Exiting...\n\n";
			exit;
		}
	}
}

sub add_to_hash()
{
	my $line = shift;
	@inputLine = split(/\t/, $line);
	if($taxa{$inputLine[0]})
	{
		#present, so add to existing
		@taxaLine = split(/\t/, $taxa{$inputLine[0]});
		for($a = 1; $a <= $numBars; $a++)
		{
			$taxaLine[$a] += $inputLine[$a];
		}
		$taxa{$inputLine[0]} = join  "\t", @taxaLine;
	}
	else
	{
		#not present already, so add new entry
		$taxa{$inputLine[0]} = $line;
	}
}

sub printOut()
{
	my $out = shift;
	open OUTPUT, ">$out" or die $!;
	for($a = 1; $a <= $numBars; $a++)
	{
		print OUTPUT "\t$a";
	}
	print OUTPUT "\n";
	foreach $name (keys %taxa)
	{
		print OUTPUT $taxa{$name}."\n";
	}
	close OUTPUT;
}