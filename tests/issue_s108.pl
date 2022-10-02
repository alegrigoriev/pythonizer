# issue s108 - for(each) variable is local to the loop and the value should revert back after the loop even if foreach statement is on multiple lines
# This is an additional case for issue s100, found in mcbytes.pl
use Carp::Assert;

$hour = 23;

sub deletefiles
{
    my $tot = 0;
    foreach $file (1,2,3)
    {
	    $tot += $file;
    }
    assert($tot == 6);
    assert($file eq 'file');

    $tot = 0;
    foreach my $file1 (1,2,3)
    {
	    $tot += $file1;
    }
    assert($tot == 6);
    assert($file1 eq 'file1');

    $tot = 0;
    foreach $file2 (1,2,3)
    {
	    $tot += $file2;
    }
    assert($tot == 6);
}
$file = 'file';
$file1 = 'file1';
deletefiles();

my %appears = ();

sub check_hour
{
    my $arg = shift;
    assert($hour == $arg);
}

assert($hour == 23);

@hours = (1,2,3,4);
$total = 0;
for $hour (@hours) 
{
    $total += $hour;
    check_hour($hour);
}
assert($total == 10);
assert($hour == 23);

$total = 0;
#

for 
    $hour 
    (@hours) 
{
    $total += $hour;
    check_hour($hour);
}
assert($total == 10);
assert($hour == 23);

$total = 0;
for my $hour (@hours) 
{
    $total += $hour;
    check_hour(23);
}
assert($total == 10);
assert($hour == 23);

print "$0 - test passed!\n";
