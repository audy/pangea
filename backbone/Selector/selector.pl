#!/usr/bin/perl -w
#
# selector.pl
# Written by: David Crabb
# Eric Triplett's Group
# University of Florida
# Last Modified: July 6, 2010
###########################################################################################
#
#	Parameters:
#		-i input sequence file
#		-s number of sequeces
#		-o output sequence file
#
#	Optional:
#		-m input megablast file
#		-k output megablast file
#
###########################################################################################

use Getopt::Std;

my %parameters;
getopts('i:m:s:o:n:', \%parameters);

unless($parameters{i} && $parameters{s} && $parameters{o})
{
	print "Please enter the program at least with -i input sequence file -o output seqeunce file -s number of sequences.\n";
	exit;
}

if($parameters{m} && !($parameters{n}))
{
	print "Please enter the output megablast file if you are entering a megablast input file.\n";
	exit;
}
elsif($parameters{n} && !($parameters{m}))
{
	print "Please enter the input megablast file if you are entering a megablast output file.\n";
	exit;
}

$limit = $parameters{s};

unless (open(INPUT, $parameters{i}))       #tries to open file
{
	print "Unable to open $parameters{i}\nMake sure you entered the extension when entering the file name.\n";
	exit;
}

$line = <INPUT>;
open OUTPUT, ">$parameters{o}" or die $!;
@IDs = (); 					#an array of seqeuence id's that will be used to select out of the megablast file.

if($line =~ /\n/)
{
	$limit--;
	if($line =~ /\r/)		#Newline characters are in CRLF format
	{
		&select_Normal($line, $limit);	
	}
	else				#Newline characters are in LF format
	{
		&select_Normal($line, $limit);
	}
}
elsif($line =~ /\r/)
{
	&select_CR($line, $limit);	#Newline characters are in CR format
}
else
{
	print "\nError: Either there is only one line in the input file or there is some newline character problem.\nExiting...\n";
}
close INPUT;
close OUTPUT;

if($parameters{m} && $parameters{n})			#If megablast input and output info has been entered
{
	$limit = $parameters{s};
	&take_megablast_input();
	
	$stoppingPoint = -1;
	foreach(@IDs)
	{
		$_ = substr($_, 1);
	}
	%searchSelected = map { $_ => 1 } @IDs;
	$size = (scalar @mega) - 1;
	for($a = $size; $a >= 0; $a--)
	{
		$dex = index($mega[$a], "\t");
		$id = substr($mega[$a], 0, $dex);
		if(exists($searchSelected{$id}))
		{
			$stoppingPoint = $a;
			$a = -1;
		}
	}
	open OUTPUT, ">$parameters{n}" or die $!;
	for($a = 0; $a <= $stoppingPoint; $a++)
	{
		print OUTPUT "$mega[$a]";
	}
	close OUTPUT;
}


###############################################   SUBROUTINES   ###############################################

sub select_Normal()	#CRLF or LF format
{
	my ($line, $limit) = @_;
	if($line =~ />/)
	{
		$limit--;
		print OUTPUT "$line";
		$line =~ s/\s+$//;
		push(@IDs, $line);				#add sequence ID to list
	}
	while($line = <INPUT>)		#selects the correct number of sequences or stops at the end of the file
	{
		if($limit < 0)		#end if the correct number of sequences have been found
		{
			if(&check_Line($line) eq "exit")	#subroutine prints or tells it to exit
			{
				last;
			}
			while($line = <INPUT>)		#loop to find the end of the sequence
			{
				if(&check_Line($line) eq "exit")	#subroutine prints or tells it to exit
				{
					last;
				}
			}
			last;
		}
		else
		{
			if($line =~ />/)		#if new sequence, count it and print it
			{
				$limit--;
				$line =~ s/\s+$//;
				push(@IDs, $line);		#add sequence ID to list
				
			}
			$line =~ s/\s+$//;
			print OUTPUT "$line\n";
		}
	}
}

sub select_CR()		#CR format
{
	my($file, $limit) = @_;
	@lines = split(/\r/, $file);		#splits file into array of lines
	
	$size = scalar @lines;
	for($a = 0; $a < $size; $a++)
	{
		if($limit < 1)		#end if the correct number of sequences have been found
		{
			for($a = $a; $a < $size; $a++)		#loop to find the end of the sequence
			{
				$lines[$a] = $lines[$a]."\n";
				if(&check_Line($lines[$a]) eq "exit")	#subroutine prints or tells it to exit
				{
					$a = $size;
				}
			}
		}
		else
		{
			$lines[$a] =~ s/\s+$//;
			if($lines[$a] =~ />/)		#if new sequence, count it and print it
			{
				$limit--;
				push(@IDs, $lines[$a]);		#add sequence ID to list
			}
			$lines[$a] = $lines[$a]."\n";
			print OUTPUT "$lines[$a]";
		}
	}
}

sub check_Line()
{
	my ($line) = @_;
	if($line =~ /[a-zA-Z]/)		#if line contains letters (bases) continue
	{
		if($line =~ />/)		#if new sequence, end
		{
			return "exit";
		}
		else
		{
			$line =~ s/\s+$//;
			print OUTPUT "$line\n";
		}
	}
	else
	{
		return "exit";
	}
}

sub take_megablast_input()
{
	unless (open(INPUT, $parameters{m}))       #tries to open file
	{
		print "Unable to open $parameters{m}\nMake sure you entered the extension when entering the file name.\n";
		exit;
	}
	@mega = ();
	while($line = <INPUT>)
	{
		if($limit < 1)
		{
			last;
		}
		else
		{
			$limit--;
			push(@mega, $line);
		}
	}
	close INPUT;
}
