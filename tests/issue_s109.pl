# issue s109 - subref dereference generates syntax error code
use Carp::Assert;
my $hour;

@array = (1,2,3,4);

sub gen_iter {
    my ($ndx, $done);
    if(@_ != 0) {	# We have an argument
	$ndx = $_[0];
    }

    return sub {
        return undef if $ndx > scalar(@array);
        return $array[$ndx++] if @_ == 0;
	my $n = $ndx;
	$ndx += $_[0];
	return $array[$n];
    };
}

$tot = 0;
my $next = gen_iter();
while(my $hour = $next->())
{
	$tot += $hour;
}
assert($tot == 10);

$tot = 0;
my $next = gen_iter();
while(my $hour = $next->(2))
{
	$tot += $hour;
}
assert($tot == 4);

print "$0 - test passed!\n";
