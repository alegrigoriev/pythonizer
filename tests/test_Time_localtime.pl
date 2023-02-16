use Carp::Assert;
use Time::localtime qw/:FIELDS/;

# Test that the Time::localtime module is installed and available
assert(defined &Time::localtime::localtime);

# Test localtime() without arguments
my ($tm, @time);
for(my $i = 0; $i < 100; $i++) {
    $tm = localtime();
    @time = CORE::localtime();
    last if $tm->sec == $time[0];
    if($i > 10) {
        assert(0, "Can't synch localtime calls after 10 tries!");
    }
}
assert(ref $tm eq "Time::tm");

# Test ctime()
my $time_str = ctime();
assert($time_str =~ /^[A-Za-z]{3} [A-Za-z]{3} [ \d]\d [ \d]\d:\d\d:\d\d [ \d]{4}$/);

# Test methods on the "Time::tm" object
assert($tm->sec == $time[0]);
assert($tm->min == $time[1]);
assert($tm->hour == $time[2]);
assert($tm->mday == $time[3]);
assert($tm->mon == $time[4]);
assert($tm->year == $time[5]);
assert($tm->wday == $time[6]);
assert($tm->yday == $time[7]);
assert($tm->isdst == $time[8]);

assert($tm_mday == $tm->mday);
assert($tm_sec == $tm->sec);
assert($tm_year == $tm->year);

# Test localtime() with a specified time value
my $timestamp = time() - 86400; # 1 day in the past
$tm2 = localtime($timestamp);
assert($tm2->mday == (CORE::localtime())[3] - 1); # day should be 1 less than current day


print "$0 - test passed\n";
