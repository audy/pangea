# !/usr/bin/perl -w
#	
# shannon.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: May 25, 2010
#######################################################
#
#	Parameters:
#		-t hybrid table input file
#		-n number of samples
#		-o output name
#
#######################################################

use Getopt::Std;

my %parameters;
getopts('t:n:o:', \%parameters);

unless($parameters{t} && $parameters{n} && $parameters{o})
{
	print "Please enter the program with -t hybrid table input file -o output seqeunce file -n number of samples.\n";
	exit;
}
$num = $parameters{n};
$num++;

unless (open(INPUT, $parameters{t}))       #tries to open file
{
	print "Unable to open $parameters{t}\nMake sure you entered the extension when entering the file name.";
	exit;
}
@in = <INPUT>;
$inSize = scalar @in;
open OUT, ">$parameters{o}" or die $!;
for($a = 0; $a < $inSize; $a++)
{
	print OUT $in[$a];
}
print OUT "Shannon-Weaver Diversity Index H'(loge):";
for($b = 1; $b < $num; $b++)
{
	@data = ();
	for($c = 1; $c < $inSize; $c++)
	{
		@line = split(/\t/, $in[$c]);
		push(@data, $line[$b]);
		
	}
	$size = scalar @data;
	$sum = 0;
	$sum2 = 0;
	for($a = 0; $a < $size; $a++)
	{
		$sum += $data[$a];	
	}
	for($a = 0; $a < $size; $a++)
	{
		if($data[$a] != 0)
		{
			$data[$a] = $data[$a]/$sum;
			$data[$a] = $data[$a] * log($data[$a]);
			$sum2 += $data[$a];
		}
	}
	$sum2 = $sum2*(-1);
	$sum2 = sprintf("%.2f", $sum2);
	print OUT "\t$sum2";
}