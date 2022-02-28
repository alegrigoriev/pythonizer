# test the map function using examples from the web and from our source code
use Carp::Assert;
#use Data::Dumper;

@myNames = ('jacob', 'alexander', 'ethan', 'andrew');
@ucNames = map(ucfirst, @myNames);
assert(@ucNames == 4);
for(my $i = 0; $i < scalar(@myNames); $i++) {
    assert(ucfirst $myNames[$i] eq $ucNames[$i]);
}

my @names = qw(Foo Bar Baz);
my %invited = map { $_ =~ /^F/ ? ($_ => 1) : () } @names;
assert(scalar(%invited) == 1);
assert($invited{Foo} == 1);
assert(!exists $invited{Bar});

my @opens = qw/O_CREAT O_EXCL O_WRONLY/;
# Map always returns a list, which can be assigned to a hash such that the elements become key/value pairs
my %os_opens = map { $_ => "os.$_" } @opens;
assert(%os_opens == 3);
assert($os_opens{'O_EXCL'} eq 'os.O_EXCL');

our @PYTHON_KEYWORDS = qw(False None True and as assert async await break class continue def del elif else except finally for from global if import in is lambda nonlocal not or pass raise return try while with yield);
our @PYTHON_BUILTINS = qw(abs aiter all any anext ascii bin bool breakpoint bytearray bytes callable chr classmethod compile complex delattr dict dir divmod enumerate eval exec filter float format frozenset getattr globals hasattr hash help hex id input int isinstance issubclass iter len list locals map max memoryview min next object oct open ord pow print property range repr reversed round set setattr slice sorted staticmethod str sum super tuple type vars zip);
our @EXTRA_BUILTINS = qw(Array Hash ArrayHash);
our %PYTHON_KEYWORD_SET = map { $_ => 1 } @PYTHON_KEYWORDS;
our %PYTHON_RESERVED_SET = map { $_ => 1 } (@PYTHON_KEYWORDS, @PYTHON_BUILTINS, @EXTRA_BUILTINS);

assert($PYTHON_KEYWORD_SET{False} == 1);
assert($PYTHON_RESERVED_SET{min} == 1);
assert($PYTHON_RESERVED_SET{False} == 1);
assert($PYTHON_RESERVED_SET{Array} == 1);

# Schwartzian transform

@unsorted=('oranges', 'apples', 'bananas', 'carrots', 'melons');

sub f
{
	my $result = reverse $_[0];
}

my @sorted =
        map  { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
        map  { [$_, f($_)] }
        @unsorted;

assert(join(' ', @sorted) eq 'bananas oranges apples melons carrots');

# A new one from pythonizer:

@export = qw/exp1 exp2 exp3/;
@export_ok = qw/ok1 ok2 ok3/;
%export_tags = (tag1=>[qw/t u/], tag2=>[qw/v w/]);
#print Dumper(\%export_tags) . "\n";
my %potential_imports = map { $_ => 1 } (@export, @export_ok);
for my $tag (keys %export_tags) {
    #print Dumper(\@{$export_tags{$tag}}) . "\n";
    %potential_imports = (%potential_imports, map { $_ => 1 } @{$export_tags{$tag}});
}
#print Dumper(\%potential_imports) . "\n";
assert(scalar(%potential_imports) == 10);
assert($potential_imports{exp1} == 1);
assert($potential_imports{ok3} == 1);
assert($potential_imports{t} == 1);
assert($potential_imports{u} == 1);
assert($potential_imports{v} == 1);
assert($potential_imports{w} == 1);

print "$0 - test passed!\n";
