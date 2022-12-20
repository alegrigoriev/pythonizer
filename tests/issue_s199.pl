# issue s199 - constant hashrefs and arrays should be auto-vivified in arg lists
use Carp::Assert;
sub check_hash {
    my $hashref = shift;

    assert($hashref->{k1} eq 'v1');
    $hashref->{key}[3] = 4;
    assert($hashref->{key}[3] == 4);
}

sub check_arr {
    my $arrref = shift;

    assert($arrref->[0] eq '1');
    $arrref->[7] = 77;
    assert($arrref->[7] == 77);
    assert($arrref->[1] eq '2');
}

sub check_arr2 {
    # Gets sent an array ref and an array
    check_arr($_[0]);
    assert($_[1] == 1);
    assert($_[2] == 2);
}

sub check_arr_arr {
    # Gets sent 2 array refs
    check_arr($_[0]);
    assert($_[1]->[0] == 3);
    assert($_[1]->[1] == 4);
    $_[1]->[8] = 88;
    assert($_[1]->[8] == 88);
    assert(!defined $_[1]->[7]);
}

sub check_hash_hash {
    # Gets sent 2 hashrefs
    local ($hr1, $hr2) = @_;
    check_hash($hr1);
    assert($hr2->{k2} eq 'v2');
    $hr2->{key}{key2}{key3} = 'value';
    assert($hr2->{key}{key2}{key3} eq 'value');
}

check_hash({k1=>'v1'});
check_hash {k1=>'v1'};
check_hash_hash {k1=>'v1'}, {k2=>'v2'};
check_arr([1,2]);
check_arr2 [1,2], split /,/, "1,2";
check_arr_arr [1,2], [3,4];
@arr = (3,4);
check_arr_arr [1,2], \@arr;

print "$0 - test passed!\n";
