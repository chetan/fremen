package Fremen::SysInfo;

use strict;

use Socket;
use Sys::Hostname;

# get a hash of { pid => command name }
sub pids {

    #   UID   PID  PPID   C     STIME TTY           TIME CMD
    #     0     1     0   0   0:01.91 ??         0:02.72 /sbin/launchd

    my $ps = `ps -ef`;
    die "unable to get process list" if not $ps;
    
    my @pids;
    while ($ps =~ /\s*([0-9a-z]*?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\s+(.*?)\s+(.*?)\s+(.*)/gc) {
        my $pid = $2;
        my $cmd = $8;
        push(@pids, $pid, $cmd);
    }
    return { @pids };
}

# get process stats, returns list of hashes
# { pid cpu mem rss vsz cmd }
sub process_stats {

    # $ ps -e -o pid,%cpu,%mem,rss,vsz,command 
    #   PID %CPU %MEM    RSS      VSZ COMMAND
    #     1   0.0  0.0    592   600820 /sbin/launchd

    my $ps = `ps -e -o pid,%cpu,%mem,rss,vsz,command`;
    die "unable to get process stats" if not $ps;
    
    my @pids;
    for (split(/\n/, $ps)) {
        my %pid;
        if ( @pid{qw(pid cpu mem rss vsz cmd)} = 
             ( $_ =~ /^\s*(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+)\s+(.*)$/ ) )  {
            push @pids, { %pid };
        }
    }
    return \@pids;
}

sub ip {
    inet_ntoa( scalar gethostbyname(hostname() || 'localhost') );
}

sub hostname {
    return (hostname() || 'localhost');
}

# get system uptime stats
# { uptime, users, load load5min, load15min }
sub uptime {
    # linux: 07:31:27 up 309 days,  7:36,  9 users,  load average: 0.03, 0.08, 0.08
    # macos: 2:29am  up 5 days  1:21,  9 users,  load average: 0.20, 0.31, 0.31
    my %uptime;
    @uptime{qw(uptime users load load5min load15min)} = ( `uptime` =~ /^.*up (\d+ days\s+\d+:\d+),?\s+(\d+) users,.*: (\d+\.\d+), (\d+\.\d+), (\d+\.\d+)/ );
    return \%uptime;
}

# get free and total memory
# { free, total }
sub memory {

    # linux:
    #              total       used       free     shared    buffers     cached
    # Mem:          1519       1471         47          0         38        144
    # -/+ buffers/cache:       1288        230
    # Swap:         1906        971        934
    
    # macos:
    # 
    # $ vm_stat 
    # Mach Virtual Memory Statistics: (page size of 4096 bytes)
    # Pages free:                  1449187.
    # 
    # $ sysctl hw.pagesize
    # hw.pagesize: 4096
    
    if (`uname` =~ 'Darwin') {
        # MAC OS X
        my $stat = `vm_stat`;
        my($page_size) = ($stat =~ /page size of (\d+)/);
        my($free_pages) = ($stat =~ /Pages free:\s+(\d+)\./);       
        my($total_mem) = (`sysctl hw.memsize` =~ /(\d+)/);
        my $free_mem = $free_pages * $page_size;
        return { free => $free_mem / 1024, total => $total_mem / 1024 };
    }
    
    # LINUX
    # TODO
    die "Linux isn't implemented yet";

}

# get detailed stats
# stolen from Gearman::Server::Client::TXTCMD_gladiator()
sub gladiator {
    my $class = shift;
    my $args = shift || "";
    my $has_gladiator = eval "use Devel::Gladiator; use Devel::Peek; 1;";
    if ($has_gladiator) {
        my @stats;
        my $all = Devel::Gladiator::walk_arena();
        my %ct;
        foreach my $it (@$all) {
            $ct{ref $it}++;
            if (ref $it eq "CODE") {
                my $name = Devel::Peek::CvGV($it);
                $ct{$name}++ if $name =~ /ANON/;
            }
        }
        $all = undef;  # required to free memory
        foreach my $n (sort { $ct{$a} <=> $ct{$b} } keys %ct) {
            next unless $ct{$n} > 1 || $args eq "all";
            push @stats, sprintf("%7d $n", $ct{$n});
        }
        return \@stats;
    }
    return undef;
}

1;