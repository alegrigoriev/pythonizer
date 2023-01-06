# issue s226: wantarray: Returns the undefined value if the context is looking for no value (void context) - implement this!
# pragma pythonizer -M
use Carp::Assert;
use lib '.';
use issue_s226m qw/uw/;

sub use_wantarray {
    $global = wantarray;

    if(defined wantarray) {
        return wantarray ? ('1') : 1;
    }
    return;
}

use_wantarray();        # Void context
assert(!defined $global);
$global = 1;
use_wantarray(split / /, $line);
assert(!defined $global);
$global = 1;
use_wantarray(1,2);
assert(!defined $global);
my @arr = use_wantarray();
assert($global);
assert($arr[0] == 1);
my $s = use_wantarray();
assert(defined $global && !$global);
assert($s == 1);

uw();        # Void context
assert(!defined $global);
$global = 1;
&issue_s226m::uw(1);        # Void context
assert(!defined $global);
my @arr = uw();
assert($global);
assert($arr[0] == 1);
my $s = uw();
assert(defined $global && !$global);
assert($s == 1);

print "$0 - test passed!\n";
