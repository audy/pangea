# !/usr/bin/perl -w
#	
# Change_Settings.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: May 17,2010
###########################################################################
#
#	Parameters:
#		-run the script, and it will prompt you for changes
#
###########################################################################

### DEFAULTS ###
$LEN = 100;
$QUAL = 20;
$PRO = 1;
$DOM = 80;
$PHY = 80;
$CLA = 90;
$ORD = 90;
$FAM = 90;
$GEN = 95;
$SPE = 99;

if(open(SETTING, "backbone/settings.txt"))       #tries to open file
{
	read_Settings();
	close SETTING;
}

do
{
	print "\n	Please enter the letter of the setting you would like to change,
	then you will be given information about the setting and you will be 
	prompted for a value.
	
	Trim2
		-l minimum length of sequences			(CURRENT: $LEN)
		-q minimum quality of sequences			(CURRENT: $QUAL)
	Megablast
		-n number of processors in your computer 	(CURRENT: $PRO)
	Classification
		-d minimum % similarity for Domain 		(CURRENT: $DOM%)
		-p minimum % similarity for Phylum 		(CURRENT: $PHY%)
		-c minimum % similarity for Class 		(CURRENT: $CLA%)
		-o minimum % similarity for Order		(CURRENT: $ORD%)
		-f minimum % similarity for Family		(CURRENT: $FAM%)
		-g minimum % similarity for Genus		(CURRENT: $GEN%)
		-s minimum % similarity for Species		(CURRENT: $SPE%)
	Defaults	
		-z restore all settings to defaults
		
	Type \"quit\" and press enter to quit.
	
	Please enter the letter and press enter:";
	
	chomp($input = <>);					#takes user input

	if($input eq "l" || $input eq "-l")
	{
		change_length();
	}
	elsif($input eq "q" || $input eq "-q")
	{
		change_quality();
	}
	elsif($input eq "n" || $input eq "-n")
	{
		change_processors();
	}
	elsif($input eq "d" || $input eq "-d")
	{
		change_tax("Domain", $DOM);
	}
	elsif($input eq "p" || $input eq "-p")
	{
		change_tax("Phylum", $PHY);
	}
	elsif($input eq "c" || $input eq "-c")
	{
		change_tax("Class", $CLA);
	}
	elsif($input eq "o" || $input eq "-o")
	{
		change_tax("Order", $ORD);
	}
	elsif($input eq "f" || $input eq "-f")
	{
		change_tax("Family", $FAM);
	}
	elsif($input eq "g" || $input eq "-g")
	{
		change_tax("Genus", $GEN);
	}
	elsif($input eq "s" || $input eq "-s")
	{
		change_tax("Species", $GEN);
	}
	elsif($input eq "z" || $input eq "-z")
	{
		restore_defaults();
	}
}	until $input eq "quit" || $input eq "Quit";
system('clear');

###############################################   SUBROUTINES   ###############################################
sub save()					#Saves all settings to file
{
	open OUTPUT, ">backbone/settings.txt" or die $!;
	print OUTPUT "$LEN\n$QUAL\n$PRO\n$DOM\n$PHY\n$CLA\n$ORD\n$FAM\n$GEN\n$SPE\n";
	close OUTPUT;
}

sub change_length()				#Change minimum length for trimming (trim2.pl)
{
	system("clear");
	print"	Trim2 throws out sequences that are too short. The default setting 
	is to throw out sequences that are less than 100 bases long. The
	current setting is $LEN".".\n\n\tPlease type the length you want to be the new minimum or \"n\" if 
	you don't want to change anything and press enter:";
	my $newLen = "";
	my $loop = "true";
	while($loop eq "true")
	{
		chomp($newLen = <>);
		if($newLen eq "n")
		{
			$loop = "false";
		}
		elsif($newLen  =~ /[a-zA-Z]/ || $newLen < 1)
		{
			print "\n\tPlease type a positive number only or \"n\"if you don't want to change anything:"
		}
		else
		{
			$loop = "false";
			print "You have chosen the new minimum length to be $newLen.\nSaving...";
			$LEN = $newLen;
			save();
			print "done.\n\n";
		}
	}
}

sub change_quality()
{
	system("clear");
	print"	Trim2 throws out sequences that are too short. Trim2 utilizes quality 
	scores to measure the quality of each nucleotide base. It trims 
	sequences based on average quality scores. The higher the minimum 
	quality, the more strict the program will be with sequences. The 
	current setting is $QUAL".".\n\n\tPlease type the length you want to be the new minimum or \"n\" if 
	you don't want to change anything and press enter:";
	my $newQual = "";
	my $loop = "true";
	while($loop eq "true")
	{
		chomp($newQual = <>);
		if($newQual eq "n")
		{
			$loop = "false";
		}
		elsif($newQual =~ /[a-zA-Z]/ || $newQual < 1)
		{
			print "\n\tPlease type a positive number only or \"n\"if you don't want to change anything:"
		}
		else
		{
			$loop = "false";
			print "You have chosen the new minimum quality to be $newQual.\nSaving...";
			$QUAL = $newQual;
			save();
			print "done.\n\n";
		}
	}
}

sub change_processors()
{
	system("clear");
	print "	Megablast runs significantly quicker if it can use more processors. 
	Using all of your processors would make Megablast and therefore PANGEA
	run at its optimum speed. The current setting is $PRO processors.\n\n\t Please type the number of processors you want to use or \"n\" if
	you don't want to change anything and press enter:";
	my $newPro = "";
	my $loop = "true";
	while($loop eq "true")
	{
		chomp($newPro = <>);
		if($newPro eq "n")
		{
			$loop = "false";
		}
		elsif($newPro =~ /[a-zA-Z]/ || $newPro < 1)
		{
			print "\n\tPlease type a positive number only or \"n\"if you don't want to change anything:"
		}
		else
		{
			$loop = "false";
			print "You have chosen the new number of processors to be $newPro.\nSaving...";
			$PRO = $newPro;
			save();
			print "done.\n\n";
		}
	}
}

sub change_tax()
{
	system("clear");
	$tax = shift;
	print "\tSequences are classified at different taxonomic levels based on
	their percent similarties to existing sequences. The current
	thresholds are:
		Domain\t$DOM
		Phylum\t$PHY
		Class\t$CLA
		Order\t$ORD
		Family\t$FAM
		Genus\t$GEN
		Species\t$SPE
	Please enter a percent similarity that is less than or equal
	to more specific classifications and greater than or equal
	to less specific classifications or enter \"n\" if you don't
	want to change anything and press enter:";
	$loop = "true";
	while($loop eq "true")
	{
		chomp($newTax = <>);
		if($newTax eq "n")
		{
			$loop = "false";
		}
		elsif($newTax =~ /[a-zA-Z]/ || $newTax < 1)
		{
			print "\n\tPlease type a positive number only or \"n\"if you don't want to change anything:";
		}
		else
		{
			if($tax eq "Domain")
			{
				if($newTax <= $PHY)
				{
					print "The new Domain threshold is $newTax.\nSaving...";
					$DOM = $newTax;
					save();
					$loop = "false";
					print "done.\n";
				}
				else
				{
					print "\n\tMust be less than or equal to the phylum threshold:";
				}
			}
			elsif($tax eq "Phylum")
			{
				if($newTax >= $DOM && $newTax <= $CLA)
				{
					print "The new Phylum threshold is $newTax.\nSaving...";
					$PHY = $newTax;
					save();
					$loop = "false";
					print "done.\n";
				}
				else
				{
					print "\n\tMust be greater than or equal to the domain threshold and\n\tless than or equal to the class threshold:";
				}
			}
			elsif($tax eq "Class")
			{
				if($newTax >= $PHY && $newTax <= $ORD)
				{
					print "The new Class threshold is $newTax.\nSaving...";
					$CLA = $newTax;
					save();
					$loop = "false";
					print "done.\n";
				}
				else
				{
					print "\n\tMust be greater than or equal to the phylum threshold and\n\tless than or equal to the order threshold:";
				}
			}
			elsif($tax eq "Order")
			{
				if($newTax >= $CLA && $newTax <= $FAM)
				{
					print "The new Order threshold is $newTax.\nSaving...";
					$ORD = $newTax;
					save();
					$loop = "false";
					print "done.\n";
				}
				else
				{
					print "\n\tMust be greater than or equal to the class threshold and\n\tless than or equal to the family threshold:";
				}
			}
			elsif($tax eq "Family")
			{
				if($newTax >= $ORD && $newTax <= $GEN)
				{
					print "The new Family threshold is $newTax.\nSaving...";
					$FAM = $newTax;
					save();
					$loop = "false";
					print "done.\n";
				}
				else
				{
					print "\n\tMust be greater than or equal to the order threshold and\n\tless than or equal to the genus threshold:";
				}
			}
			elsif($tax eq "Genus")
			{
				if($newTax >= $FAM && $newTax <= $SPE)
				{
					print "The new Genus threshold is $newTax.\nSaving...";
					$GEN = $newTax;
					save();
					$loop = "false";
					print "done.\n";
				}
				else
				{
					print "\n\tMust be greater than or equal to the family threshold and\n\tless than or equal to the species threshold:";
				}
			}
			elsif($tax eq "Species")
			{
				if($newTax >= $GEN)
				{
					print "The new Species threshold is $newTax.\nSaving...";
					$SPE = $newTax;
					save();
					$loop = "false";
					print "done.\n";
				}
				else
				{
					print "\n\tMust be greater than or equal to the genus threshold:";
				}
			}
		}
	}
}

sub restore_defaults()				#restore defaults to all values
{
	$LEN = 100;
	$QUAL = 20;
	$PRO = 1;
	$DOM = 80;
	$PHY = 80;
	$CLA = 90;
	$ORD = 90;
	$FAM = 90;
	$GEN = 95;
	$SPE = 99;
	unlink("backbone/settings.txt");
}

sub read_Settings()					#read previous settings file
{
	chomp($LEN = <SETTING>);
	chomp($QUAL = <SETTING>);
	chomp($PRO = <SETTING>);
	chomp($DOM = <SETTING>);
	chomp($PHY = <SETTING>);
	chomp($CLA = <SETTING>);
	chomp($ORD = <SETTING>);
	chomp($FAM = <SETTING>);
	chomp($GEN = <SETTING>);
	chomp($SPE = <SETTING>);
}