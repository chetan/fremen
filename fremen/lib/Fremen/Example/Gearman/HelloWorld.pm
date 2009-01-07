package Fremen::Example::Gearman::HelloWorld;

use warnings;
use strict;

use base qw( Fremen::Worker );

sub work {
    print "Hello World from $$!\n";
}

1;