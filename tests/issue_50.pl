# Dereferencing an array ref generates bad code
use Carp::Assert;

@thr = (1, 2, 3);
$threeref = \@thr;
@three = @{$threeref};
assert(scalar(@three) == scalar(@thr) &&
	$three[0] == $thr[0] &&
	$three[1] == $thr[1] &&
	$three[2] == $thr[2]);
@three = @$threeref;
assert(scalar(@three) == scalar(@thr) &&
	$three[0] == $thr[0] &&
	$three[1] == $thr[1] &&
	$three[2] == $thr[2]);

assert($threeref->[0] == 1);
assert($$threeref[0] == 1);

%options = ();
$options{three} = $threeref;
@thre = @{$options{three}};
assert(scalar(@thre) == scalar(@thr) &&
	$thre[0] == $thr[0] &&
	$thre[1] == $thr[1] &&
	$thre[2] == $thr[2]);

my $hr = {name=>'Foo', email=>'foo@corp.com'};
my %h = %$hr;
assert($h{name} eq 'Foo' && $hr->{name} eq 'Foo' && $$hr{name} eq 'Foo');
assert("$h{name}" eq 'Foo' && "$hr->{name}" eq 'Foo' && "$$hr{name}" eq 'Foo');
my %s = %{$hr};
assert($s{name} eq 'Foo');
assert("$s{name}" eq 'Foo');

$gr = {name=>'Foo', email=>'foo@corp.com'};
%g = %$gr;
assert($g{name} eq 'Foo' && $gr->{name} eq 'Foo' && $$gr{name} eq 'Foo');
assert("$g{name}" eq 'Foo' && "$gr->{name}" eq 'Foo' && "$$gr{name}" eq 'Foo');
%gs = %{$gr};
assert($gs{name} eq 'Foo');
assert("$gs{name}" eq 'Foo');


print "$0 - test passed!\n";
