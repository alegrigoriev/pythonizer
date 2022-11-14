# issue s150 - GetOptions or die generates bad code
use Carp::Assert;
use Getopt::Long;
use Getopt::Std;

$Getopt::Long::ignorecase = 0;

if(0) {
    $Getopt::Long::ignorecase = 1;
}
assert($Getopt::Long::ignorecase == 0);

# Process options
GetOptions("c:s" => \$flag_c,
           "D:s" => \$opt_D,
           "O:s" => \$out_D,
           "d:s" => \$date,
           'resend' => \$resend_f) or die ("Error in command line arguments\n");
assert($ARGV[1] eq '');

getopts('oif:') or die ("Error in short command line arguments\n");

assert($ARGV[2] eq ''); # Make sure autovivification still works

# This doesn't return anything: getopt('') or die ("Error in shorter command line arguments\n");

# Now some error tests, check STDERR, etc

%options = ();
@ARGV = ('--oops', '-nope');
close(STDERR);
open(STDERR, '>tmp.tmp');
my $passed = 0;
if(GetOptions(\%options, "myopt")) {
    assert(0);
} else {
    $passed = 1;
}
#open(SAVERR, '>&', STDERR);
close(STDERR);
open(ERRORS, '<tmp.tmp');
chomp(@errors = <ERRORS>);
close(ERRORS);
unlink "tmp.tmp";
#open(STDERR, '>&', SAVERR);
assert($passed);
assert(@errors == 2);
assert($errors[0] eq 'Unknown option: oops');
assert($errors[1] eq 'Unknown option: nope');

print "$0 - test passed!\n";

