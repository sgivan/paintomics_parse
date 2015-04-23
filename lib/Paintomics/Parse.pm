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
    default =>  'infile',
);

has 'infile_fh'    =>  (
    is  =>  'rw',
    isa =>  'FileHandle',
    lazy    =>  1,
    builder =>  '_make_infile_FH',
);

has 'outfile' => (
    is  =>  'rw',
    isa =>  'Str',
    default =>  'outfile.txt',
    trigger =>  \&_set_outfile_fh,
);

has 'outfile_fh'    =>  (
    is  =>  'rw',
    isa =>  'FileHandle',
    lazy    =>  1,
    builder =>  '_make_outfile_FH',
);

has 'outfile_sigID' =>  (
    is  =>  'rw',
    isa =>  'Str',
    default =>  'outfile_sigID.txt',
    trigger =>  \&_set_outfile_sigID_fh,
);

has 'outfile_sigID_fh'  =>  (
    is  =>  'rw',
    isa =>  'FileHandle',
    lazy    =>  1,
    builder =>  '_make_outfile_sigID_FH',
);

has 'qvalue'    =>  (
    is  =>  'rw',
    isa =>  'Int',
    default =>  0,
);

has 'sig_q' =>  (
    is  =>  'rw',
    isa =>  'Num',
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
        #say "key: '$id'";
        if ($self->qvalue()) {
            say $outFH $id . "\t" .  $hashref->{$id}->[0] . "\t" . $hashref->{$id}->[1];
        } else {
            say $outFH $id . "\t" .  $hashref->{$id}->[0];
        }

        if ($hashref->{$id}->[1] < $self->sig_q()) {
            say $sigFH $id;
        }
    }
#    $self->_closeFH($outFH);
#    $self->_closeFH($sigFH);
}

sub _make_infile_FH {
    my $self = shift;

    open(my $fh, '<', $self->infile());
    $self->infile_fh($fh);
    return $fh;
}

sub _make_outfile_FH {
    my $self = shift;

    #say "creating output file '" . $self->outfile() . "'";
    open(my $fh, '>', $self->outfile());
    $self->outfile_fh($fh);
    return $fh;
}

sub _make_outfile_sigID_FH {
    my $self = shift;

    open(my $fh, '>', $self->outfile_sigID());
    $self->outfile_sigID_fh($fh);
    return $fh;
}

sub _closeFH {
    my ($self,$fh) = @_;

    $fh->close();
}

sub _set_outfile_fh {
    my ($self,$new) = @_;

    $self->_closeFH($self->outfile_fh);

    $self->_make_outfile_FH($new);

}

sub _set_outfile_sigID_fh {
    my ($self,$new) = @_;

    $self->_closeFH($self->outfile_sigID_fh);

    $self->_make_outfile_sigID_FH($new);

}

no Moose;
__PACKAGE__->meta->make_immutable;


