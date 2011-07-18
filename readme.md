# PANGEA
### Pipeline for Analysis of Next GEneration Amplicons

Written By: David Crabb
Eric Triplett's Group
University of Florida
Last Updated: February 9, 2010

## Table of Contents

1. Perl and R
2. Input
3. Running PANGEA
4. TaxCollector Database
5. cd-hit-est Installation
6. Chi-Square Tool
7. Changes

## Perl, Python, and R
 
### Perl

PANGEA uses Perl 5  which is available at
http://www.perl.org/

### R

The Chi-Square Tool uses R 2, which is available at:
http://cran.r-project.org/

## Input

Make sure the barcode input file is in the correct format: numbered starting at "01" with a tab between the number and the barcode
sequence. Do not put any blank lines after the final barcode. Check the example in the PANGEA folder to see the exact format.

A "-n minimum number of sequences selected.." option is included. Of course, this is not necessary to run the program. It just allows
the user to specify if they have a different number of sequences they want for the normalized data to each have. Otherwise, the program 
automatically sets the minimum at the lowest number a barcode has over 100.

## Running PANGEA

Usage

	perl PANGEA4MAC.pl -s inputSequences.fas -q inputSequences.fas.qual -b inputBarcodes.txt -d taxcollector.fas

Before starting PANGEA do not leave any of the files in the `PANGEA_output` folder open. This will inhibit PANGEA from removing and replacing its output folder and could mess up your output. Instead, rename the previous output folder whatever you want so that data is not lost. If you want to discard that data anyway, then don't rename it and when the program runs it will remove it and put the new data in `PANGEA_output`.

## TaxCollector Database

See [TaxCollector](https://github.com/audy/taxcollector/tree/publication) on Github for instructions on how to prepare a TaxCollector database.

## cd-hit-est Installation

Before you begin using PANGEA, you must make sure `cd-hit-est` is correctly installed. On Windows operating systems, `cd-hit-est.exe should` already be in the backbone and ready to go, so no changes are necessary.

For Mac OS X you must first have X Code installed. For Mac & Linux, in the CD-HIT directory, type 'Make'.  After everything finished compiling type `sudo cp cd-hit-est /usr/bin/cd-hit-est` type your password and hit return.

## Chi-Square Tool

The Chi-Square tool is utilized after PANGEA has run on a dataset. Once a dataset has run, do not change the folder name "PANGEA_Output".  Run the Chi-Square file for whichever system you have to generate your input files for R using the following example notation:

Example:

On Mac/UNIX:
	Chi_Square4MAC.pl -l 1_4 2_3 5_6

On Windows:
	Chi_Square4WIN.pl -r C:/Program_Files/R/R-2.10.1/bin -l 1_4 2_3 5_6

Where the numbers joined by the underscore are the pairs being compared. The script will generate files at each taxonomic level and place them into the Chi_Square folder. It will then generate R scripts and run them in R. Remember that this folder is replaced every time you run the Chi-Square tool, so be sure to change the name of any Chi_Square folder if you wish to save it.