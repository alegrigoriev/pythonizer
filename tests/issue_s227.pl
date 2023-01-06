# issue s227 - Brackets not being escaped in interpolated string that almost looks like a hash index
use Carp::Assert;

my $chars = 'abc';
my $code = "sub {\$_[0] =~ s/([$chars])/\$char2entity{\$1} || num_entity(\$1)/ge; }";
assert($code eq 'sub {$_[0] =~ s/([abc])/$char2entity{$1} || num_entity($1)/ge; }');

my $try_backslash_bracket = "\$nothash\{\$1\}$chars";
assert($try_backslash_bracket eq '$nothash{$1}abc');

my %ishash = (key=>'value');
my $try_ishash = "$chars$ishash{key}";
assert($try_ishash eq 'abcvalue');

print "$0 - test passed!\n";
