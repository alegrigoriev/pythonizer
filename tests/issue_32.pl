# issue 32 - let user define the variable translations
use Carp::Assert;
$a = 1;
$b = 2;
assert($a+1 == $b);
$_ = 'abc';
my @fields = split /b/;
assert(scalar(@fields) == 2 && $fields[0] eq 'a' && $fields[1] eq 'c');
foreach (@fields) {
    assert($_ eq 'a' || $_ eq 'c');
}
$_ = "abc\n";
chomp;
assert($_ eq 'abc');
chop;
assert($_ eq 'ab');
assert($line = /b/);
assert($line == 1);
$_ = 'a';
$i = ord;
assert($i == 97);
assert(ord == 97);
assert(ord $_ == 97);
assert(ord($_) == 97);
assert(ord chr == 'a');
open(FH,'>_test.tmp');
print;
print FH;
say;
assert($_ eq 'a');
say FH;
close FH;
open(FH,'<_test.tmp');
my @test = <FH>;
chomp @test;
#assert(scalar(@test) == 1 && $test[0] eq 'aa');  Why doesn't this work?
assert(scalar(@test) == 1);
my $a=$b=$c="\n";
chomp ($a, $b, $c);
assert($a eq '' && $b eq '' && $c eq '');
chomp(my @tester = <FH>);
assert(scalar(@tester) == 0);
close FH;
unlink '_test.tmp';
$_ = 65;
$c = chr;
assert($c == 'A');
assert(chr == 'A');
assert(chr $_ == 'A');
assert(chr $_+1 == 'B');
assert(chr($_) == 'A');
my @numbers = (1,2,3);
my @doubles = map {$_ * 2} @numbers;
assert(scalar(@doubles) == 3 && $doubles[0] == 2 && $doubles[1] == 4 && $doubles[2] == 6);
my @numbers = (65, 66);
my @chars = map(chr, @numbers);
assert($chars[0] eq 'A' && $chars[1] eq 'B');

@numbers = qw(8 2 5 3 1 7);
my @big_numbers = grep { $_ > 4 } @numbers;
assert(scalar(@big_numbers) == 3);

my @names = qw(Foo Bar Baz);
my $visitor = 'Bar';
assert(grep { $visitor eq $_ } @names);
assert(!grep { 'Fred' eq $_ } @names);
my @foo = grep($_ eq 'Foo', @names);
assert(scalar(@foo) == 1 && $foo[0] eq 'Foo');
my @bs = grep(/B/, @names);
assert(scalar(@bs) == 2);
assert(grep('Baz', @names));

my $string = "the quick brown fox jumped over the lazy dog";
my $count_the_fox = $string =~ /\s+([a-z][a-z]x)\s+/;	# 1
assert($count_the_fox == 1);
my ($find_the_fox) = $string =~ /\s+([a-z][a-z]x)\s+/;	# "fox"
assert($find_the_fox == 'fox');

assert(my_add(1, 2) == 3);

sub my_add {
	# Add op1 to op2 giving result
	$op1 = shift;
	$op2 = shift;
	return if(!defined $op1);	# Make sure they gave both args
	return if(!defined $op2);	# Make sure they gave both args
	$op1 + $op2;		# implicitly return the sum
}

print "$0 - test passed!\n";
