# !/usr/bin/perl -w
#	
# megaclustable.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: July 15, 2011
###########################################################################################
#
#	Parameters:
#		-m list of all megaclust output files seperated by commas (no spaces)
#		-t level of taxa that megaclust was run for where 1= domain and 7= species
#		-o output table name
#
###########################################################################################

use Getopt::Std;

my %parameters;
getopts('m:t:o:', \%parameters);

unless($parameters{m} && $parameters{t} && $parameters{o})
{
	print "Please enter the program with -m list of all megaclust output files seperated by commas (no spaces) -t taxa level -o output table name.\n";
	exit;
}

if($parameters{t} < 1 || $parameters{t} > 7)
{
	print "You entered the level of taxa as $parameters{t}. The level of taxa must be between 1 and 7, where 1 = domain and 7 = species.\n";
	exit;
}

$tax = $parameters{t} - 1;
@megaclustfiles = split(/,/, $parameters{m});
%table = ();
$count = 0;

foreach(@megaclustfiles)
{
	$count++;
	unless (open(MEGA, $_))       #tries to open file
	{
		print "Unable to open $_\nMake sure you entered the extension when entering the file name.\n";
		exit;
	}
	$line = <MEGA>;
	%file = ();
	
	while($line = <MEGA>)
	{
		if($line =~ /[$tax]/)
		{
			add_to_filehash();
		}
	}
	close MEGA;
	add_hash_to_table();
	
	open OUTPUT, ">$parameters{o}" or die $!;
	print_out();
	close OUTPUT;
	
}

###############################################   SUBROUTINES   ###############################################
sub print_out()
{
	for($a = 1; $a <= $count; $a++)
	{
		print OUTPUT "\t$a";
	}
	print OUTPUT "\n";
	foreach $name (keys %table)
	{
		print OUTPUT "$name\t$table{$name}\n";
	}
}

sub add_to_filehash()
{
	my $index = index($line, "[$tax]") + 3;
	my $comma = index($line, ",");
	my $num = substr($line, $comma + 1);
	chomp($num);
	
	if($index == 2)
	{
		if(exists($file{"null"}))								# If there is no taxonomic unit, put in "null category."
		{
			$file{"null"} += $num;
		}
		else
		{
			$file{"null"} = $num;
		}
	}
	else
	{
		my $stop = index($line, ";", $index);
		if($stop < 0)											# If this is the last taxonomic unit, a ";" won't be found
		{
			$stop = $comma;
		}
		my $name = substr($line, $index, $stop - $index);
		if(exists($file{$name}))
		{
			$file{$name} += $num;
		}
		else
		{
			$file{$name} = $num;
		}
	}
}

sub add_hash_to_table()
{
	foreach $name (keys %table)
	{
		if(!(exists($file{$name})))
		{
			$table{$name} = $table{$name}."\t0";				# If this file does not have this unit, set its count to 0
		}
		else
		{
			$table{$name} = $table{$name}."\t".$file{$name};	# Add the count of the unit to the list
			delete $file{$name};								# After unit has been added, remove from list
		}
	}
	
	foreach $name (keys %file)									# Add new taxonomic unit
	{
		for($a = 0; $a < $count - 1; $a++)						# Set all other files processed to 0 for this unit
		{
			$table{$name} = $table{$name}."0\t";
		}
		$table{$name} = $table{$name}.$file{$name};				# Add the count for the file for this unit at the end
	}
}


