# issue 111: Patterns containing array or hash lookups generate bad code

use Carp::Assert;

my @arr = ('LIFE', 'party');
my %hash = (key=>'value', value=>'key');

my $i = 'to';
my $j = 'from';
my $val = 'value';

my $sentence = "Happiness is the key to life";

assert($sentence =~ /$arr[0]/i);

if($sentence =~ /$hash{value}/) {
    ;   # good
} else {
    assert(0);
}

assert($sentence =~ /$hash{$val}/);
assert($sentence !~ m'$hash{$val}');
assert($sentence =~ m"$hash{$val}");
assert($sentence =~ /the $hash{$val} to/);

$sentence =~ s/$hash{value}/$hash{key}/;

assert($sentence eq 'Happiness is the value to life');

$sentence =~ s/$arr[0]$/$arr[1]/i;

assert($sentence eq 'Happiness is the value to party');

$sentence =~ s'$i'$j'g; # Should do nothing

assert($sentence eq 'Happiness is the value to party');

$sentence =~ s/$i/$j/g;

assert($sentence eq 'Happiness is the value from party');

print "$0 - test passed!\n";

