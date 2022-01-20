# Test that file handles are global across files

use Carp::Assert;
use lib '.';

local *LCL;

open(FH, '>tmp.tmp');
require "test_global_part_2.pm";

my $fh = FH;
assert($fh == FH);

close(FH);

open(FH, '<tmp.tmp') or die "Cannot open tmp.tmp";
chomp($line = <FH>);
assert($line eq 'test global data');

if(open(FH, '<tmp.tmp')) {
   chomp($line = <FH>);
   assert($line eq 'test global data');
} else {
    die "Cannot open tmp.tmp";
}

open(LCL, '<tmp.tmp') or die "Cannot open tmp.tmp";
chomp($line = <LCL>);
assert($line eq 'test global data');

sub mysub
{
    local *FH;

    if(!open(FH, '<tmp.tmp')) {
        assert(0);
    }
    chomp($line = <FH>);
    assert($line eq 'test global data');
    close(FH);
}

open(FH, '<tmp.tmp') or die "Cannot open tmp.tmp";
# mysub call should stack and restore our global FH
mysub();
chomp($line = <FH>);
assert($line eq 'test global data');

print "$0 - test passed!\n";

END {
    eval {close(FH);};
    eval {close(LCL);};
    eval {unlink "tmp.tmp";};
}
