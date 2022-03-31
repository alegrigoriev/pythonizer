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
assert(ref $fh eq 'IO::File' || ref $fh eq '_io.TextIOWrapper' || ref $fh eq 'TextIOWrapper');

print "$0 - test passed!\n";
