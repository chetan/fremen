#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Fremen' );
}

diag( "Testing Fremen $Fremen::VERSION, Perl $], $^X" );
