# part of issue_s319.pl
package DBI::var;

use strict;
use warnings;

our $mock_err_value;
our $fetch_called = 0;
our $store_called = 0;

sub TIESCALAR {
    my ($class, $key) = @_;
    return bless {key=>$key}, $class;
}

sub FETCH {
    my ($self) = @_;
    $fetch_called++;
    return $mock_err_value;
}

sub STORE {
    my ($self, $value) = @_;
    $store_called++;
    $mock_err_value = $value;
}

1;

