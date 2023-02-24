# test the "::" operator (gets the symbol table)
# pragma pythonizer -M

use Carp::Assert;
use lib '.';
use Exporting ();
my %pack = %{Exporting::};

$py = ($0 =~ /\.py$/);
my $export_ok = 'EXPORT_OK';
$export_ok = 'EXPORT_OK_a' if $py;

assert(exists $pack{$export_ok});
assert(exists $pack{munge});
assert(exists $pack{frobnicate});
*munge = $pack{munge};
assert(munge('a') eq 'am');
@export_ok = @{$pack{$export_ok}};
assert(join(' ', @export_ok) eq 'munge frobnicate');
print "$0 - test passed!\n";
