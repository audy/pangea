# !/usr/bin/perl -w
#	
# megaclustable.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: June 28, 2010
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

$tax = $parameters{t} - 1;
@megaclustfiles = split(/,/, $parameters{m});
$count = 0;
%table = ();

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
	add_hash_to_table();
	close MEGA;
	
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
	#if that level of taxonomic name is not present in the taxonomy, skip it.
	if($index == 2)
	{
		return;
	}
	my $stop = index($line, ";", $index);
	my $comma = index($line, ",");
	if($stop < 0)
	{
		$stop = $comma;
	}
	my $name = substr($line, $index, $stop - $index);
	my $num = substr($line, $comma + 1);
	chomp($num);
	if(exists($file{$name}))
	{
		$file{$name} += $num;
	}
	else
	{
		$file{$name} = $num;
	}
}

sub add_hash_to_table()
{
	foreach $name (keys %table)
	{
		if(!(exists($file{$name})))
		{
			$table{$name} = $table{$name}."\t0";
		}
		else
		{
			$table{$name} = $table{$name}."\t".$file{$name};
			delete $file{$name};
		}
	}
	
	foreach $name (keys %file)
	{
		for($a = 0; $a < $count - 1; $a++)
		{
			$table{$name} = $table{$name}."0\t";
		}
		$table{$name} = $table{$name}.$file{$name};
	}
}


