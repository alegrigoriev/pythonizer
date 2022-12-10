# issue s198 - array or hash in local declaration list in a sub should consume the rest of the RHS
use Carp::Assert;

my @arr = ('k1', 'v1', 'k2', 'v2');

my (%h) = @arr;
assert($h{k1} eq 'v1' && $h{k2} eq 'v2');
my ($i, $j, %ha) = @arr;
assert($i eq 'k1');
assert($j eq 'v1');
assert($ha{k2} eq 'v2');
my ($l, $m, @a) = @arr;
assert($l eq 'k1');
assert($m eq 'v1');
assert(@a == 2);
assert($a[0] eq 'k2');
assert($a[1] eq 'v2');
$a[2] = 'k3';       # Make sure it's autovivified
assert(@a == 3);
assert($a[2] eq 'k3');

local(%hl) = @arr;
assert($hl{k1} eq 'v1' && $hl{k2} eq 'v2');

sub trySub {
   local (%in) = @_;
   local %xx = @_;
   local (@args) = @_;
   local @args_copy = @args;
   local (@xx_copy) = %xx;
   assert($in{k1} eq 'v1' && $in{k2} eq 'v2');
   assert($xx{k1} eq 'v1' && $xx{k2} eq 'v2');
   assert($args[0] eq $_[0] && $args[1] eq $_[1] && $args[2] eq $_[2] &&
          $args[3] eq $_[3]);
   $args[0] = 'newarg';
   assert($args[0] eq 'newarg' && $_[0] eq 'k1');
   assert($args_copy[0] eq 'k1');
   assert(@xx_copy == 4);
   assert(grep {/k1/} @xx_copy);
   assert(grep {/k2/} @xx_copy);
   assert(grep {/v1/} @xx_copy);
   assert(grep {/v2/} @xx_copy);
}
trySub(@arr);

# some crazy cases from netdb code:

my ($warning_msg, @flds, @selected_lines, @sorted_lines, @dirs, @cirtxt) = "";
assert($warning_msg eq '');
assert(@flds == 0);
assert(@selected_lines == 0);
assert(@dirs == 0);
assert(@cirtxt == 0);

my ($thing1, @things2, $thing3) = ('a', 'b');
#print "$thing1, @things2, $thing3\n";
assert($thing1 eq 'a');
assert("@things2" eq 'b');
assert(!defined $thing3);

my ($sc1, %ha1, $sc2) = ('s', 'k', 'v');
assert($sc1 eq 's');
assert($ha1{k} eq 'v');
assert(!defined $sc2);

print "$0 - test passed!\n";
