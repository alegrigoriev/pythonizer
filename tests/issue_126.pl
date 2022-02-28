# Hash initialization generates bad code if there are any expressions on the RHS
use Carp::Assert;
#use Data::Dumper;

my %h1 = (k1=>'v1', k2=>'v2');
assert(%h1 == 2);
assert($h1{k1} eq 'v1' && $h1{k2} eq 'v2');

sub echo
{
    return $_[0];
}

my %h2 = (echo('k1')=>echo('v1'), echo('k2')=>echo('v2'));
assert(%h2 == 2);
assert($h2{k1} eq 'v1' && $h2{k2} eq 'v2');

my %h3 = ((echo('k').'1')=>(echo('v').'1'), (echo('k').echo('2'))=>(echo('v').echo('2')));
assert(%h3 == 2);
assert($h3{k1} eq 'v1' && $h3{k2} eq 'v2');

my @arr = ('k3', 'k4');
my %h4 = (%h3, map { $_ => s/k/v/r } @arr);
assert(%h4 == 4);
assert($h4{k1} eq 'v1' && $h4{k2} eq 'v2');
assert($h4{k3} eq 'v3' && $h4{k4} eq 'v4');

print "$0 - test passed!\n";
