# issue s51 - Add more functions to File::Spec implementation

use File::Spec;
use Carp::Assert;

#my $path = "c:\\program files\\fred\\file.ext";
my $path = "/c/pythonizer/pythonizer/tests";
#print "$path\n";
my ($dv, $dd) = File::Spec->splitpath($path, 1);
#print "$dv, $dd\n";
assert(!$dv);
assert($dd eq $path);
my @d = File::Spec->splitdir($dd);
my $sd = scalar(@d);
#print "$sd, @d\n";
assert($sd == 5);
assert(join(' ', @d) eq ' c pythonizer pythonizer tests');

my $curdir = File::Spec->curdir();
assert($curdir eq '.');
my $updir = File::Spec->updir();
assert($updir eq '..');

print "$0 - test passed!\n";
