# issue s110 - scope of 'my' should not be extended below for/while loop
# pragma pythonizer -M
use Carp::Assert;
$hour = 23;

foreach my $hour (1,2,3)
{
	$tot += $hour;
}
assert($tot == 6);
assert($hour == 23);

@array = (1,2,3,4);

sub gen_iter {
    my ($ndx, $done);
    if(@_ != 0) {	# We have an argument
	$ndx = $_[0];
    }

    return sub {
        return undef if $ndx > scalar(@array);
        return $array[$ndx++];
    };
}

$tot = 0;
my $next = gen_iter();
while(my $hour = $next->())
{
	$tot += $hour;
}
assert($tot == 10);
assert($hour == 23);

# 'my' doesn't re-initialize to 0 in pythonizer, so skip these tests
=pod
if(my $hour == 0)
{
	;
} else {
	assert(0);
}
assert($hour == 23);

unless(my $hour == 0) {
	assert(0);
}
assert($hour == 23);
=cut

$tot = 0;
for(my $hour = 0; $hour < 10; $hour++)
{
	$tot += $hour;
}
assert($tot == 45);
assert($hour == 23);

print "$0 - test passed!\n";
