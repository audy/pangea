# !/usr/bin/perl -w
#
# labeler.pl
# Written by: David B. Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: July 26, 2010
#################################################
#
#	Parameters:
#		-s sequences input
#		-m megablast result
#		-p similarity level
#	Optional:
#		-e e-value upper threshold (DEFAULT: -20)
#		-b bitscore lower threshold (200)
#		-d directory of output
#		-o additional output name
#
#################################################

use Getopt::Std;

#Organizes input
my %parameters;
$dir = "";
$out = "";
$printLoc = -1;
getopts('s:m:p:d:o:', \%parameters);				#Takes parameters

unless($parameters{s} && $parameters{m} && $parameters{p})
{
	print "Must enter the -s sequences file -m megablast result file and -p similarity level.\n";
	exit;
}

$pthres = $parameters{p};					# Setting the cutoff value to the thres variable

$ethres = exp(-20);
if($parameters{e})
{
	$ethres = exp($parameters{e});
}

$bthres = 200;
if($parameters{b})
{
	$bthres = $parameters{b};
}

if($parameters{d})
{
	$dir = "$parameters{d}";				#Sets directory, because we are not taking output file names for each file
}

if($parameters{o})							#Allows for the second labeling step, i.e., "classunclass or unclassunclass"
{
	$out = "$parameters{o}";
}

unless (open(SEQIN, $parameters{s}))       #tries to open file
{
	print "Unable to open $parameters{s}\nMake sure you entered the extension when entering the file name.";
	exit;
}
unless (open(MEGAIN, $parameters{m}))       #tries to open file
{
	print "Unable to open $parameters{m}\nMake sure you entered the extension when entering the file name.";
	exit;
}

open CLASSOUT, ">$dir"."class$out$pthres.fas" or die $!;
open UNCLASSOUT, ">$dir"."unclass$out$pthres.fas" or die $!;
$megaLine = <MEGAIN>;
while($seqLine = <SEQIN>)
{
	if($seqLine =~ />/)						#if new sequence...
	{
		@seqHeading = split("_", $seqLine);
		$size = scalar @seqHeading;
		$seqHeading[0] = $seqHeading[0]."_";					#adds original underscore since it just split
		$seqHeading[$size - 1] = "_".$seqHeading[$size -1];		#adds extra underscore
		
		$seqDex = index($seqLine, "\n") - 2;
		$seqName = substr($seqLine, 1, $seqDex);

		@megaName = split("\t", $megaLine);						#split the megablast output file up
		if($seqName eq $megaName[0])
		{
			if($megaName[2] < $pthres || $megaName[10] > $ethres || $megaName[11] < $bthres)
			{
				printU();
				$printLoc = 1;
			}
			else
			{
				printC();
				$printLoc = 0;
			}
			$oldMega = $megaName[0];
			while($oldMega eq $megaName[0])
			{
				$megaLine = <MEGAIN>;				#Gets new line, only if the previous megablast result sequence was found and makes sure the new sequence has a different name
				@megaName = split("\t", $megaLine);						#split the megablast output file up
			}
		}
		else
		{
				printU();
				$printLoc = 1;
		}
	}
	else
	{
		if($printLoc == 0)
		{
			print CLASSOUT "$seqLine";
		}
		elsif($printLoc == 1)
		{
			print UNCLASSOUT "$seqLine";
		}
	}
}
close SEQIN;
close MEGAIN;
close CLASSOUT;
close UNCLASSOUT;

#######################################	  SUBROUTINES	#######################################
sub printU()
{
	print UNCLASSOUT $seqHeading[0]."U";
	for($a = 1; $a < $size; $a++)
	{
		print UNCLASSOUT "$seqHeading[$a]";
	}
}

sub printC()
{
	print CLASSOUT $seqHeading[0]."C";
	for($a = 1; $a < $size; $a++)
	{
		print CLASSOUT "$seqHeading[$a]";
	}
}