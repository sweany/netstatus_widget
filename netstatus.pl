#! /usr/bin/perl -w

# netstatus Tk widget
# since none of the vista/7 widgets are worth a damn
# ping a list of hosts and display the latency

# Run "enc2xs -C" to avoid the ConfigLocal.pm error

#perl2exe_include Tk::Canvas
#perl2exe_include Tk::Scale

use strict;
use Tk;
require Tk::ROText;
use IO::Socket;
use IO::Select;

use Time::HiRes;
use Net::Ping;

use vars qw(%CONF);


%CONF = (
	'interval' => 10, # how often to poll
	'maxhosts' => 3, # how many hosts can we poll
	'lastinterval' => 0,
	'statefile' => 'netstatus.conf',
	'BG_MAIN' => '#222222',
	'BG_FRAME' => '#444444',
	'plotw' => 150,
	'ploth' => 24,
);

# create main window
my $mw = MainWindow->new;
# set title of main window
$mw->title("NetStatus widget");

# make title bar a bit smaller, lose minimize/maximize buttons
$mw->after(250,sub {$mw->attributes(-toolwindow=>1)});





# configure main window options
$mw->configure(
	-relief => "sunken",
	-bg => $CONF{BG_MAIN},
	#-padx => 10,
	#-pady => 10
);
$mw->minsize(200,50);
#$mw->optionAdd('*font', 'Helvetica 8');


################################################################################
#  Frames
################################################################################

# top frame inside main window
my $topwin = $mw->Frame(
#	-width => 650,
	-padx => 5,
	-pady => 5,
	-bg => $CONF{BG_FRAME}
)->pack(-fill => "x", -expand => 1, -anchor => "n");


################################################################################
#  Widgets
################################################################################

my $label_host = $topwin->Label(
	-bg => $CONF{BG_FRAME},
	-foreground => 'white',
	-text => 'hostname or IP address',
);

my $label_history = $topwin->Label(
	-bg => $CONF{BG_FRAME},
	-foreground => 'white',
	-text => 'latency history',
);


# create an input field for the latest poll period
my $entry_timestamp = $topwin->Entry(
	-text => '',
	-bg => 'black',
	-foreground => 'green',
	-font => 'Helvetica 8 bold',
	-width => 17,
	-relief => 'flat'
);

my $hostentries = [];
my $resultentries = [];
my $plots = [];
my @xvalues;
for (my $i = 0; $i < $CONF{maxhosts}; $i++) {
	$xvalues[$i] = $CONF{plotw};
}

for (my $i = 0; $i < $CONF{maxhosts}; $i++) {
	$hostentries->[$i] = $topwin->Entry(
		-relief => 'flat',
		-text => '',
		-bg => 'white',
		-width => 24
	);

	# ping plots
	$plots->[$i] = $topwin->Canvas (
		-width => $CONF{plotw},
		-height => $CONF{ploth},
		-bg => 'black',
		-highlightthickness => 0,
		-relief => 'flat',
		-borderwidth => 0,
	)->pack();

	# history
	my @fg = ('#FF0000','#CC0000','#990000','#660000','#330000');
	for (my $j = 0; $j < 5; $j++) {
		$resultentries->[$i][$j] =  $topwin->Entry(
			-relief => 'flat',
			-text => '',
			-font => 'Helvetica 8 bold',
			-foreground => $fg[$j],
			-bg => 'white',
			-width => 5
		);
	}

}

# ping interval
my $entry_interval = $topwin->Entry(
	-relief => 'flat',
	-text => $CONF{interval},
	-font => 'Helvetica 8',
	-foreground => 'white',
	-bg => '#222266',
	-width => 2
);
my $scale_interval = $topwin->Scale(
	-command => sub { my $value = shift; $value = 1 if ($value < 1); $CONF{interval} = $value; $entry_interval->configure( -text => $value ); },
	-bg => $CONF{BG_FRAME},
	-activebackground => 'red',
	-highlightbackground => $CONF{BG_FRAME},
	-fg => 'white',
	-from => 0,
	-to => 60,
	-orient => 'horizontal',
	-font => 'Fixed 6 normal',
	-borderwidth => 0,
	-showvalue => 0,
	-label => 'ping interval',
	-width => 20,
	-length => 150,
	-resolution => 1,
	-sliderlength => 15,
	-tickinterval => 10,
);
$scale_interval->set($CONF{interval});

# save host list button
my $button_save = $topwin->Button(
	-text => 'Save host list',
	-command => sub {
	# write host list to state file
	open(FILE,">$CONF{statefile}");
	for (my $i = 0; $i < 3; $i++) {
		my $host = $hostentries->[$i]->get;
		print FILE "$host\n";
	}
	close FILE;
	print "Saved to $CONF{statefile}\n";
});



################################################################################
#  Grid Layout
################################################################################

# Frames in main window

$topwin->grid(-row => 0, -column => 0, -sticky => "nsew");

$mw->gridColumnconfigure(0, -weight => 1);
$mw->gridRowconfigure(0, -weight => 1);

$entry_timestamp->grid(-row => 0, -column => 0, -columnspan => 5);

$label_host->grid(-row => 1, -column => 0, -columnspan => 1);
$label_history->grid(-row => 1, -column => 1, -columnspan => 3);

# host addresses, ping history, plots
for (my $i = 0; $i < $CONF{maxhosts}; $i++) {
	$hostentries->[$i]->grid(-row => $i+2, -column => 0, -padx => 10, -sticky => "e");
	$resultentries->[$i][0]->grid(-row => $i+2, -column => 1, -sticky => "e");
	$resultentries->[$i][1]->grid(-row => $i+2, -column => 2, -sticky => "e");
	$resultentries->[$i][2]->grid(-row => $i+2, -column => 3, -sticky => "e");
	$resultentries->[$i][3]->grid(-row => $i+2, -column => 4, -sticky => "e");
	$resultentries->[$i][4]->grid(-row => $i+2, -column => 5, -sticky => "e");
	$plots->[$i]->grid(-row => $i+2, -column => 6, -sticky => "w");
}

# ping interval scale
$scale_interval->grid(-row => 8, -column => 0, -sticky => "e");
$entry_interval->grid(-row => 8, -column => 1, -sticky => "w");

# Save button
$button_save->grid(-row => 8, -column => 2, -columnspan => 2);


# set resize weight on all cells in the grid
my ($columns, $rows) = $topwin->gridSize( );
for (my $i = 0; $i < $columns; $i++) {
  $topwin->gridColumnconfigure($i, -weight => 1);
}
for (my $i = 0; $i < $rows; $i++) {
  $topwin->gridRowconfigure($i, -weight => 1);
}

# assign focus to the main entry item
#$entry_timestamp->focus;


################################################################################
#  Timers
################################################################################



# see if any new messages have arrived
#my $timer = $topwin->repeat($CONF{interval} * 1000, \&pingcycle);

my $timer_modinterval = $topwin->repeat(1000, sub {
	# check to see if a change in interval has occurred
	if ($CONF{interval} != $CONF{lastinterval}) {
		if (exists $CONF{pingcycle}) {
			$CONF{pingcycle}->cancel;
		}
		print "Changing ping interval to $CONF{interval} seconds\n";
		$CONF{pingcycle} = $topwin->repeat($CONF{interval} * 1000, \&pingcycle);
	}
	$CONF{lastinterval} = $CONF{interval};
});

sub pingcycle {
	# ping all the hosts

	my $p = Net::Ping->new("icmp"); # ICMP requires root/admin rights
	$p->hires(1);
	for (my $i = 0; $i < $CONF{maxhosts}; $i++) {
		my $host = $hostentries->[$i]->get;
		if ($host ne "") {
			# shift previous values over
			$resultentries->[$i][4]->configure( -text => $resultentries->[$i][3]->get );
			$resultentries->[$i][3]->configure( -text => $resultentries->[$i][2]->get );
			$resultentries->[$i][2]->configure( -text => $resultentries->[$i][1]->get );
			$resultentries->[$i][1]->configure( -text => $resultentries->[$i][0]->get );
			print "testing $host... "; 
			my $time0 = Time::HiRes::time;
			my $result = $p->ping($host,0.51);
			my $time1 = Time::HiRes::time;
			my $latency = ($time1 - $time0)*1000;
			printf("$result: %.1f\n", $latency);
			if ($result == 1) {
				$resultentries->[$i][0]->configure( -text => sprintf("%4d", $latency +0.5) );
			} else {
				$resultentries->[$i][0]->configure( -text => "down" );
			}

			# experimental; plot the pign values
			$plots->[$i]->configure( -xscrollincrement => 1);
			$plots->[$i]->xviewScroll(1, 'units');
			$xvalues[$i] += 1;
			#$CONF{x} = $CONF{plotw} if ($CONF{x} < 0); # don't need this since we're scrolling
			my $y = 2 + int($CONF{ploth} * ($latency/200));
			#my $z = int($CONF{ploth} * (log($latency)/log(2))/200);
			#print "Linear: $y    log2: $z\n";

			my $color = 'green';
			if ($latency > 150) {
				$color = 'red';
			} elsif ($latency > 100) {
				$color = 'orange';
			} elsif ($latency > 50) {
				$color = 'yellow';
			}
			#$canvas_plot->create('line', $CONF{x}, $CONF{ploth}, $CONF{x}, $CONF{ploth} - $CONF{y}, -fill => $color); # y axis is inverted
			
			$plots->[$i]->create('line', $xvalues[$i], $CONF{ploth}, $xvalues[$i], $CONF{ploth} - $y, -fill => $color); # y axis is inverted
		}
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$entry_timestamp->configure( -text => sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1,$mday,$hour,$min,$sec ) );
}





################################################################################
#  Other initialization
################################################################################

# read in host list
if (-f $CONF{statefile}) {
	open(FILE,"<$CONF{statefile}");
	my $i = 0;
	while (my $line = <FILE>) {
		chomp($line);
		$line =~ s/[^a-zA-Z0-9\.\-]//g;
		$hostentries->[$i]->configure( -text => $line);
		$i += 1;
		print "read $line from statefile\n";
	}
	close FILE;
}





################################################################################
#  Main Loop
################################################################################

# execute first pingcycle at startup
pingcycle();

# execute main window loop
MainLoop;

