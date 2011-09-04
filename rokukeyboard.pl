
use strict;
use warnings;
use Term::ReadKey;
use LWP::UserAgent;
use URI::Escape;
use Data::Dumper;

my $ua = LWP::UserAgent->new();
my $roku_kp_url = "http://192.168.4.3:8060/keypress/";

# Reassign the "STOP" sequence away from Ctrl+S
# so that Ctrl+S can be search.
my %control_chars = GetControlChars();
$control_chars{STOP} = 23;
SetControlChars(%control_chars);

my %keycodes = (
    "\e[A" => 'Up',
    "\e[B" => 'Down',
    "\e[C" => 'Right',
    "\e[D" => 'Left',
    "\x7f" => 'Backspace',
    "\x0a" => 'Enter',
    "\x02" => 'Back',    # Ctrl+B
    "\x09" => 'Info',    # Ctrl+I
    "\x12" => 'InstantReplay', # Ctrl+R
    "\x13" => 'Search',  # Ctrl+S
    "\x10" => 'Play',    # Ctrl+P
    "\e[1~" => 'Home',   # Home
    "\e[5~" => 'Fwd',    # PgUp
    "\e[6~" => 'Rev',    # PgDn
    "\e[4~" => 'Select', # End
);

for my $i (32 .. 126) {
    my $char = chr($i);
    $keycodes{$char} = "Lit_$char";
}

ReadMode 3;

while (my $c = ReadKey 0) {
    if (ord($c) == 27) {
        # Eat a whole escape sequence into a single string
        my $next = ReadKey 0;
        $c .= $next;

        if ($next eq '[') {
            while (my $oc = ReadKey 0) {
                $c .= $oc;
                last if $oc =~ m!^[\x40-\x78~]$!;
            }
        }
    }

    my $code = $keycodes{$c};

    $c =~ s![\x00-\x20]!sprintf('\x%02x', ord($c))!eg;
    if ($code) {
        print "Pressed $code\n";
        my $url = $roku_kp_url . uri_escape($code);
        my $res = $ua->post($url);
        unless ($res->is_success) {
            warn "Roku returned " . $res->status_line;
        }
    }
    else {
        print "Unrecognized $c\n";
    }
}

ReadMode 0;
