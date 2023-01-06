# part of issue_s203a
package MYPACKAGE;
use Carp::Assert;

sub new {
    bless {}, shift;
}

sub subname {
    my ($self, $input) = @_;

    assert($input eq 'valid_input', 'Invalid input detected') if DEBUG;
    return 'expected_output';
}
1;
