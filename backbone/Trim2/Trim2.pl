# !/usr/bin/perl -w
#
# Trim2.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: June 4, 2010
#################################################
#
#	Parameters:
#		-s input sequence file name
#		-q input qual file name
#		-o output file name
#	Options:
#		-l minimum length (default 100)
#		-m minimum quality (default 20)
#
#################################################

use Getopt::Std;

#DEFAULT VALUES
$lengthCut = 100;
$qualityCut = 20;

#Organizes input
my %parameters;
getopts('s:q:o:l:m:', \%parameters);
unless($parameters{s} && $parameters{q} && $parameters{o})
{
	print "Please make sure that you are entering the correct parameters.\n";
	exit;
}
if($parameters{l})
{
	$lengthCut = $parameters{l};
}
if($parameters{m})
{
	$qualityCut = $parameters{m};
}

print "Opening $parameters{s}...";
unless (open(INPUTSEQ, $parameters{s}))       #tries to open Sequence file
{
	print "Unable to open $parameters{s}\nMake sure you entered the extension when entering the file name.";
	exit;
}
system("perl -pe 's/\\r\\n|\\n|\\r/\\n/g'   $parameters{s} > $parameters{s}");	  # Convert to UNIX format
print "Successful.\nOpening $parameters{q}...";
unless(open(INPUTQUAL, $parameters{q}))		#tries to open Qual file
{
	print "Unable to open $parameters{q}\nMake sure you entered the extension when entering the file name.";
	exit;
}

print "Successful.\nTrimming and Writing File...";

open OUTPUT, ">$parameters{o}" or die $!;
$Rejected = -1;
@FinalTrim = ();
$end = 0;
$max = 0;
$sum = 0;
$start = 0;
$first = 0;
$lineNum = 0;
while($lineSeq = <INPUTSEQ>)
{
	$lineQual = <INPUTQUAL>;
	if($lineSeq =~ />/)
	{
		$length = ($end + 1) - $start;
		if($length < $lengthCut)
		{
			$Rejected = 1;
		}
		if($Rejected == 0)
		{
			print_Trimmed_Seq()
		}
		$Rejected = 0;
		
		#Trim off heading
		$space = index($lineSeq, " ") + 1;
		$header = substr($lineSeq, 0, $space);
		@FinalTrim = ();
		$max = 0;
		$sum = 0;
		$first = 0;
		$lineNum = 0;
	}
	elsif($Rejected == 0)
	{
		#Store for use when trimming bases
		chomp($lineSeq);
		@bases = split(//, $lineSeq);
		$size  = scalar @bases;
		for($a = 0; $a < $size; $a++)
		{
			push(@FinalTrim, $bases[$a]);
		}
		chomp($lineQual);
		@line = split(/ /, $lineQual);
		$size = scalar @line;
		for($a = 0; $a < $size; $a++)
		{
			$sum += ($line[$a] - $qualityCut);
			if($sum > $max)
			{
				$max = $sum;
				$end = $a + (60*$lineNum);
				$start = $first;
			}
			if($sum < 0)
			{
				$sum = 0;
				$first = $a + 1 + (60*$lineNum);
			}
		}
		$lineNum++;
	}
}
$length = ($end + 1) - $start;
if($length < $lengthCut)
{
	$Rejected = 1;
}
if($Rejected == 0)
{
	print_Trimmed_Seq()
}
print "Successful.\nFinished!\n";
close INPUTSEQ;
close INPUTQUAL;
close OUTPUT;

##########################################   SUBROUTINES   ##########################################
sub print_Trimmed_Seq()
{
	print OUTPUT "$header";
	print OUTPUT "\n";
	
	$countDown = 60;
	for($a = $start; $a <= $end; $a++)
	{
		$countDown--;
		print OUTPUT "$FinalTrim[$a]";
		if($countDown == 0)
		{
			print OUTPUT "\n";
			$countDown = 60;
		}
	}
	print OUTPUT "\n";
}
