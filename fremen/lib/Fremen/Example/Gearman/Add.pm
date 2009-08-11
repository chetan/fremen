package Fremen::Example::Gearman::Add;

use warnings;
use strict;

use base qw( Fremen::Worker );

use List::Util qw( sum );

our $ALIAS = 'add';
    
sub work {
    my($class, $job) = ( @_ == 2 ? @_ : (undef, @_) );
    my $args = $job->arg;
    return sum(@$args);
}

1;