# !/usr/bin/perl -w
#
# barcode.pl
# Written by: David B. Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: June 30, 2011
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
@barcodes = ();								# Will contain the barcodes
@barNames = ();								# Will contain the barcode names
@storedLines = ();							# Used for processing the input sequence file
$count = 0;									# Counts the total number of sequences
$countNoBar = 0;							# Counts the number of sequences with no barcode
$countNorm = 0;								# Counts the number of sequences with barcode found

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
open_barcodes();							# Processes the barcodes, skipping empty lines; also creates the hash for barcode counts

print "Successful.\nCreating Files...\n";
create_files();								# Creates the output files

while($line = <SEQIN>)
{
	if($line =~ />/)								# If new sequence, print previous sequence
	{
		chomp($line);
		$storeSize = scalar @storedLines;
		if($storeSize > 0)							# Print if there is a sequence stored
		{
			find_and_print_barcode(@storedLines);	
			@storedLines = ();						# Resets @storedLines to prepare for the next sequence
		}
		push(@storedLines, $line);					# Stores the header first
		$count++;									# Marks that we have found another sequence
	}
	else
	{
		if($line ne "\n")							# If line has some letters in it, store
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
sub create_files()
{
	for($a = 0; $a < $barcodesSize; $a++)
	{
		open BAR, ">$dir"."$barNames[$a].fas" or die $!;
		close BAR;
	}
	open NOBAR, ">$dir"."nobar.fas" or die $!;
	close NOBAR;
}

sub find_and_print_barcode()								# Finds any barcode in the sequence and prints in the correct file.
{
	my $bar = "";
	my $heading = shift;
	my $firstLine = shift;
	$heading = substr($heading, 1);							# Removes ">" character
	foreach $barcode (keys %barcounts)						# Iterates through barcodes
	{
		if($firstLine =~ /^$barcode/)						# If barcode is found at beginning
		{
			$bar = $barcode;
			last;											# End the search if barcode matches at beginning of sequence, that is perfect
		}
	}
	
	if($bar ne "")											# If a barcode is matched, i.e. $bar has been changed from ""
	{
		$num = $barnum{$bar};
		$countNorm++;										# A normal, matching barcode has been found
		$barcounts{$bar}++;									# Add one to this barcode's total
		open BAR, ">>$dir"."$barName[$num].fas" or die $!; 
		print BAR ">$barName[$num]"."_$heading\n";
		$barcodeLength = length($bar);
		$firstLine = substr($firstLine, $barcodeLength);	# Removes the first $barcodeLength characters, which is the barcode
		print BAR "$firstLine";
		while($seqLine = shift)
		{
			print BAR "$seqLine";
		}
		close BAR;
	}
	else													# No matching barcode was found
	{
		$countNoBar++;										# Count it!
		open NOBAR, ">>$dir"."nobar.fas" or die $!;			# Add it to the no barcode file
		print NOBAR ">$heading\n";
		print NOBAR "$firstLine";
		while($seqLine = shift)
		{
			print NOBAR "$seqLine";
		}
		close NOBAR;
	}
}

sub find_and_print_min()
{
	my $min = -1;
	foreach (keys %barcounts)
	{
		if($barcounts{$_} > $minNorm)						# If the number of barcodes is greater than the minimum normalizing amount
		{
			if($min == -1)									# If no minimum has been found yet, then this number of sequences is the new minimum
			{
				$min = $barcounts{$_};
			}
			if($barcounts{$_} < $min)						# If this number of sequences is smaller than the current minimum, then it is the new minimum
			{
				$min = $barcounts{$_};
			}
		}
	}
	open MIN, ">$dir"."info.txt" or die $!;					# Print the minimum so it can be read by PANGEA
	print MIN $min;
	close MIN;
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
		my @split_Line = split(/\t/, $barcodes[$a]);
		$split_Line[0] =~ s/\s+$//;						# Eliminate white space from barcode name
		push(@barNames, $split_Line[0]);
		$barcodes[$a] = $split_Line[1];
		$barcodes[$a] =~ s/\s+$//;						# Eliminate white space from barcode
		$barnum{$barcodes[$a]} = $a;					# Keeps track of what number the barcode is
	}
	%barcounts = map { $_ => 0 } @barcodes;								#create a hash to keep the barcode counts
}

sub print_counts()
{
	open COUNT, ">$dir"."barcode_counts.txt" or die $!;
	for($a = 0; $a < $barcodesSize; $a++)
	{
		print COUNT "$barNames[$a]\t$barcodes[$a]\t$barcounts{$barcodes[$a]}"."\n";	
	}
	close COUNT;
}