# issue s209: Multiple packages in the same file with names that have the same prefix causes errors on global variable initialization
package issue_s209;
use Carp::Assert;
#use Data::Dumper;

assert(!defined $issue_s209::notThere);
sub check_it {
    assert($issue_s209::subPack::TIMEOUT == 240);
    assert(!defined $main::mainVar);
}
assert(!defined $issue_s209::subPack::NotThere);

# Make sure we don't _init_global of this:
#assert($Data::Dumper::Purity == 0);
#if(0) {
#    Dumper(\%main::);   # Data namespace is defined by Dumper
#}

package issue_s209::subPack;
use Carp::Assert;
$subPack::TIMEOUT ||= 240;
assert($main::subPack::TIMEOUT == 240);
assert($::subPack::TIMEOUT == 240);
$simPack::TIMEOUT = 240;
assert($main::simPack::TIMEOUT == 240);
$TIMEOUT = $subPack::TIMEOUT;
assert($TIMEOUT == 240);
assert($issue_s209::subPack::TIMEOUT == 240);
assert($main::issue_s209::subPack::TIMEOUT == 240);

sub local_check_it {
    assert($TIMEOUT == 240);
}
local_check_it();

&issue_s209::check_it();
print "$0 - test passed!\n";
