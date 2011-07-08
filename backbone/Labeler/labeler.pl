# !/usr/bin/perl -w
#
# labeler.pl
# Written by: David B. Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: July 8, 2010
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
#
#################################################

use Getopt::Std;

#Organizes input
my %parameters;
$ETHRESHOLD = exp(-20);								# Default e-value upper threshold
$BTHRESHOLD = 200;									# Default bitscore lower threshold
$dir = "";											# Default output directory is the current directory

$printLoc = -1;
getopts('s:m:p:d:', \%parameters);					# Takes parameters

unless($parameters{s} && $parameters{m} && $parameters{p})
{
	print "Must enter the -s sequences file -m megablast result file and -p similarity level.\n";
	exit;
}

$extIndex = index($parameters{s}, ".") + 1;			# Determines the location of the "." of the extension of a file or returns 0 if it is not there
if($extIndex > 0)
{
	$out = substr($parameters{s}, 0, $extIndex);	# If there is an extension, take everything up until, but not including extension
}
else
{
	$out = $parameters{s};							# If there is no extension, no need to adjust
}	

$PTHRESHOLD = $parameters{p};						# Set the similarity level as defined by the user

if($parameters{e})									# If user defined a new e-value upper threshold
{
	$ethres = exp($parameters{e});
}

if($parameters{b})									# If user defined a new bitscore lower threshold
{
	$bthres = $parameters{b};
}

if($parameters{d})									# If user defined a new output directory
{
	$dir = "$parameters{d}";
}

unless (open(SEQIN, $parameters{s}))       			# Try to open file
{
	print "Unable to open $parameters{s}\nMake sure you entered the extension when entering the file name.";
	exit;
}
unless (open(MEGAIN, $parameters{m}))       		# Try to open file
{
	print "Unable to open $parameters{m}\nMake sure you entered the extension when entering the file name.";
	exit;
}

open CLASSOUT, ">$dir"."C_$out"."_$pthres.fas" or die $!;
open UNCLASSOUT, ">$dir"."U_$out"."_$pthres.fas" or die $!;
$megaLine = <MEGAIN>;
while($seqLine = <SEQIN>)
{
	if($seqLine =~ />/)								# If new sequence...
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