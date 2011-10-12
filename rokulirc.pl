
use strict;
use warnings;

use IO::Socket;
use Carp "croak";
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();
my $roku_launch_url = "http://192.168.4.3:8060/launch/";

my $sock = IO::Socket->new(
    Domain => &AF_UNIX,
    Type   => SOCK_STREAM,
    Peer   => "/dev/lircd",
) or croak "couldn't connect to lircd: $!";

my %chanmap = (
    PLAY => '12', # Netflix
    VOLUP => '2285', # Hulu Plus
    VOLDOWN => '4026', # BBC World Service
    MENU => '1489_dd56', # YouTube
    BACKWARD => '13', # Amazon Instant Video
    FORWARD => '2136', # MOG
);

while (my $l = <$sock>) {
    chomp $l;
    my ($something, $repeat, $command, $remote) = split(/\s+/, $l, 4);
    next unless $remote eq 'Apple_A1156';
    next if $repeat > 0;
    my $channel = $chanmap{$command};
    print STDERR "$command\t$channel\n";
    my $url = $roku_launch_url . $channel;
    my $res = $ua->post($url);
    unless ($res->is_success) {
        print STDERR $url, "\n";
        warn "Roku returned " . $res->status_line;
    }
}
