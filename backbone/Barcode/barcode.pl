# !/usr/bin/perl -w
#
# barcode.pl
# Written by: David B. Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: June 28, 2011
#################################################
#
#	Parameters:
#		-s sequences input
#		-b barcodes in txt file
#	Options:
#		-d directory of output
#		-m minimum number for normalizing
#
#################################################

use Getopt::Std;

#Organizes input
my %parameters;
$dir = "";
$minNorm = 100;
getopts('s:b:d:m:', \%parameters);					#Takes parameters

unless($parameters{s} && $parameters{b})
{
	print "Must enter at least the -s sequences and -b barcodes.\n";
	exit;
}

if($parameters{d})							#if directory is defined, it adds a directory to the files that will be created
{
	$dir = $parameters{d}."/";
}

if($parameters{m})							#if a minimum is defined, change the minimum number of sequences
{
	$minNorm = $parameters{m};
}

print "Opening $parameters{s}...";
system("perl -pi -e 's/\\r\\n|\\r/\\n/g' $parameters{s}");		#formats to UNIX newline characters
unless (open(SEQIN, $parameters{s}))       #tries to open file
{
	print "Unable to open $parameters{s}\nMake sure you entered the extension when entering the file name.";
	exit;
}
print "Successful.\nOpening $parameters{b}...";
system("perl -pi -e 's/\\r\\n|\\r/\\n/g' $parameters{b}");		#formats to UNIX newline characters
unless (open(BARIN, $parameters{b}))       #tries to open file
{
	print "Unable to open $parameters{b}\nMake sure you entered the extension when entering the file name.";
	exit;
}
@barcodes = ();								#will contain the barcodes
open_barcodes();							#processes the barcodes taking into account the newline characters and skipping empty lines; also creates the hash for barcode counts
create_files();

print "Successful.\nCreating Files...\n";

@storedLines = ();
$count = 0;
$countNoBar = 0;
$countNorm = 0;

while($line = <SEQIN>)
{
	if($line =~ />/)								#if new sequence, print previous sequence
	{
		chomp($line);
		$storeSize = scalar @storedLines;
		if($storeSize > 0)							#print if there is a sequence stored
		{
			find_and_print_barcode(@storedLines);
			@storedLines = ();
		}
		push(@storedLines, $line);
		$count++;
	}
	else
	{
		if($line ne "\n")							#if line is not empty, store
		{
			push(@storedLines, $line);
		}
	}
}
close SEQUIN;
find_and_print_barcode(@storedLines);
find_and_print_min();
print "Found $count sequences.\nFound $countNorm barcodes at the beginning.\nFound no barcodes in $countNoBar sequences.\n";
print_counts();
print "Finished!\n\n";

#######################################	  SUBROUTINES	#######################################
sub find_and_print_barcode()				#finds any barcode in the sequence and prints in the correct file.
{
	$heading = shift;
	$heading = substr($heading, 1);
	my $bar = "";
	$firstLine = shift;	
	foreach $barcode (keys %barcounts)
	{
		if($firstLine =~ /^$barcode/)		#if barcode is found at beginning
		{
			$bar = $barcode;
			last;
		}
	}
	
	if($bar ne "")
	{
		$num = $barnum{$bar};
		$countNorm++;
		$barcounts{$bar}++;
		$openNum = $num + 1;
		open BAR, ">>$dir"."bar$openNum.fas" or die $!; 
		print BAR ">$openNum"."_$heading\n";
		$barcodeLength = length($bar);
		$firstLine = substr($firstLine, $barcodeLength);
		print BAR "$firstLine";
		while($seqLine = shift)
		{
			print BAR "$seqLine";
		}
		close BAR;
	}
	else
	{
		$countNoBar++;
		open NOBAR, ">>$dir"."nobar.fas" or die $!;
		print NOBAR ">$heading\n";
		print NOBAR "$firstLine";
		while($seqLine = shift)
		{
			print NOBAR "$seqLine";
		}
		close NOBAR;
	}
}

sub open_barcodes()
{
	my $barLine = "";
	while($barLine = <BARIN>)
	{
		if($barLine =~ /[a-zA-Z]/)						#makes sure that it only adds lines with barcodes in them
		{
			push(@barcodes, $barLine);
		}
	}
	close BARIN;
	$barcodesSize = scalar @barcodes;
	
	for($a = 0; $a < $barcodesSize; $a++)
	{
		my $dex = index($barcodes[$a], "\t") + 1;
		$barcodes[$a] =~ s/\s+$//;								#Eliminate white space
		$barcodes[$a] =  uc substr($barcodes[$a], $dex, length($barcodes[$a]) - $dex);		#trimming the line down to the actual barcode
		$barnum{$barcodes[$a]} = $a;
	}
	%barcounts = map { $_ => 0 } @barcodes;								#create a hash to keep the barcode counts
}

sub find_and_print_min()
{
	my $min = 1;
	foreach (keys %barcounts)
	{
		if($barcounts{$_} > $minNorm)
		{
			if($min == 1)
			{
				$min = $barcounts{$_};
			}
			if($barcounts{$_} < $min)
			{
				$min = $barcounts{$_};
			}
		}
	}
	open MIN, ">$dir"."info.txt" or die $!;
	print MIN $min;
	close MIN;
}

sub print_counts()
{
	open COUNT, ">$dir"."barcode_counts.txt" or die $!;
	for($a = 0; $a < $barcodesSize; $a++)
	{
		my $num = $a + 1;
		print COUNT "$num"."\t"."$barcodes[$a]"."\t"."$barcounts{$barcodes[$a]}"."\n";	
	}
	close COUNT;
}

sub create_files()
{
	for($a = 1; $a <= $barcodesSize; $a++)
	{
		open BAR, ">$dir"."bar$a.fas" or die $!;
		close BAR;
	}
	open NOBAR, ">$dir"."nobar.fas" or die $!;
	close NOBAR;
}