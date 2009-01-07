package Fremen::Example::Gearman::Add;

use warnings;
use strict;

use base qw( Fremen::Worker );

use List::Util qw( sum );
    
sub work {
    my($job) = @_;
    my $args = $job->arg;
    return sum(@$args);
}

1;