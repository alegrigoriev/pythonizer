# pragma pythonizer -s
# Written by chatGPT
# This one needs to be adjusted to check that the actual is >= the expected but not completely out of bounds, using an epsilon.

use Time::HiRes qw(usleep nanosleep);
use Time::HiRes qw/d_usleep d_ualarm d_gettimeofday d_getitimer d_setitimer
                 d_nanosleep d_clock_gettime d_clock_getres
                 d_clock d_clock_nanosleep d_hires_stat
                 d_futimens d_utimensat d_hires_utime/;
use Carp::Assert;

use constant EPS => 0.022;

sub test_time_hires {
    my $test_cases = shift;

    for my $name (keys %$test_cases) {
        my $input = $test_cases->{$name}{input};
        my $expected = $test_cases->{$name}{output};

        # Determine which function to call based on the test case name
        my $function;
        if ($name =~ /^usleep/) {
            $function = \&usleep;
            assert(d_usleep);
        } elsif ($name =~ /^nanosleep/) {
            $function = \&nanosleep;
            assert(d_nanosleep);
        }

        my $start = Time::HiRes::time();
        $function->($input);
        my $elapsed = Time::HiRes::time() - $start;

        assert(($elapsed - $expected) < EPS, "Test case failed: $name, elapsed=$elapsed, expected=$expected");
        #print("Test case $name, elapsed=$elapsed, expected=$expected\n");
    }
}

# Test cases
my %test_cases = (
    usleep_10ms => {
        input => 10000,
        output => 0.01,
    },
    usleep_100ms => {
        input => 100000,
        output => 0.1,
    },
    nanosleep_10ms => {
        input => 10000000,
        output => 0.01,
    },
    nanosleep_100ms => {
        input => 100000000,
        output => 0.1,
    },
);

test_time_hires(\%test_cases);

use Time::HiRes qw(utime gettimeofday tv_interval);

sub test_stat {
    assert(d_hires_stat);
    my $file = shift;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = Time::HiRes::stat($file);
    my ($sdev,$sino,$smode,$snlink,$suid,$sgid,$srdev,$ssize,$satime,$smtime,$sctime,$sblksize,$sblocks) = stat($file);

    assert($dev == $sdev);
    assert($ino == $sino);
    assert($mode == $smode);
    assert($nlink == $snlink);
    assert($uid == $suid);
    assert($gid == $sgid);
    assert($rdev == $srdev);
    assert($size == $ssize);
    assert($blksize == $sblksize);
    assert($blocks == $sblocks);

    assert(abs($atime - $satime) <= 1);
    assert(abs($mtime - $smtime) <= 1);
    assert(abs($ctime - $sctime) <= 1);
}

sub test_lstat {
    my $file = shift;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = Time::HiRes::lstat($file);
    my ($sdev,$sino,$smode,$snlink,$suid,$sgid,$srdev,$ssize,$satime,$smtime,$sctime,$sblksize,$sblocks) = lstat($file);

    assert($dev == $sdev);
    assert($ino == $sino);
    assert($mode == $smode);
    assert($nlink == $snlink);
    assert($uid == $suid);
    assert($gid == $sgid);
    assert($rdev == $srdev);
    assert($size == $ssize);
    assert($blksize == $sblksize);
    assert($blocks == $sblocks);

    assert(abs($atime - $satime) <= 1);
    assert(abs($mtime - $smtime) <= 1);
    assert(abs($ctime - $sctime) <= 1);
}

sub test_utime {
    assert(d_hires_utime);
    my ($file, $atime, $mtime) = @_;

    my $res = utime($atime, $mtime, $file);
    assert($res == 1);
    my (undef,undef,undef,undef,undef,undef,undef,undef,$natime,$nmtime,$nctime,undef,undef) = Time::HiRes::stat($file);
    assert(abs($atime - $natime) < EPS, "atime: $atime vs $natime after utime call");
    assert(abs($mtime - $nmtime) < EPS, "mtime: $mtime vs $nmtime after utime call");
}

sub test_gettimeofday {
    assert(d_gettimeofday);
    my ($seconds, $microseconds) = gettimeofday();
    my ($tsec, $tmic) = (time(), 0);
    assert(abs($tsec - $seconds) <= 1);
}

sub test_time {
    my $seconds = Time::HiRes::time();
    my $tsec = time;
    assert(abs($tsec - $seconds) <= 1);
}

sub test_clock_gettime {
    assert(d_clock_gettime);
    my $seconds = Time::HiRes::clock_gettime(Time::HiRes::CLOCK_REALTIME);
    my $tsec = time;
    return if $seconds < 0;     # It does this on Windows
    #print "seconds = $seconds, tsec=$tsec\n";
    assert(abs($tsec - $seconds) <= 1);
}

sub test_clock_getres {
    assert(d_clock_getres);
    my $res = Time::HiRes::clock_getres(Time::HiRes::CLOCK_REALTIME);
    return if $res < 0;     # It does this on Windows
    assert($res <= 1);
}

sub test_clock {
    assert(d_clock);
    my $t0 = Time::HiRes::clock();
    my $seconds0 = Time::HiRes::time();
    for(my $i = 0; $i < 20000000; $i++) { # Burn some time
        $cnt++;
    }
    my $t1 = Time::HiRes::clock();
    my $seconds1 = Time::HiRes::time();
    #print STDERR ($t1 - $t0) . "\n";
    assert($t1 > $t0, "check that clock incremented didn't increment");
    assert(abs(abs($seconds1-$seconds0) - abs($t1-$t0)) < EPS*2.5, "clock and time intervals are not close");
}

sub test_tv_interval {
    my ($t1, $t2) = @_;

    my $interval = tv_interval($t1, $t2);
    assert($interval >= 0.5 && $interval < 0.6, "Interval should be between 0.5 and 0.6 but is $interval!");
}

# Test cases
my $file = 'tmp.tmp';
open(TMP, '>tmp.tmp');
close(TMP);
my $atime = Time::HiRes::time;
my $mtime = Time::HiRes::time;
my $t1 = [gettimeofday];
Time::HiRes::sleep(0.5);
my $t2 = [gettimeofday];

test_stat($file);
test_lstat($file);
test_utime($file, $atime, $mtime);
test_gettimeofday();
test_time();
test_clock_gettime();
test_clock_getres();
test_clock();
test_tv_interval($t1, $t2);

# More tests. Some of these don't work on Windows:

my $py = ($0 =~ /\.py$/);

use Time::HiRes qw(alarm);
use constant EPS2 => 0.05;

sub test_alarm {
  my $time = 0.1; # 100 milliseconds

  # Capture if we got the alarm
  my $raised = 0;
  local $SIG{ALRM} = sub { $raised = 1 };

  # set an alarm for 100 milliseconds
  alarm $time;

  # get the current time
  my $start = Time::HiRes::time();

  # wait for the alarm to be raised
  my $i = 0;
  while (!$raised && $i++ < 20) { Time::HiRes::sleep(0.05) }

  # get the time after the alarm has been raised
  my $end = Time::HiRes::time();

  # calculate the difference in time
  my $difference = $end - $start;

  assert($raised, "The alarm set for $time was not raised after waiting for $difference");

  # assert that the difference is close to the desired time
  assert($difference >= $time - EPS2 && $difference <= $time + EPS2,
         "The alarm was not raised for the expected amount of time. Diff: $difference, Time: $time");
}

if ($^O ne 'MSWin32') {
  test_alarm();
}

use Carp::Assert;
use Time::HiRes qw(ualarm);

sub test_ualarm {
    assert(d_ualarm);
    my $signal_received = 0;

    local $SIG{ALRM} = sub { $signal_received = 1 };

    # set an alarm for 100ms
    ualarm(100_000);

    # wait for the alarm to go off or until 200ms have passed
    my $i = 0;
    while (!$signal_received && $i++ < 20) { Time::HiRes::sleep(0.05) }

    assert($signal_received, "ualarm signal was not received");
}

test_ualarm() if ($^O ne 'MSWin32');
assert(!d_ualarm) if ($^O eq 'MSWin32');

use Time::HiRes qw(setitimer getitimer ITIMER_REAL);

sub test_setitimer_getitimer {
    assert(d_getitimer); assert(d_setitimer);
    my $count = 0;
    local $SIG{ALRM} = sub { $count++ };

    my $time = 0.1; # set the timer for 100 milliseconds
    setitimer(ITIMER_REAL, $time, 0);

    my ($it_value, $it_interval) = getitimer(ITIMER_REAL);
    assert($it_value <= $time, "The returned value should be equal to or less than the set time.");
    assert($it_interval == 0, "The returned interval should be 0.");

    # wait for the signal to be delivered
    my $i = 0;
    while($count == 0 && $i++ < 20) {
        sleep($time);
    }
    assert($count == 1, "The signal should have been delivered exactly once, but count = $count.");
}

test_setitimer_getitimer() if ($^O ne 'MSWin32' && $^O ne 'msys');
do {assert(!d_getitimer);
    assert(!d_setitimer);} if ($^O eq 'MSWin32');

use Time::HiRes qw( clock_nanosleep );

sub test_clock_nanosleep {
    assert(d_clock_nanosleep);
    my $which = Time::HiRes::CLOCK_REALTIME;
    my $flags = 0;
    my $sleep_time = 100_000_000; # 100 milliseconds in nanoseconds

    my $start = Time::HiRes::time();
    assert(clock_nanosleep($which, $sleep_time, $flags) > 0);
    my $end = Time::HiRes::time();
    my $elapsed = $end - $start;
    $elapsed *= 1_000_000_000;      # Nanoseconds
    $fudge = 300_000;

    assert($elapsed >= $sleep_time-$fudge, "Elapsed time ($elapsed) should be at least $sleep_time");
}

test_clock_nanosleep() if ($^O ne 'MSWin32' || $py);

use strict;
use warnings;
use Time::HiRes qw( clock_nanosleep CLOCK_REALTIME TIMER_ABSTIME );
use Carp::Assert;

sub test_clock_nanosleep_TIMER_ABSTIME {
    my $current_time = Time::HiRes::time();
    my $sleep_until = $current_time + 0.5; # sleep for 500ms

    my $ret = clock_nanosleep(CLOCK_REALTIME, $sleep_until * 1_000_000_000, TIMER_ABSTIME);
    assert($ret >= $current_time, "clock_nanosleep failed with ret = $ret vs $current_time");

    my $elapsed = Time::HiRes::time() - $current_time;
    assert($elapsed >= 0.1, "Expected at least 100ms elapsed time, but got $elapsed");
}

test_clock_nanosleep_TIMER_ABSTIME() if($^O ne 'MSWin32' || $py);

# Make sure we're calling the proper routines in the generated code:

if($py) {
    open(SOURCE, '<', $0);
    my @lines = <SOURCE>;
    close(SOURCE);
    assert((grep { /(?:_stat\(|perllib.stat\()/ } @lines), "Can't find call to perllib.stat or _stat in generated code!");
    assert((grep { /hires_stat\(/ } @lines), "Can't find call to hires_stat in generated code!");
    assert((grep { /hires_utime\(/ } @lines), "Can't find call to hires_utime in generated code!");
    assert((grep { /hires_alarm\(/ } @lines), "Can't find call to hires_alarm in generated code!");
}

END {
    unlink "tmp.tmp";
}

print "$0 - test passed!\n";
