# !/usr/bin/perl -w
#
# CDclustable.pl
# Created by David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: June 30, 2010
#################################################################
#
#	Parameters:	
#		-c fas.clstr.clstr input file
#		-n number of samples
#		-o name of output file
#
#################################################################

use Getopt::Std;

my %parameters;
getopts('c:n:o:', \%parameters);

unless($parameters{c} && $parameters{n} && $parameters{o})
{
	print "Please enter the program with -c fas.clstr.clstr input file -n number of samples -o name of output file.\n";
	exit;
}

unless (open(INPUT, $parameters{c}))       #tries to open file
{
	print "Unable to open $parameters{c}\nMake sure you entered the extension when entering the file name.";
	exit;
}
open FILE, ">$parameters{o}" or die $!;

@samples = ();
$count = 0; 										#cluster number
$sampleSize = $parameters{n};

for($a = 0; $a < $sampleSize; $a++)				#Initialize empty columns
{
	unshift(@samples, "0");
}

while($input = <INPUT>)					#finds first cluster, so input starts after it
{
	if($input =~ /Cluster/)
	{
		last;
	}
}

while($input = <INPUT>)
{
	if($input =~ /Cluster/)					#If new cluster, print previous cluster information
	{
		print_Line();
		clear_samples();
		$count++;
	}
	else
	{
		count_and_check($input);
	}
}
print_Line();								#print last cluster information

close FILE;
close INPUT;

###############################################   SUBROUTINES   ###############################################
sub print_Line()							#prints cluster line
{
	$sampleText = "";
	for($a = 0; $a < $sampleSize; $a++)
	{
		$sampleText = $sampleText."\t".$samples[$a];
	}
	print FILE "$count\t$ID"."$sampleText\n";
}

sub clear_samples()							#clears samples for new cluster
{
	foreach(@samples)
	{
		$_ = 0;
	}
}

sub count_and_check()						#checks normal cluster line
{
	my ($line) = @_;

	$index = index($line, ">") + 1;
	if($index > 0)
	{
		$dex = index($line, "_");
		$num = substr($line, $index, $dex - $index);
		$samples[$num - 1]++;
	}
	
	if($line =~ /\*/)
	{
		$index--;
		$dex = index($line, ".");
		$ID = substr($line, $index, $dex - $index);
	}
}