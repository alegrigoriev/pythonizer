# test replace usage option (-u)

use Carp::Assert;

my $py = ($0 =~ /.py$/ ? 1 : "");

my $usage = "Usage: test_replace_usage.pl";
my $u2 = 'Usage: test_replace_usage.pl';
my $u3 = q/Usage: test_replace_usage.pl/;
my $u4 = qq/Usage: test_replace_usage.pl/;
my $u5 = "Usage: test_replace_usage.pl $py";

my $n1 = 'Usage test_replace_usage.pl';
my $n2 = 'Usage: replace_usage.pl';
my $n3 = ' Usage: test_replace_usage.pl';
my $n4 = "Usage: test_replace_usage";

if($py) {
    assert($usage eq 'Usage: test_replace_usage.' . 'py');
    assert($u2 eq 'Usage: test_replace_usage.' . 'py');
    assert($u3 eq 'Usage: test_replace_usage.' . 'py');
    assert($u4 eq 'Usage: test_replace_usage.' . 'py');
    assert($u5 eq 'Usage: test_replace_usage.' . 'py 1');
} else {
    assert($usage eq 'Usage: test_replace_usage.' . 'pl');
    assert($u2 eq 'Usage: test_replace_usage.' . 'pl');
    assert($u3 eq 'Usage: test_replace_usage.' . 'pl');
    assert($u4 eq 'Usage: test_replace_usage.' . 'pl');
    assert($u5 eq 'Usage: test_replace_usage.' . 'pl ');
}

assert($n1 eq 'Usage test_replace_usage.' . 'pl');
assert($n2 eq 'Usage: replace_usage.' . 'pl');
assert($n3 eq ' Usage: test_replace_usage.' . 'pl');
assert($n4 eq 'Usage: test_replace_usage');

print "$0 - test passed!\n";
