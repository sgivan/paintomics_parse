#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  new.pl
#
#        USAGE:  ./new.pl  
#
#  DESCRIPTION:  Parse a custom tab-delimited file generated by Bill Spollen
#                   and create a file for input to PaintOmics website.
#                   The main goal of this script is to eliminate multiple
#                   rows for a given gene.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (SAG), sgivan@yahoo.com
#      COMPANY:  BWL Software
#      VERSION:  1.0
#      CREATED:  04/01/2015 04:55:23 PM
#     REVISION:  ---
#===============================================================================



use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;

my ($debug,$verbose,$help,$infile,$outfile,$sig_q,$qvalue,$nobest);

my $result = GetOptions(
    "infile:s"  =>  \$infile,
    "outfile:s" =>  \$outfile,
    "sig_q:f"   =>  \$sig_q,
    "qvalue"    =>  \$qvalue,
    "nobest"  =>  \$nobest,
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
);

if ($help) {
    help();
    exit(0);
}

sub help {

say <<HELP;

    "infile:s"
    "outfile:s"
    "sig_q:f" minimum Q-value to be significant - default = 0.05
    "qvalue" print Q-value in output
    "nobest" don't pick best data for each gene
    "debug"
    "verbose"
    "help"

HELP

}

$infile ||= 'infile';
$outfile ||= 'outfile';
$sig_q ||= '0.05';

if ($debug) {
    say "infile: '$infile'";
    say "outfile: '$outfile'";
    say "sig_q: '$sig_q'";
    exit();
}

open(my $in, "<", $infile);
open(my $out, ">", $outfile);
open(my $sigs, ">", "$outfile" . "_sigID.txt");

#
# input file looks like this:
#
#SeqID	logFC	logCPM	PValue	FDR	EnsemblID	AIN_B_F	AIN_B_F	AIN_B_F	AIN_B_F	AIN_B_F	AIN_B_M	AIN_B_M	AIN_B_M	AIN_B_M	AIN_B_M	tagwise.dispersions
#c100001_g1_i1	1.88718933819957	-3.39403395367824	0.0502593823991571	1	ENSMUSG00000030102	1	0	0	0	3	2	4	1	1	4	0.382978762331822
#c100006_g1_i1	0.124082247649993	1.90383223800325	0.805873267935035	1	ENSMUSG00000031604	224	135	100	156	171	81	161	153	146	102	0.285484765761154
#c100014_g1_i1	-2.29464848758662	-2.95486182924322	0.00218562527095768	0.267105253387657	ENSMUSG00000020682	4	5	6	6	7	0	0	2	2	0	0.23266991972961
#
# index of relevent fields:
# 1 logFC
# 2 logCPM
# 4 FDR
# 5 Ensembl ID
# 16 tagwise.dispersion 
#

#
# instantiate a hash to hold the values that will be printed
# keyed by Ensembl ID
# if a duplicate Ensembl ID is detected, keep the "better" one
#
my %ensemblIDs = ();

for my $inline (<$in>) {

    chomp($inline);
    my @linevals = split /\t/, $inline;
#    next if (exists($ensemblIDs{$linevals[5]}));
#    say $out $linevals[5] . "\t" . $linevals[1] if ($linevals[5] =~ /ENSMUS/);
    my $td = $linevals[$#linevals];# tagwise.dispersion
    #my $data = [$linevals[1], $linevals[4],$linevals[16]];
    my $data = [$linevals[1], $linevals[4],$td];
#    $ensemblIDs{$linevals[5]} = $data if ($linevals[5] =~ /ENSMUS/);
    if ($linevals[5] =~ /ENSMUS/) {
        unless ($nobest) {
            if (exists($ensemblIDs{$linevals[5]})) {
                if ($linevals[4] < $sig_q && ($linevals[4] < $ensemblIDs{$linevals[5]}->[1])) {
                    # if FDR of incoming data < what's already stored in hash
                    #$ensemblIDs{$linevals[5]} = [$linevals[1], $linevals[4],$linevals[16]];
                    $ensemblIDs{$linevals[5]} = $data;
                } elsif ($linevals[4] > $sig_q && $ensemblIDs{$linevals[5]}->[1] > $sig_q) {
                    # when FDR is > sig_q, usually 0.05, this gene is not differentially expressed
                    # so, save the data with the lowest tagwise.dispersion
                    if ($td < $ensemblIDs{$linevals[5]}->[2]) {
                        #$ensemblIDs{$linevals[5]} = [$linevals[1], $linevals[4], $linevals[16]];# logFC, FDR, tagwise.dispersion
                        $ensemblIDs{$linevals[5]} = $data;
                    }
                }
            } else {
                #$ensemblIDs{$linevals[5]} = [$linevals[1], $linevals[4], $linevals[16]];# logFC, FDR, tagwise.dispersion
                $ensemblIDs{$linevals[5]} = $data;
            }
        } else {
            $ensemblIDs{$linevals[5]} = $data;
        }
    }

}

#
# print output
#
say $out "Gene_ID\tSample_1";# if you don't have this line, PaintOmics bugs out sometimes
#for my $id (sort keys(%ensemblIDs)) {
for my $id (keys(%ensemblIDs)) {
    if ($qvalue) {
        say $out $id . "\t" .  $ensemblIDs{$id}->[0] . "\t" . $ensemblIDs{$id}->[1];
    } else {
        say $out $id . "\t" .  $ensemblIDs{$id}->[0];
    }

    if ($ensemblIDs{$id}->[1] < $sig_q) {
        say $sigs $id;
    }
}

