# issue s217 - Array assignment in foreach loop generates bad code
# Code from parent.pm
use Carp::Assert;

sub test_issue {
    my $val;
    for(my @filename = @_) {
        $val .= $_;
    }
    $val;
}

assert(test_issue('a', 'b') == 'ab');

sub test_issue2 {
    my $val;
    for my $v (my @filename = @_) {
        $val .= $v;
    }
    $val;
}

assert(test_issue2('a', 'b') == 'ab');
print "$0 - test passed!\n";
