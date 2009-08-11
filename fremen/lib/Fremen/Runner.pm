package Fremen::Runner;

use warnings;
use strict;
no strict 'refs';

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

our $ALIAS;

sub new {
    my($class, %self) = @_;
    %self = (
    	%self,
		help		=> 0,
		man			=> 0,
		verbose		=> 0,
		gearman	    => [],
		schwartz	=> [],
		gearmand    => [],
	);
    return bless \%self, $class;
}

sub _split_arrays {
    my($self) = @_;
    for (keys %$self) {
        next if ref($self->{$_}) ne 'ARRAY';
        my @arr = @{$self->{$_}};
        @arr = split(/,/, join(',', @arr)) if @arr;
        $self->{$_} = \@arr;
    }
}

sub parse_options {

    my($self) = @_;

	GetOptions(
        help			    => \$self->{help},
        man				    => \$self->{man},
        'verbose|v+'		=> \$self->{verbose},
        'gearman|g=s'       => $self->{gearman},
        'schwartz|s=s'		=> $self->{schwartz},
        'gearmand|d=s'      => $self->{gearmand},
	) or pod2usage( -verbose => 0 );
          
	pod2usage( -verbose => 1 ) if $self->{help};
	pod2usage(-exitstatus => 0, -verbose => 2) if $self->{man};

    $self->_split_arrays();
	
	if ( @{$self->{gearman}} && @{$self->{schwartz}} ) {
	    die "can't mix gearman and schwartz workers!";
    }
	
}

sub start {
    
    my($self) = @_;
    
    if ( $self->{gearman} ) {
        $self->start_gearman();
        
    } elsif ( $self->{schwartz} ) {
        $self->start_schwartz();
    }

}

sub start_gearman {

    my($self) = @_;

    eval 'require Gearman::Worker';
    
    my $worker = Gearman::Worker->new;
    $worker->job_servers( @{$self->{gearmand}} );
    
    for my $class ( @{$self->{gearman}} ) {
    
        # load module
        eval "require $class" || die "unable to load package $class, $@";
        die "package $class does not have work() routine" 
            if ! $class->can('work');
        
        if ($class->isa('Fremen::Worker')) {
            Fremen::Worker->wrap_json($class);
            Fremen::Worker->wrap_stats($class);
        }
        
        # register the routine
        my $sub = "${class}::work";
        print "registering $sub\n";
        $worker->register_function($sub => \&{$sub});
        
        # check for alias
        my $alias = ${"${class}::ALIAS"};
        if ($alias) {
            print "  registering alias $alias\n";
            $worker->register_function($alias => \&{$sub});
        }
        
    }
    
    # add helper methods
    $worker->register_function(
        "fremen_stats_" . $worker->{client_id} => \&{'Fremen::Worker::stats'});
    
    $worker->work while 1;
}

sub start_schwartz {
    
    my($self) = @_;
    
    eval 'require TheSchwartz';
    
    my $worker = TheSchwartz->new( databases => () );
    
    for my $class ( @{$self->{schwartz}} ) {
        eval "require $class" || die "unable to load package $class, $@";
        die "package $class does not have work() routine" 
            if ! $class->can('work');
        print "registering $class\n";
        $worker->can_do($class);
    }
    
    $worker->work();
}

=head1 NAME

Fremen::Runner - The great new Fremen!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Fremen;

    my $foo = Fremen->new();
    ...

=head1 EXPORT

A list of functions that can be exported. You can delete this section if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

=head2 function2

=cut

=head1 AUTHOR

Chetan Sarva, C<< <chetan at pixelcop.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fremen at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Fremen>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Fremen


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Fremen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Fremen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Fremen>

=item * Search CPAN

L<http://search.cpan.org/dist/Fremen/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Chetan Sarva, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Fremen
