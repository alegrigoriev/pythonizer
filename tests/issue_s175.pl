# issue s175: tie should be allowed to take a bareword package name

use warnings ;
#use strict ;
use lib '.';
use TiedArray ;
use Carp::Assert;

my $filename = "tmp.tmp" ;
unlink $filename ;

my @h ;
my $href = tie @h, TiedArray, $filename
    or die "Cannot create file $filename: $!\n" ;

assert(ref $href eq 'TiedArray');
assert(ref \@h eq 'ARRAY');
assert(tied @h == $href);
assert($href->length == 0);
# Add a few key/value pairs to the file
$h[0] = "orange" ;
$h[1] = "blue" ;
$h[2] = "yellow" ;
assert($href->length == 3);

push @h, "green", "black" ;
assert($href->length == 5);

my $elements = scalar @h ;
#print "The array contains $elements entries\n" ;
assert($elements == 5);

my $last = pop @h ;
# print "popped $last\n" ;
assert($last eq 'black');

unshift @h, "white" ;
my $first = shift @h ;
#print "shifted $first\n" ;
assert($first eq 'white');

# Check for existence of a key
#print "Element 1 Exists with value $h[1]\n" if $h[1] ;
if($h[1]) {
    ;
} else {
    assert(0);
}

# use a negative index
#print "The last element is $h[-1]\n" ;
#print "The 2nd last element is $h[-2]\n" ;
assert($h[-1] eq 'green');
assert($h[-2] eq 'yellow');

my @removed = splice @h, 1, 2, 'purple', 'violet', 'pink';
assert(@removed == 2);
assert($removed[0] eq 'blue');
assert($removed[1] eq 'yellow');
assert($h[-2] eq 'pink');
assert(join(' ', @h) eq 'orange purple violet pink green');

undef $href;
untie @h ;

assert(@h == 0);
open(FILE, '<', $filename) or die "cannot read $filename";
chomp(my @rows = <FILE>);
assert(@rows == 5);
assert(join(' ', @rows) eq 'orange purple violet pink green');

END {
    eval {
        untie @h;
    };
    unlink $filename ;
}

print "$0 - test passed!\n";
