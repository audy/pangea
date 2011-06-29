# !/usr/bin/perl -w
#	
# hybridtable.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: July 1, 2010
###########################################################################################
#
#	Parameters:
#		-m megaclustable output file
#		-c cdclustable output file
#		-o output table name
#
###########################################################################################

use Getopt::Std;

my %parameters;
getopts('m:c:o:', \%parameters);

unless($parameters{m} && $parameters{c} && $parameters{o})
{
	print "Please enter the program with -m megaclustable output file -c cdclustable output file -o output table name.\n";
	exit;
}

unless (open(MEGAIN, $parameters{m}))       #tries to open file
{
	print "Unable to open $parameters{m}\nMake sure you entered the extension when entering the file name.";
	exit;
}
unless (open(CDIN, $parameters{c}))       #tries to open file
{
	print "Unable to open $parameters{c}\nMake sure you entered the extension when entering the file name.";
	exit;
}

open OUTPUT, ">$parameters{o}" or die $!;

while($line = <MEGAIN>)
{
	chomp($line);
	print OUTPUT $line."\n";
}
$a= 0;
while($line = <CDIN>)
{
	print OUTPUT "Cluster";
	$loc = index($line, "\t") + 1;
	print OUTPUT substr($line, 0, $loc);
	$loc = index($line, "\t", $loc) + 1;
	print OUTPUT substr($line, $loc);
}
close MEGIN;
close CDIN;
close OUTPUT;
