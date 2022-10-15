# issue s116 - Regex substitution raises exception on undef arg
# from diffdata.pl
use Carp::Assert;

sub strip
{
   my $string = shift; 

   $string =~ s/^\s*//;
   $string =~ s/\s*$//;

   return $string;
}

assert(strip('a') eq 'a');
assert(strip(' a ') eq 'a');
my $u = undef;
assert(strip($u) eq '');

# let's try some other cases
assert($u !~ /a/);

print "$0 - test passed!\n";

