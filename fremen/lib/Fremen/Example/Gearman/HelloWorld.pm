package Fremen::Example::Gearman::HelloWorld;

use warnings;
use strict;

use base qw( Fremen::Worker );

our $ALIAS = 'hello_world';

sub work {
    print "Hello World from $$!\n";
}

1;