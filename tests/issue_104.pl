# issue 104 - The index/rindex functions generate bad code
use Carp::Assert;

my @tt_list = ('a', 'bcdefedcb');
my $j = 0;
my $i = 2;
my $word = 'abcdef';
$k=index($tt_list[$j+1], substr($word,$i,1));
assert($k == 1);
$k=rindex($tt_list[$j+1], substr($word,$i,1));
assert($k == 7);

print "$0 - test passed!\n";
