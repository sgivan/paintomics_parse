#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  join_tables.pl
#
#        USAGE:  ./join_tables.pl  
#
#  DESCRIPTION: Script to join any number of tables
#               given as arguments on command line
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  04/24/15 17:04:33
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use Data::Table;

my ($debug,$verbose,$help);

my $result = GetOptions(
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

    usage: join_tables.pl [options] table_one table_two table_three ...
   
    debug
    verbose
    help

HELP

}

open(my $OUT, ">", "new_table.tsv");

my @tables = ();

for my $file (@ARGV) {
    say STDERR $file if ($debug);

    my $table = Data::Table::fromFile($file);
    push(@tables,$table);
}

say STDERR "\@tables contains " . scalar(@tables) . " tables" if ($debug);

my $joined_table;
my $cnt = 0;
for (my $tbl = 0; $tbl < scalar(@tables); ++$tbl) {
    my $table = $tables[$tbl];
    
    unless ($table->isEmpty()) {
        ++$cnt;
        if ($cnt == 1) {
            # in first iteration of loop, just assign first Data::Table object to $joined_table
            $joined_table = $table;
            next;
        }
        $joined_table = $joined_table->join($table,Data::Table::FULL_JOIN,['Gene_ID'],['Gene_ID'],{renameCol=>1});
    }
     
}
say STDERR "\$joined_table isa '" . ref($joined_table) . "'" if ($debug);
say $OUT $joined_table->tsv();

