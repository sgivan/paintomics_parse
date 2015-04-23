#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  new.pl
#
#        USAGE:  ./new.pl  
#
#  DESCRIPTION:  Parse the tab-delimited file generated by cuffdiff
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
#      CREATED:  04/22/2015 01:46:49 PM
#     REVISION:  ---
#===============================================================================



use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Paintomics::Parse;

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

my $PP = Paintomics::Parse->new();

$infile ||= 'infile';
$outfile ||= 'outfile';
$sig_q ||= '0.05';

$PP->infile($infile);
#$PP->outfile($outfile);
#$PP->outfile_sigID($outfile . "_sigID.txt");
$PP->sig_q($sig_q);

if ($debug) {
    say "infile: '" . $PP->infile();
    say "outfile: '$outfile'";
    say "sig_q: '$sig_q'";
    exit();
}

#
# input file looks like this:
#test_id	gene_id	gene	locus	sample_1	sample_2	status	value_1	value_2	log2(fold_change)	test_stat	p_value	q_value	significant
#ENSRNOG00000000001	ENSRNOG00000000001	Arsj	C2:249516524-250013503	6FL-NT	6FL	NOTEST	0.196099	0.185595	-0.079425	0	1	1	no
#ENSRNOG00000000007	ENSRNOG00000000007	Gad1	C3:63479962-63519877	6FL-NT	6FL	OK	61.5844	45.2746	-0.443864	-1.4554	0.00095	0.0537574	no
#ENSRNOG00000000008	ENSRNOG00000000008	Alx4	C3:89249577-89286113	6FL-NT	6FL	NOTEST	0	0.137481	inf	0	1	1	no
#ENSRNOG00000000009	ENSRNOG00000000009	Tmco5b	C3:111335115-111350242	6FL-NT	6FL	NOTEST	0	0	0	0	1	1	no
#
#
# index of relevent fields:
# 1 gene_id (ie; Ensembl ID)
# 4 sample_1 name
# 5 sample_2 name
# 9 log(value_2/value_1)
# 12 FDR
#
my $gene_id = 1;
my $sample_1 = 4;
my $sample_2 = 5;
my $log2ratio = 9;
my $fdr = 12;

#
# instantiate a hash to hold the values that will be printed
# keyed by Ensembl ID
# if a duplicate Ensembl ID is detected, keep the "better" one
#
my %ensemblIDs = ();

my $cnt = 0;
my $sample_set_last = '';
my $infile_fh = $PP->infile_fh();
for my $inline (<$infile_fh>) {

    chomp($inline);
    next if (++$cnt == 1);
    my @linevals = split /\t/, $inline;
    $linevals[$log2ratio] =~ s/inf/0/;
    my $sample_set = $linevals[$sample_2] . "_vs_" . $linevals[$sample_1];
    #say "sample set: '$sample_set'";
    if ($sample_set_last && ($sample_set_last eq $sample_set)) {

        my $data = [$linevals[$log2ratio], $linevals[$fdr]];

        if ($linevals[$gene_id] =~ /ENS/) {
            my $ensemblID = $linevals[$gene_id];
            #say $ensemblID;
            unless ($nobest) {
                if (exists($ensemblIDs{$ensemblID})) {
                    say "ensemblIDs{$ensemblID} exists";
                    if ($linevals[$fdr] < $sig_q && ($linevals[$fdr] < $ensemblIDs{$ensemblID}->[1])) {
                        # if FDR of incoming data < what's already stored in hash
                        #$ensemblIDs{$linevals[5]} = [$linevals[1], $linevals[4],$linevals[16]];
                        $ensemblIDs{$ensemblID} = $data;
                    } elsif ($linevals[$fdr] > $sig_q && $ensemblIDs{$ensemblID}->[1] > $sig_q) {
                        # when FDR is > sig_q, usually 0.05, this gene is not differentially expressed
                        # so, save the data with the largest log2ratio
                        if (abs($linevals[$log2ratio]) > $ensemblIDs{$ensemblID}->[2]) {
                            #$ensemblIDs{$linevals[5]} = [$linevals[1], $linevals[4], $linevals[16]];# logFC, FDR, tagwise.dispersion
                            $ensemblIDs{$linevals[5]} = $data;
                        }
                    }
                } else {
                    #$ensemblIDs{$linevals[5]} = [$linevals[1], $linevals[4], $linevals[16]];# logFC, FDR, tagwise.dispersion
                    $ensemblIDs{$ensemblID} = $data;
                }
            } else {
                $ensemblIDs{$ensemblID} = $data;
            }
        }
    } elsif ($sample_set_last) {
        $PP->outfile($outfile . "_" . $sample_set_last);
        $PP->outfile_sigID($outfile . "_sigID_" . $sample_set_last);
        $PP->output_files(\%ensemblIDs);
        %ensemblIDs = ();
        $sample_set_last = $sample_set;
        redo;
    } else {
        $sample_set_last = $sample_set;
        redo;
    }
}

$PP->outfile($outfile . "_" . $sample_set_last);
#say "outputting last dataset to file: '" . $PP->outfile() . "'";
$PP->outfile_sigID($outfile . "_sigID_" . $sample_set_last);
$PP->output_files(\%ensemblIDs);

