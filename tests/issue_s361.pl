# issue s361 - Symbolic reference not generating proper code
use Carp::Assert;
use lib '.';
use ExportVars;
no warnings 'experimental';
# pragma pythonizer -M

my $backend;
$backend = 'ExportVars';
my $backend_exp = $backend . "::EXPORT";
{
    no strict 'refs';
    @EXPORT = @{ $backend_exp };
}

assert(@EXPORT ~~ @ExportVars::EXPORT);

print "$0 - test passed!\n";
