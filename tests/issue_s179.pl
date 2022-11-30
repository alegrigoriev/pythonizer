# issue s179 - Conditional eval generates bad code
use Carp::Assert;
use Getopt::Std;

$i = 0;
sub mysub {
    $i = 1;
}

eval 'mysub()' unless 1==2;
assert($i == 1);

# same issue on the re E flag

my $str = 'abc';
$str =~ s/abc/'def'/e unless 1==2;
assert($str == 'def');

my $ok = getopts('abc') unless 1==2;
assert($ok == 1);

print "$0 - test passed!\n";
