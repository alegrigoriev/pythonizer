# submodule for issue_s187
package issue_s187m;
use Carp::Assert;

sub import {
    assert(0);      # should NOT get here!
}

sub print_it {
    print $_[0];
}
1;
