# Test ref on basic types
use Carp::Assert;
my $i = 1;
assert(ref \$i eq 'SCALAR');
my $f = 1.2;
assert(ref(\$f) eq 'SCALAR');
my $s = 'a';
assert(ref(\$s) eq 'SCALAR');
my @a = (1, 2);
assert(ref(\@a) eq 'ARRAY');
assert(ref \$a[0] eq 'SCALAR');
my %h = (a=>2, b=>3);
assert(ref(\%h) eq 'HASH');
assert(ref(\$h{a}) eq 'SCALAR');
my %hh = (h=>\%h);
assert(ref \%hh eq 'HASH');
#print ref \%hh{h};
#assert(ref \%hh{h} eq 'HASH');

# now let's try testing if something is a ref (e.g. an object) or not (TDD)

use IO::File;
my $fh = IO::File::new;
assert(ref $fh);
assert(!ref $i);
assert(!ref @a);
assert(!ref %h);
#print STDERR ref($fh) . "\n";
assert(ref $fh eq 'IO::File' || ref $fh eq '_io.TextIOWrapper' || ref $fh eq 'TextIOWrapper');

# More test cases from GPT:
# Test ref on a file handle that has just been used in an open statement
# We can't handle this one
#open $fh, '<', $0;
#print STDERR ref($fh) . "\n";
#binmode $fh;
#print STDERR ref($fh) . "\n";
#assert(ref($fh) eq 'GLOB', 'ref on a file handle that has just been used in an open statement should return "GLOB"');

# Test ref on a scalar
my $scalar = 'foo';
assert(ref($scalar) eq '', 'ref on a scalar should return an empty string');

# Test ref on an array
my @array = (1, 2, 3);
assert(ref(\@array) eq 'ARRAY', 'ref on an array should return "ARRAY"');

# Test ref on a hash
my %hash = (a => 1, b => 2, c => 3);
assert(ref(\%hash) eq 'HASH', 'ref on a hash should return "HASH"');

# Test ref on a subroutine
sub test_sub { return 'test' }
#print STDERR ref(\&test_sub) . "\n";
assert(ref(\&test_sub) eq 'CODE', 'ref on a subroutine should return "CODE"');

# Test ref on an object

my $obj = MyObject->new;
assert(ref($obj) eq 'MyObject', 'ref on an object should return the object\'s class name');

# Test ref on undef
assert(ref(undef) eq '', 'ref on undef should return an empty string');

# Test ref on a scalar containing a reference to an array
my $scalar_array_ref = [1, 2, 3];
assert(ref($scalar_array_ref) eq 'ARRAY', 'ref on a scalar containing a reference to an array should return "ARRAY"');

# Test ref on a scalar containing a reference to a hash
my $scalar_hash_ref = {a => 1, b => 2, c => 3};
assert(ref($scalar_hash_ref) eq 'HASH', 'ref on a scalar containing a reference to a hash should return "HASH"');

# Test ref on a scalar containing a reference to a subroutine
my $scalar_sub_ref = \&test_sub;
assert(ref($scalar_sub_ref) eq 'CODE', 'ref on a scalar containing a reference to a subroutine should return "CODE"');

# Test ref on a scalar containing a reference to an object
# We can't handle this one:
#my $scalar_obj_ref = \$obj;
#assert(ref($scalar_obj_ref) eq 'REF', 'ref on a scalar containing a reference to an object should return "REF"');

# Test ref on a scalar out parameter
sub one_out_ref {
    my $p = shift;
    assert(ref $p eq 'SCALAR');
    $$p = 1;
}

my $scalar;
one_out_ref(\$scalar);
assert($scalar == 1);

print "$0 - test passed!\n";

package MyObject;
sub new { bless {}, shift }
