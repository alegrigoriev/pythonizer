# issue with gmtime/localtime, etc
use Carp::Assert;
use Time::Local;

BEGIN {
    #$ENV{TZ} = 'America/New_York';
}

# In scalar context, localtime returns the ctime(3) value
for(my $i = 0; $i < 5; $i++) {
    $tm = time;
    $ct = localtime;
    $ct0 = localtime $tm;
    last if $ct eq $ct0;
}
$ct1 = localtime 44444;
$rep_time = 44444;
$slt = scalar(localtime($rep_time));
#print "$tm, $ct, $ct0, $ct1, $slt\n";
assert($tm > 1622775721);               # Time when I wrote this test
assert($ct eq $ct0);
assert($ct1 eq "Thu Jan  1 07:20:44 1970");     # assumes eastern timezone
assert($slt eq "Thu Jan  1 07:20:44 1970");     # assumes eastern timezone

$gt = gmtime;
$gt0 = gmtime $tm;
$gt1 = gmtime 44444;
$sgm = scalar(gmtime($rep_time));
#print "$gt, $gt0, $gt1, $sgm\n";
assert($gt eq $gt0);
assert($gt1 eq 'Thu Jan  1 12:20:44 1970');
assert($sgm eq 'Thu Jan  1 12:20:44 1970');


@lcl = localtime 3155815555;
@gmt = gmtime 3155815555;
$tgm = timegm(@gmt);
$tlc = timelocal(@lcl);
#print "@lcl, @gmt, $tgm, $tlc\n";
assert(join(' ', @lcl) eq '55 25 10 1 0 170 3 0 0');
assert(join(' ', @gmt) eq '55 25 15 1 0 170 3 0 0');
assert($tgm == 3155815555);
assert($tlc == 3155815555);

$tgm = timegm(1, 2, 3, 4, 5, 2021-1900);
@gmt = gmtime $tgm;
#print "$tgm, @gmt\n";
assert($tgm == 1622775721);
assert(join(' ', @gmt) eq '1 2 3 4 5 121 5 154 0');
$tlc = timelocal(1, 2, 3, 4, 5, 2021-1900);
@lcl = localtime $tlc;
#print "$tlc, @lcl\n";
assert($tlc == 1622790121);             # Assumes Eastern timezone
assert(join(' ', @lcl) eq '1 2 3 4 5 121 5 154 1');     # Assumes Eastern timezone

print "$0 - test passed!\n";
