package Fremen::Status::Gearman;

use strict;

use Errno qw(EAGAIN);
use Socket qw(IPPROTO_TCP TCP_NODELAY SOL_SOCKET PF_INET SOCK_STREAM);

use Data::Dumper;

use fields qw(cmd sock);

sub new {
    my $self = shift;
    my $ipport = shift;

    $self = fields::new($self) unless ref $self;
    
    # create socket    
    my $sock = IO::Socket::INET->new(PeerAddr => $ipport,
                                     Timeout => 1);
    die if not $sock;
    
    $sock->autoflush(1);
    setsockopt($sock, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;
    
    $self->{sock} = $sock;

    # make sure provided listening socket is non-blocking
    IO::Handle::blocking($sock, 1);

    return $self;
}

sub read_response {

    my $self = shift;
    
    # read everything into a buffer until we get .\n
    
    # Start off trying to read the whole buffer. Store the bits in an array
    # one element for each read, then do a big join at the end. This minimizes
    # the number of memory allocations we have to do.
    my @buffers;
    my $i = 0;
    while (1) {
        my $rv = sysread($self->{sock}, $buffers[$i], 1024);
        last if $rv == 0 || $buffers[$i] =~ /^\.\n$/;
        $i++;
    }
    
    return join('', @buffers);
}

sub CMD_status {
    my($self, $res) = @_;
    # Function name \t Number in queue \t Number of jobs running \t Number of capable workers
    my @stats;
    for ( split(/\n/, $res) ) {
        next if $_ eq 'status';
        last if $_ eq '.';
        my %stat;
        @stat{qw(function queue running workers)} = ($_ =~ /^(.*)\t([^\t]*?)\t([^\t]*?)\t([^\t]*?)$/);
        push @stats, \%stat;
    }
    return \@stats;
}

sub status {
    my $self = shift;
    $self->_send_cmd('status');
}

sub CMD_workers {
    my($self, $res) = @_;
    # fd ip.x.y.z client_id : func_a func_b func_c
    my @workers;
    for ( split(/\n/, $res) ) {
        next if $_ =~ /^\d+ \d+\.\d+\.\d+\.\d+ - : $/;
        last if $_ eq '.';
        my %worker;
        @worker{qw(fd ip client_id funcs)} = ($_ =~ /^(\d+) (\d+\.\d+\.\d+\.\d+) ([a-z]+) : (.*)$/);
        
        # extract functions, prefix
        my $has_prefix = $worker{funcs} =~ /\t/ ? 1 : 0;
        $worker{funcs} = [ split(/ /, $worker{funcs}) ];
        if ($has_prefix) {
            my($prefix, @funcs, $f);
            for (@{$worker{funcs}}) {
                ($prefix, $f) = split(/\t/, $_);
                $worker{prefix} = $prefix;
                $worker{agent} = 1 if $f eq 'fremen_agent';
                push @funcs, $f;
            }
            $worker{funcs} = [ @funcs ];
        }
        push @workers, \%worker;
    }
    return \@workers;
}

sub workers {
    my $self = shift;
    return $self->_send_cmd('workers');
}

sub _send_cmd {
    
    my($self, $cmd) = @_;
    
    $self->{cmd} = $cmd;
    $self->{sock}->syswrite("$cmd\n");
    
    my $buf = $self->read_response();
    
    # finally, process it
    my $code = $self->can("CMD_" . $self->{cmd});
    if ($code) {
        return $code->($self, $buf);
    }
}

1;
