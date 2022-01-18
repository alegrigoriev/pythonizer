# test the "::" operator (gets the symbol table)

use Carp::Assert;
use lib '.';
use Exporting ();
my %pack = %{Exporting::};

assert(exists $pack{EXPORT_OK});
assert(exists $pack{munge});
assert(exists $pack{frobnicate});
*munge = $pack{munge};
assert(munge('a') eq 'am');
@export_ok = @{$pack{EXPORT_OK}};
assert(join(' ', @export_ok) eq 'munge frobnicate');
print "$0 - test passed!\n";
