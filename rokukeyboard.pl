
use strict;
use warnings;
use Linux::Input::Info qw(:all);
use Linux::Input;
use Data::Dumper;
use LWP::UserAgent;
use URI::Escape;

my $ua = LWP::UserAgent->new();
my $roku_kp_url = "http://192.168.4.3:8060/keypress/";

my $left_shift = 42;
my $right_shift = 54;

my $lc_keycodes = {
    1  => "Back",
    2  => "Lit_1",
    3  => "Lit_2",
    4  => "Lit_3",
    5  => "Lit_4",
    6  => "Lit_5",
    7  => "Lit_6",
    8  => "Lit_7",
    9  => "Lit_8",
    10 => "Lit_9",
    11 => "Lit_0",
    12 => "Lit_-",
    13 => "Lit_=",
    14 => "Backspace",
    15 => "Select",
    16 => "Lit_q",
    17 => "Lit_w",
    18 => "Lit_e",
    19 => "Lit_r",
    20 => "Lit_t",
    21 => "Lit_y",
    22 => "Lit_u",
    23 => "Lit_i",
    24 => "Lit_o",
    25 => "Lit_p",
    26 => "Lit_[",
    27 => "Lit_]",
    28 => "Enter",
    30 => "Lit_a",
    31 => "Lit_s",
    32 => "Lit_d",
    33 => "Lit_f",
    34 => "Lit_g",
    35 => "Lit_h",
    36 => "Lit_j",
    37 => "Lit_k",
    38 => "Lit_l",
    39 => "Lit_;",
    40 => "Lit_'",
    43 => "Lit_\\",
    44 => "Lit_z",
    45 => "Lit_x",
    46 => "Lit_c",
    47 => "Lit_v",
    48 => "Lit_b",
    49 => "Lit_n",
    50 => "Lit_m",
    51 => "Lit_,",
    52 => "Lit_.",
    53 => "Lit_/",
    57 => "Lit_ ",
    102 => "Home",
    103 => "Up",
    105 => "Left",
    106 => "Right",
    108 => "Down",
};
my $uc_keycodes = {
    2  => "Lit_!",
    3  => "Lit_@",
    4  => "Lit_#",
    5  => "Lit_\$",
    6  => "Lit_%",
    7  => "Lit_^",
    8  => "Lit_&",
    9  => "Lit_*",
    10 => "Lit_(",
    11 => "Lit_)",
    12 => "Lit__",
    13 => "Lit_+",
    16 => "Lit_Q",
    17 => "Lit_W",
    18 => "Lit_E",
    19 => "Lit_R",
    20 => "Lit_T",
    21 => "Lit_Y",
    22 => "Lit_U",
    23 => "Lit_I",
    24 => "Lit_O",
    25 => "Lit_P",
    26 => "Lit_{",
    27 => "Lit_}",
    28 => "Enter",
    30 => "Lit_A",
    31 => "Lit_S",
    32 => "Lit_D",
    33 => "Lit_F",
    34 => "Lit_G",
    35 => "Lit_H",
    36 => "Lit_J",
    37 => "Lit_K",
    38 => "Lit_L",
    39 => "Lit_:",
    40 => "Lit_\"",
    43 => "Lit_|",
    44 => "Lit_Z",
    45 => "Lit_X",
    46 => "Lit_C",
    47 => "Lit_V",
    48 => "Lit_B",
    49 => "Lit_N",
    50 => "Lit_M",
    51 => "Lit_<",
    52 => "Lit_>",
    53 => "Lit_?",
    57 => "Lit_ ",
};

my @devs = glob "/dev/input/event*";

my $kbd_dev = undef;

foreach my $dev (@devs) {
    # This is kinda stupid... I need to extract
    # the device number from the name to hand
    # to Linux::Input::Info, just so it can
    # just turn it back into the filename again.
    # *sigh*
    if ($dev =~ m!(\d+)$!) {
	my $num = $1;

	my $i = Linux::Input::Info->new($num);
	# Uniquely matches only the keyboard we're
	# interested in, and only the second
	# input device it registers. (the first
	# is only good for the wacky media keys, I guess)
      	next unless $i && $i->vendor == 7247 && $i->product == 2 && [ $i->bits ]->[4] == 20;

	$kbd_dev = $dev;
	my $name = $i->name;

	# Make X ignore this keyboard so it only
	# controls the roku and doesn't interfere
	# with whatever app has focus.
	system('xinput', 'set-prop', $name, 'Device Enabled', '0') && warn "Failed to disable the device with xinput\n";

	warn Data::Dumper::Dumper($i);

	last;

    }
}

if ($kbd_dev) {
    warn "The keyboard is on $kbd_dev";
}
else {
    die "The keyboard doesn't seem to be available right now.\n";
}

my $kbd = Linux::Input->new($kbd_dev);
my $shift = 0;

while (1) {
    while (my @events = $kbd->poll(0.01)) {
	foreach my $event (@events) {
	    next unless $event->{type} == EV_KEY;

	    if ($event->{code} == $left_shift || $event->{code} == $right_shift) {
		if ($event->{value} == 1) {
		    warn "(shift)\n";
		    $shift = 1;
		}
		elsif ($event->{value} == 0) {
		    warn "(unshift)\n";
		    $shift = 0;
		}
	    }
	    else {
		next unless $event->{value} != 1; # keyup (0) or autorepeat (2)

		my $scancode = $event->{code};
		my $table = $shift ? $uc_keycodes : $lc_keycodes;

		if (my $keycode = $table->{$scancode}) {
		    my $url = $roku_kp_url . uri_escape($keycode);
		    my $res = $ua->post($url);
		    warn "$keycode\n";
		}
	    }
	}
    }
}
