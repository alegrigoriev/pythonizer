# issue 106: String as regex, issue 112, !~ generates the same code as =~

use Carp::Assert;

$browser = "IE version 2";
assert($browser =~ "IE");
assert($browser !~ "Firefox");

$ie = "IE";
assert($browser =~ $ie);
$firefox = "Firefox";
assert($browser !~ $firefox);

@arie = ('', 'IE', 'Firefox');
assert($browser =~ $arie[1]);
assert($browser !~ $arie[2]);

assert(lc($browser) =~ lc($ie));
assert(lc($browser) !~ lc($firefox));

assert($browser =~ "IE" && lc($browser) =~ lc($ie));
assert($browser !~ "Firefox" && lc($browser) !~ lc($firefox));

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
