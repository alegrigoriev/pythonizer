# Test the sort function using the examples on the definition page

use Carp::Assert;
use Data::Dumper;
use feature 'fc';

@files = ('d', 'e', 'c', 'a', 'b');
# sort lexically
my @articles = sort @files;
assert(join('', @articles) eq 'abcde');

# same thing, but with explicit sort routine
my @articles1 = sort {$a cmp $b} @files;
assert(join('', @articles1) eq 'abcde');

# now case-insensitively
my @articles2 = sort {fc($a) cmp fc($b)} @files;
assert(join('', @articles2) eq 'abcde');

@files = ('d', 'e', 'c', 'a', 'b');
# same thing in reversed order
my @articlesr = sort {$b cmp $a} @files;
assert(join('', @articlesr) eq 'edcba');

@files = (4, 5, 3, 1, 2);
# sort numerically ascending
my @articlesn = sort {$a <=> $b} @files;
assert(join('', map {''.$_} @articlesn) eq '12345');

# sort numerically descending
my @articlesnd = sort {$b <=> $a} @files;
assert(join('', map {''.$_} @articlesnd) eq '54321');

%age = (a=>10, b=>5, c=>20, d=>1, e=>6);
# this sorts the %age hash by value instead of key
# using an in-line function
my @eldest = sort { $age{$b} <=> $age{$a} } keys %age;
assert(join('', @eldest) eq 'caebd');

my @class = ('a', 'c', 'b');
# sort using explicit subroutine name
sub byage {
    $age{$a} <=> $age{$b};  # presuming numeric
}
my @sortedclass = sort byage @class;
assert(join('', @sortedclass) eq 'bac');

sub backwards { $b cmp $a }
my @harry  = qw(dog cat x Cain Abel);
my @george = qw(gone chased yz Punished Axed);

assert(join('', sort @harry) eq 'AbelCaincatdogx');

assert(join('', sort backwards @harry) eq 'xdogcatCainAbel');

#We'll fix this some other day
#@sorted = sort @george, 'to', @harry;
#assert(join('', @sorted) eq 'AbelAxedCainPunishedcatchaseddoggonetoxyz');

print "$0 - test passed!\n";
