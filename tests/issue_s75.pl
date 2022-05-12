# issue s75 - for(each) loop with multiple list items doesn't work

use Carp::Assert;

%h1 = (a=>1, b=>1);
%h2 = (c=>1, d=>1);

for my $name ( keys %h1, keys %h2 ) {
	if(exists($h1{$name})) {
		$h1{$name}++;
	} else {
		$h2{$name}++;
	}
}

assert(%h1 == 2);
assert(%h2 == 2);
assert($h1{a} == 2 && $h1{b} == 2);
assert($h2{c} == 2 && $h2{c} == 2);

print "$0 - test passed!\n";
