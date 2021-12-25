# issue 106: String as regex

use Carp::Assert;

$browser = "IE version 2";
assert($browser =~ "IE");

$ie = "IE";
assert($browser =~ $ie);

@arie = ('', 'IE');
assert($browser =~ $arie[1]);

assert(lc($browser) =~ lc($ie));

assert($browser =~ "IE" && lc($browser) =~ lc($ie));

# this is what the code is supposed to be:
$cnt = 0;
my $param_value = "param";
@words = ('nope', 'par', 'PAR');

for $word (@words) {
    if (lc($param_value) =~ lc $word) {
        $cnt++;
        assert(lc $word eq 'par');
    }
}
assert($cnt == 2);

# As it was written in the code:

$word = 'PAR';
$param_value = 'param';
$cnt = 0;
if (lc $param_value  =~ lc $word) {
    $cnt++;
}
assert($cnt == 1);

#$param_value = 'Param';
#if (lc $param_value  =~ lc $word) {
#assert(0);
#}

print "$0 - test passed!\n";
