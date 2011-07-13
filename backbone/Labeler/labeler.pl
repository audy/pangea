# !/usr/bin/perl -w
#
# labeler.pl
# Written by: David B. Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: July 13, 2011
#####################################################
#
#	Parameters:
#		-s sequences input
#		-m megablast result
#		-p similarity level
#	Optional:
#		-e e-value upper threshold (DEFAULT: -20)
#		-b bitscore lower threshold (200)
#		-d directory of output
# 		-o base output name
# 		-l number of times input analyzed by labeler
#
#####################################################

use Getopt::Std;

#Organizes input
my %parameters;
$ETHRESHOLD = exp(-20);								# Default e-value upper threshold
$BTHRESHOLD = 200;									# Default bitscore lower threshold
$dir = "";											# Default output directory is the current directory

$printLoc = -1;										# Will tell the script which file to print a sequence in. Unclassified = 0, Classified = 1
getopts('s:m:p:o:d:e:b:l:', \%parameters);			# Takes parameters

unless($parameters{s} && $parameters{m} && $parameters{p})
{
	print "Must enter the -s sequences file -m megablast result file and -p similarity level.\n";
	exit;
}	

$extIndex = index($parameters{s}, ".");				# Determines the location of the "." of the extension of a file or returns -1 if it is not there
if($extIndex > 0)
{
    $out = substr($parameters{s}, 0, $extIndex);	# If there is an extension, take everything up until, but not including extension
}
else
{
    $out = $parameters{s};							# If there is no extension, no need to adjust
}

if($parameters{o})
{
	$out = $parameters{o};							# Set the base output name as defined by the user
}

$PTHRESHOLD = $parameters{p};						# Set the similarity level as defined by the user

if($parameters{e})									# If user defined a new e-value upper threshold
{
	$ETHRESHOLD = exp($parameters{e});
}

if($parameters{b})									# If user defined a new bitscore lower threshold
{
	$BTHRESHOLD = $parameters{b};
}

if($parameters{d})									# If user defined a new output directory
{
	$dir = "$parameters{d}";
}

$num_labeled = -1;
if($parameters{l})
{
	$num_labeled = $parameters{l};
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

open CLASSOUT, ">$dir"."C$PTHRESHOLD"."_$out.fas" or die $!;
open UNCLASSOUT, ">$dir"."U$PTHRESHOLD"."_$out.fas" or die $!;
$megaLine = <MEGAIN>;
while($seqLine = <SEQIN>)
{
	if($seqLine =~ />/)								# If new sequence...
	{
		$seqLine =~ s/\s+$//;						# Removes white space
		$seqName = substr($seqLine, 1);				# Removes ">" character
		
		if($num_labeled > 0)
		{
			$start = $num_labeled * 4;				# Will skip the labels
			$seqName = substr($seqLine, $start);
		}
		
		@megaName = split("\t", $megaLine);			# Split the megablast output file up
		if($seqName eq $megaName[0])
		{
			$seqName = substr($seqLine, 1);			# Restores the labels for further labeling
			if($megaName[2] < $PTHRESHOLD || $megaName[10] > $ETHRESHOLD || $megaName[11] < $BTHRESHOLD)
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
	print UNCLASSOUT ">U$PTHRESHOLD"."_$seqName\n";
}

sub printC()
{
	print CLASSOUT ">C$PTHRESHOLD"."_$seqName\n";
}