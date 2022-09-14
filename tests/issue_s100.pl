# issue s100 - for(each) variable is local to the loop and the value should revert back after the loop
# From the doc: "The foreach loop iterates over a normal list value and sets the scalar variable VAR to
# be each element of the list in turn. If the variable is preceded with the keyword my, then it is 
# lexically scoped, and is therefore visible only within the loop. Otherwise, the variable is 
# implicitly local to the loop and regains its former value upon exiting the loop."
use Carp::Assert;

my $file = "file";
my $name = "name";			# test a name with a conflict
my %name = (key=>'value');
sub name { 0 }

my %appears = ();

sub check_file
{
    my $arg = shift;
    assert($file eq $arg);
}

for $file ('a', 'b') {
    $appears{$file} = 1;
    check_file('file');
}
assert($appears{a} == 1);
assert($appears{b} == 1);
assert(scalar(%appears) == 2);

assert($file eq 'file');

foreach $file ('c', 'd') {
    $appears{$file} = 1;
    check_file('file');
}
assert($appears{c} == 1);
assert($appears{d} == 1);
assert(scalar(%appears) == 4);
assert($file eq 'file');

foreach my $file ('e', 'f') {
    $appears{$file} = 1;
    check_file('file');
}
assert($appears{e} == 1);
assert($appears{f} == 1);
assert(scalar(%appears) == 6);
assert($file eq 'file');

foreach my $name ('g', 'h') {
    $appears{$name} = 1;
}
assert($appears{g} == 1);
assert($appears{h} == 1);
assert(scalar(%appears) == 8);
assert($name eq 'name');
assert($name{key} eq 'value');
assert(name() == 0);

foreach my $iter ('i', 'j') {	# make sure we don't change this to 'iter_l'
    $appears{$iter} = 1;
}
assert($appears{i} == 1);
assert($appears{j} == 1);
assert(scalar(%appears) == 10);

for $iter ('k', 'l') {	# shouldn't be 'iter_l' (but it is)
	$appears{$iter} = 1;
}
assert($appears{k} == 1);
assert($appears{l} == 1);
assert(scalar(%appears) == 12);

$cnt = 0;
for($file = 0; $file < 10; $file++) {
	check_file($cnt);
	$cnt++;
}
assert($file ne 'file');
$file = 10;
assert($cnt == 10);

$cnt = 0;
for(my $file = 0; $file < 5; $file++) {
	check_file(10);
	$cnt++;
}
assert($cnt == 5);
assert($file == 10);

$cnt = 0;
for(my $file = 0; $file < 5; $file++) {
	check_file(10);
	$cnt++;
	$file = 6 if $file == 2;	# modify the loop ctr
}
assert($cnt == 3);
assert($file == 10);

$cnt = 0;
for(my $file=0, my $name=6; $file < 6; $file++, $name--) {
	check_file(10);
	assert($file+$name == 6);
}
assert($file == 10);
assert($name eq 'name');

print "$0 - test passed!\n";
