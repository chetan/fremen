package Fremen::Worker;

use warnings;
use strict;

use JSON;
use Sub::Install;

use Fremen::SysInfo;

our $stats = {};

sub new {
    my($self) = @_;
    $self = fields::new($self) unless ref $self;
    return $self;
}

# handle job/args before calling work()
sub wrap_json {

    my($class, $module) = @_;
    
    my $work_method_ref = \&{"${module}::work"};
    
    my $code = sub {
    
        my($pkg, $job) = ( @_ == 2 ? @_ : (undef, @_) );
       
        if ($job->arg) {
            my $json = from_json($job->arg);
            $job->{argref} = \$json;
        }
        
        my $ret = $work_method_ref->( ($pkg ? ($pkg, $job) : ($job)) );
        if ( ref($ret) && ref($ret) ne 'SCALAR' ) {
            $ret = to_json($ret);
        }
        return \$ret;
    };
    
    Sub::Install::reinstall_sub({code => $code,
                                 into => $module,
                                 as   => 'work'});  
}

sub wrap_stats {

    my($class, $module) = @_;
    
    my $method = "${module}::work";
    my $work_method_ref = \&{$method};
    
    my $code = sub {
        my(@args) = @_;
        # incr stats
        if ($stats->{$method}) {
            $stats->{$method}++;
        } else {
            $stats->{$method} = 1;
        }
        return $work_method_ref->(@args);
        my $ret = $work_method_ref->(@args);
        return \$ret;
    };
    
    Sub::Install::reinstall_sub({code => $code,
                                 into => $module,
                                 as   => 'work'});
}

sub stats {
    my($class, $job) = ( @_ == 2 ? @_ : (undef, @_) );
    
    my $proc_stats = Fremen::SysInfo->process_stats();
    my($proc) = grep({ $_->{pid} == $$ } @$proc_stats);
    
    my $stats_ref = { func => $stats,
                      proc => $proc,
                      perl => Fremen::SysInfo->gladiator(),
                    };
    
    return to_json($stats_ref);
}

=head1 NAME

Fremen::Worker - The great new Fremen!

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
