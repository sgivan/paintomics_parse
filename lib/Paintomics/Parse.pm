#
#===============================================================================
#
#         FILE:  Paintomics::Parse.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  04/22/15 17:26:42
#     REVISION:  ---
#===============================================================================
package Paintomics::Parse;

use v5.10.0;
use strict;
use warnings;
use autodie;
use Moose;

1;

has 'infile' => (
    is  =>  'rw',
    isa =>  'Str',
);

has 'outfile' => (
    is  =>  'rw',
    isa =>  'Str',
    default =>  'outfile.txt',
);

has 'outfile_fh'    =>  (
    is  =>  'ro',
    isa =>  'Object',
);

has 'outfile_sigID' =>  (
    is  =>  'rw',
    isa =>  'Str',
    default =>  'outfile_sigID.txt',
);

has 'outfile_sigID_fh'  =>  (
    is  =>  'ro',
    isa =>  'Object',
);

has 'qvalue'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    default =>  0,
);

has 'sig_q' =>  (
    is  =>  'rw',
    isa =>  'Float',
    default =>  0.05,
);

has 'qvalue'    =>  (
    is  =>  'rw',
    isa =>  'Int',
);


sub output_files {
    my ($self,$hashref) = @_;
    my $outFH = $self->outfile_fh();
    my $sigFH = $self->outfile_sigID_fh();
    my $qvalue = $self->qvalue();
    say $outFH "Gene_ID\tSample_1";# if you don't have this line, PaintOmics bugs out sometimes

    for my $id (keys(%$hashref)) {
        say "key: '$id'";
        if ($self->qvalue()) {
            say $outFH $id . "\t" .  $hashref->{$id}->[0] . "\t" . $hashref->{$id}->[1];
        } else {
            say $outFH $id . "\t" .  $hashref->{$id}->[0];
        }

        if ($hashref->{$id}->[1] < $self->sig_q()) {
            say $sigFH $id;
        }
    }

}

sub _make_out_FH {
    my $self = shift;

    open(my $fh, '>', $self->outfile());
    $self->outfile_fh($fh);
    return $fh;
}

sub _make_sigs_FH {
    my $self = shift;

    open(my $fh, '>', $self->outfile_sigID());
    $self->outfile_sigID_fh($fh);
    return $fh;
}

no Moose;
__PACKAGE__->meta->make_immutable;

