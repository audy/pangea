#!/usr/bin/perl -w
#
# chomp.pl
# Written by David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: June 1, 2010
#################################################################
#
#	Parameters:	
#		-i input file
#		-o output file
#
#################################################################

use Getopt::Std;

my %parameters;
getopts('i:o:', \%parameters);							#handles input

unless($parameters{i} && $parameters{o})
{
	print "Please enter the program with -i input file -o output file.\n";
	exit;
}

print "Opening $parameters{i}...";
unless (open(INPUT, $parameters{i}))       #tries to open file
{
	print "Unable to open $parameters{i}\nMake sure you entered the extension when entering the file name.";
	exit;
}
print "\n";
open FILE, ">$parameters{o}" or die $!;
print "Writing $parameters{o}\n";
$line = <INPUT>;
if($line =~ /\r/ && !($line =~ /\n/))
{
	go_go_gadget_CR($line);
}
else
{
	go_go_gadget_Normal($line);
}
print "Done!\n";

close INPUT;
close FILE;

###############################################   SUBROUTINES   ###############################################
sub go_go_gadget_CR()
{
	my ($file) = @_;
	@lines = split(/\r/, $file);		#splits file into array of lines
	
	foreach(@lines)
	{
		print_it($_);
	}
}

sub go_go_gadget_Normal()
{
	my ($line) = @_;
	print_it($line);
	
	while($line = <INPUT>)
	{
		print_it($line);
	}	
}

sub print_it()
{
	my ($in) = @_;
	if($in =~ />/)						#chops off the extra text on the sequence heading
	{
		print FILE substr($in, 0, index($in, " ") + 1)."\n";
	}
	else									#if not a heading, prints out the line
	{
		print FILE $in;
	}
}
