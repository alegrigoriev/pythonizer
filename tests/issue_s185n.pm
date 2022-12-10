package issue_s185n;
# sub-module of issue_s185 to test out parameters from a non-OO module

use Exporter 'import';
use lib '.';
use issue_s185m;

our @EXPORT_OK = qw(set_to_one set_evens);

sub set_to_one {
    $p = new issue_s185m();
    $p->one_out($_[0]);
}

sub set_evens {
    for(my $i = 0; $i < @_; $i+=2) {
        ${$_[$i]} = $i;
    }
}
1;
    
