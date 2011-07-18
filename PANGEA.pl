#!/usr/bin/perl

use warnings;

use File::Path;
use File::Copy;
use Getopt::Std;

rmtree(PANGEA_Output);

#Defaults
$LEN = 100;
$QUAL = 20;
$PRO = 1;
@cutoffs = (80, 90, 95, 99);
@thresholds = (0, 0, 1, 1, 1, 2, 3);
@classifications = (Domain, Phylum, Class, Order, Family, Genus, Species);

#Checks the operating system PANGEA is being run on, and makes the necessary adjustments
check_OS();

#Read settings file and organize settings
read_Settings();

#Organizes input
my %parameters;
getopts('s:q:b:d:u:h', \%parameters);
if($parameters{h})
{
	print_summary();
	exit;
}
unless($parameters{s} && $parameters{q} && $parameters{b} && $parameters{d} && $parameters{u})
{
	print_summary();
	exit;
}

$barNum = count_barcodes($parameters{b});			
mkdir("PANGEA_Output");
mkdir("PANGEA_Output/1.3_Trim2");

print "\n...Running Trim2.pl...\n\n";
system "perl backbone/Trim2/Trim2.pl -s $parameters{s} -q $parameters{q} -o PANGEA_Output/1.3_Trim2/Trimmed.fas -l $LEN -m $QUAL";

$input = "PANGEA_Output/1.3_Trim2/Trimmed.fas";

mkdir("PANGEA_Output/1.4_barcode");
if($parameters{b} eq "n")
{
	copy($input, "PANGEA_Output/1.4_barcode/bar1.fas");
}
else
{
	print "\n...Running barcode.pl...\n\n";
	system "perl backbone/Barcode/barcode.pl -s $input -b $parameters{b} -d PANGEA_Output/1.4_barcode";
}

print "\n...Prepping Isolates Database for Megablast...\n\n";
system "backbone/Megablast/bin/formatdb_$opsys -i $parameters{d} -p F -o F";
mkdir("PANGEA_Output/1.5_Megablast");
run_megablast($parameters{d}, "b");

mkdir("PANGEA_Output/2.3_labeler");
run_labeler("c", @cutoffs);

print "\n...Prepping \"All\" database for Megablast...\n\n";
system "backbone/Megablast/bin/formatdb_$opsys -i $parameters{u} -p F -o F";
mkdir("PANGEA_Output/2.4a_Megablast");
run_megablast($parameters{u}, "u", @cutoffs);
mkdir("PANGEA_Output/2.4b_labeler");
run_labeler("u", @cutoffs);
mkdir("PANGEA_Output/2.4c_megaclust");
run_megaclust("u", @cutoffs);
mkdir("PANGEA_Output/2.4d_megaclustable");
run_megaclustable("2.4c_megaclust", "2.4d_megaclustable", @cutoffs);
concat_labeler(@cutoffs);
mkdir("PANGEA_Output/2.4e_CD-HIT");
run_CDHIT("2.4b_labeler/AllUnclassifiedU", "2.4e_CD-HIT/AllUnclassifiedU", @cutoffs);
mkdir("PANGEA_Output/2.4f_CDclustable");
run_CDclustable("2.4e_CD-HIT", "2.4f_CDclustable", "U", @cutoffs);
mkdir("PANGEA_Output/2.5a_megaclust");
run_megaclust("b", "1.5_megablast", "2.5a_megaclust", @cutoffs);
mkdir("PANGEA_Output/2.5b_megaclustable");
run_megaclustable("2.5a_megaclust", "2.5b_megaclustable", @cutoffs);
mkdir("PANGEA_Output/2.6a_combinedTables");
run_combineMegaTables();
mkdir("PANGEA_Output/2.6b_hybridtable");
run_hybridtable("2.6a_combinedTables", "2.4f_cdclustable", "2.6b", @cutoffs);

mkdir("PANGEA_Output/3.1_selector");
run_selector();

mkdir("PANGEA_Output/3.3_Unclas_Sel");
run_unclassSelector(@cutoffs);
concat_unclas_sel(@cutoffs);

mkdir("PANGEA_Output/3.4_CD-HIT");
run_CDHIT("3.3_Unclas_Sel/allUnclassified", "3.4_CD-HIT/AllUnclassified", @cutoffs);
mkdir("PANGEA_Output/3.4_CDclustable");
run_CDclustable("3.4_CD-HIT", "3.4_CDclustable", "", @cutoffs);

mkdir("PANGEA_Output/3.5_Megaclust");
run_megaclust("b", "3.1_selector", "3.5_Megaclust", @cutoffs);
mkdir("PANGEA_Output/3.5_Megaclustable");
run_megaclustable("3.5_Megaclust", "3.5_Megaclustable", @cutoffs);

mkdir("PANGEA_Output/3.6_HybridTable");
run_hybridtable("3.5_Megaclustable", "3.4_CDclustable", "3.6", @cutoffs);

mkdir("PANGEA_Output/3.7_Shannon");
run_shannon(@classifications);

print "\nFinished!\n\n";

###############################################   SUBROUTINES   ###############################################
sub print_summary()			#summarizes the parameters
{
	$summary = "\nParameters:
	-s .fas raw sequence input file
	-q .fas.qual quality input file
	-b .txt file containing barcodes or put \"n\" for no barcodes
	-d tax collector \"isolates only\" database file
	-u tax collector \"all\" database file
	-h input help

	Caution: PANGEA.pl deletes the directory 
	PANGEA_Output every time it runs, make sure
	you retreive all files from that directory
	before you run again!";
	print $summary."\n\n";
}

sub count_barcodes()			#counts and returns barcodes
{
	my ($barInput) = @_;
	
	if($barInput eq "n")
	{
		return 1;					#No barcodes
	}
	
	unless (open(BARCODE, $barInput))       #tries to open file
	{
		print "Unable to open $barInput\nMake sure you entered the extension when entering the file name.\n";
		exit;
	}
	
	my $count = 0;
	my $line = "";
	while($line = <BARCODE>)
	{
		if($line =~ /[a-zA-Z]/)
		{
			$count++;
		}
		if(($line =~ /\r/) && !($line =~ /\n/))
		{
			@lines = split(/\r/, $line);
			$linesize = scalar @lines;
			for($e = 1; $e < $linesize; $e++)
			{
				if($lines[$e] =~ /[a-zA-Z]/)
				{
					$count++;
				}
			}
			break;
		}
	}
	return $count;
}

sub run_megablast()			#runs megablast
{
	print "\n...Running Megablast...\n\n";
	my $inputDB = shift;
	my $type = shift;
	if($type eq "u")		#unclassified branch
	{
		foreach(@_)
		{
			for($a = 1; $a <= $barNum; $a++)
			{
				system "backbone/Megablast/bin/megablast_$opsys -d $inputDB -i PANGEA_Output/2.3_labeler/bar$a"."_unclass$_".".fas -o PANGEA_Output/2.4a_Megablast/bar$a"."_$_"."_megablast.txt -a $PRO -v 1 -b 1 -m 8";
			}
		}
	}
	elsif($type eq "b")		#barcoded input
	{
		for($a = 1; $a <= $barNum; $a++)
		{
			system "backbone/Megablast/bin/megablast_$opsys -d $inputDB -i PANGEA_Output/1.4_barcode/bar$a".".fas -o PANGEA_Output/1.5_Megablast/bar$a"."_megablast.txt -a $PRO -v 1 -b 1 -m 8";
		}
	}
}

sub run_labeler()			#runs labeler
{
	print "\n...Running labeler...\n\n";
	my $type = shift;

	if($type eq "u")
	{
		foreach(@_)
		{
			for($a = 1; $a <= $barNum; $a++)
			{
				system "perl backbone/Labeler/labeler.pl -s PANGEA_Output/2.3_labeler/bar$a"."_unclass$_.fas -m PANGEA_Output/2.4a_megablast/bar$a"."_$_"."_megablast.txt -p $_ $extraIn-d PANGEA_Output/2.4b_labeler/bar$a"."_ -o U";
			}	
		}
	}
	else
	{
		foreach(@_)
		{
			for($a = 1; $a <= $barNum; $a++)
			{
				system "perl backbone/Labeler/labeler.pl -s PANGEA_Output/1.4_barcode/bar$a.fas -m PANGEA_Output/1.5_megablast/bar$a"."_megablast.txt -p $_ -d PANGEA_Output/2.3_labeler/bar$a"."_";
			}
		}
	}
}

sub concat_labeler()			#concatenation functions after labeling
{
	print "\n...Concatenating Files...\n\n";
	for($a = 1; $a <= $barNum; $a++)		#for each barcode
	{		
		foreach(@_)				#for each threshold
		{
			concatenate("PANGEA_Output/2.3_labeler/bar$a"."_class$_".".fas", "PANGEA_Output/2.3_labeler/AllClassified$_".".fas");
			concatenate("PANGEA_Output/2.4b_labeler/bar$a"."_classU$_".".fas", "PANGEA_Output/2.4b_labeler/AllClassifiedU$_".".fas");
			concatenate("PANGEA_Output/2.4b_labeler/bar$a"."_unclassU$_".".fas", "PANGEA_Output/2.4b_labeler/AllUnclassifiedU$_".".fas");
		}
	}
}

sub run_unclassSelector()		#runs unclassified selector for each threshold for each barcode
{
	print "\n...Running unclassified_selector...\n\n";
	foreach(@_)						#for each threshold
	{
		for($a = 1; $a <= $barNum; $a++)		#for each barcode
		{
			system "perl backbone/Unclas_Sel/unclassified_selector.pl -m PANGEA_Output/3.1_selector/bar$a"."_megablast.txt -s PANGEA_Output/3.1_selector/bar$a".".fas -t $_ -e -20 -b 200 -o PANGEA_Output/3.3_Unclas_Sel/bar$a"."_$_".".fas";
		}
	}
}

sub concat_unclas_sel()			#concatenates unclassified files from unclas_sel.pl for each threshold for each barcode
{
	print "\n...Concatenating Files...\n";
	foreach(@_)						#for each threshold
	{
		for($a = 1; $a <= $barNum; $a++)		#for each barcode
		{
			concatenate("PANGEA_Output/3.3_Unclas_Sel/bar$a"."_$_".".fas", "PANGEA_Output/3.3_Unclas_Sel/AllUnclassified$_".".fas");
		}
	}
}

sub run_CDHIT()				#runs CD-HIT for each of the concantenated files (each threshold)
{
	print "\n...Running CD-HIT...\n\n";
	my $inDir = shift;
	my $outDir = shift;
	foreach(@_)						#for each threshold
	{
		system "backbone/CD-HIT/cd-hit-est_$opsys -i PANGEA_Output/$inDir$_".".fas -o PANGEA_Output/$outDir$_".".fas.clstr -c 0.$_ -n 8 -g 1";
	}
}

sub run_CDclustable()			#runs CDclustable to combine CD-HIT files
{
	print "\n...Running CDclustable...\n\n";
	my $inDir = shift;
	my $outDir = shift;
	my $extra = shift;
	foreach(@_)						#for each threshold
	{
		system "perl backbone/CDclustable/CDclustable.pl -c PANGEA_Output/$inDir/AllUnclassified$extra"."$_".".fas.clstr.clstr -n $barNum -o PANGEA_Output/$outDir/AllUnclassified$_"."Table.txt";
	}
}

sub run_megaclust()			#runs megaclust for each threshold for each barcode
{
	print "\n...Running Megaclust...\n\n";
	my $type = shift;
	if($type eq "u")
	{
		foreach(@_)					#for each threshold
		{
			for($a = 1; $a <= $barNum; $a++)			#for each barcode
			{
					system "perl backbone/Megaclust/megaclust.pl -i PANGEA_Output/2.4a_megablast/bar$a"."_$_"."_megablast.txt -o PANGEA_Output/2.4c_megaclust/bar$a"."_$_"."_hits.txt -s $_";
			}
		}
	}
	else
	{
		my $inDir = shift;
		my $outDir = shift;
		foreach(@_)					#for each threshold
		{
			for($a = 1; $a <= $barNum; $a++)			#for each barcode
			{
					system "perl backbone/Megaclust/megaclust.pl -i PANGEA_Output/$inDir/bar$a"."_megablast.txt -o PANGEA_Output/$outDir/bar$a"."_$_"."_hits.txt -s $_";
			}
		}
	}
}

sub run_megaclustable()			#makes a table out of the megaclust output files
{
	print "\n...Running Megaclustable...\n\n";
	my $inDir = shift;
	my $outDir = shift;
	my @lists = ();
	
	#creating an empty input list for each threshold
	foreach(@_)
	{
		push(@lists, "");
	}
	my $size = scalar @_;
	
	#for each threshold
	for($b = 0; $b < $size; $b++)
	{
		#for each barcode
		for($a = 1; $a <= $barNum; $a++)		
		{
			$lists[$b] = "$lists[$b]PANGEA_Output/$inDir/bar$a"."_$_[$b]"."_hits.txt,";
		}
	}

	#runs megaclustable for each taxonomic level
	for($a = 0; $a < 7; $a++)
	{
		my $lev = $a + 1;
		system "perl backbone/Megaclustable/megaclustable.pl -m $lists[$thresholds[$a]] -t $lev -o PANGEA_Output/$outDir/$classifications[$a]"."Table.txt";
	}
}

sub run_hybridtable()			#combines the megaclustables and cdclustables using hybridtable
{
	print "\n...Making Hybrid Tables...\n\n";
	my $inMega = shift;
	my $inCD = shift;
	my $outNum = shift;
	
	for($a = 0; $a < 7; $a++)			#for each taxonomic level
	{
		system "perl backbone/HybridTable/hybridtable.pl -m PANGEA_Output/$inMega/$classifications[$a]"."Table.txt -c PANGEA_Output/$inCD/AllUnclassified$_[$thresholds[$a]]"."Table.txt -o PANGEA_Output/$outNum"."_hybridtable/HybridTable$classifications[$a]".".txt";
	}
}

sub run_selector()			#normalizes the data using selector
{
	print "\n...Running selector.pl...\n\n";
	unless (open(INFO, "PANGEA_Output/1.4_barcode/info.txt"))       #tries to open file
	{
		print "Error opening info.txt.";
		exit;
	}

	my $min = <INFO>;					#smallest number of sequences in a barcode file as found by barcode.pl
	close INFO;
	for($a = 1; $a <= $barNum; $a++)
	{
		system "perl backbone/Selector/selector.pl -i PANGEA_Output/1.4_barcode/bar$a".".fas -m PANGEA_Output/1.5_Megablast/bar$a"."_megablast.txt -o PANGEA_Output/3.1_selector/bar$a".".fas -n PANGEA_Output/3.1_selector/bar$a"."_megablast.txt -s $min";
	}
}

sub run_shannon()			#performs Shannon analysis
{
	print"\n...Performing Shannon Diversity Anaylsis...\n\n";
	foreach(@_)
	{
		system "perl backbone/Shannon/shannon.pl -t PANGEA_Output/3.6_HybridTable/HybridTable$_".".txt -n $barNum -o PANGEA_Output/3.7_Shannon/Shannon$_"."Table.txt";
	}
}

sub read_Settings()			#read settings.txt
{
	if(open(SETTINGS, "backbone/settings.txt"))       #tries to open file
	{
		while($line = <SETTINGS>)
		{
			if(($line =~ /\r/) && !($line =~ /\n/))
			{
				@lines = split(/\r/, $line);
				break;
			}
			else
			{
				push(@lines, $line);
			}
		}
		chomp($LEN = $lines[0]);
		chomp($QUAL = $lines[1]);
		chomp($PRO = $lines[2]);
		@cutoffs = ();
		@thresholds = ();
		for($e = 3; $e < 10; $e++)
		{
			$found = "f";
			chomp($lines[$e]);
			$cutSize = scalar @cutoffs;
			for($f = 0; $f < $cutSize; $f++)
			{
				if($cutoffs[$f] eq $lines[$e])
				{
					push(@thresholds, $f);
					$found = "t";
					$f = $cutSize;
				}
			}
			if($found eq "f")
			{
				push(@thresholds, $cutSize);
				push(@cutoffs, $lines[$e]);
			}
		}
		close SETTINGS;
	}
}

sub check_OS()				#adjusts for the OS PANGEA is running on	
{
	my $OS = $^O;
	if($OS eq "darwin")
	{
		$opsys = "Mac";
	}
	elsif($OS eq "MSWin32")
	{
		$opsys = "Win.exe";
	}
	elsif($OS eq "linux")
	{
		$opsys = "Linux";
	}
}

sub run_combineMegaTables()
{
	print "\n...Combining Megaclustables...\n\n";
	my $numClass = scalar @classifications;
	for($a = 0; $a < $numClass; $a++)
	{
		system "perl backbone/combineMegaTables/combineMegaTables.pl -m PANGEA_Output/2.4d_megaclustable/$classifications[$a]Table.txt,PANGEA_Output/2.5b_megaclustable/$classifications[$a]Table.txt -o PANGEA_Output/2.6a_combinedTables/$classifications[$a]Table.txt";
	}
}

sub concatenate()			#combines files
{
	my $file = shift;
	my $addtoFile = shift;
	my $OS = $^O;
	if(($OS eq "darwin") || ($OS eq "linux"))
	{
		system "cat $file >> $addtoFile";
	}
	elsif($OS eq "MSWin32")
	{
		open FILE, ">$file" or die $!;
		open ADDTOFILE, ">>$addtoFile" or die $!;
		
		while($concatLine = <FILE>)
		{
			print ADDTOFILE "$concatLine";
		}
		
		close FILE;
		close ADDTOFILE;
	}
}