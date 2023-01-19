# issue s248 - Sub with scalar out parameter can crash Pythonizer

use Carp::Assert;

# create a mocked version of db_connect->new
my $expected_dbc = 'test_dbc';
*db_connect::new = sub { return $expected_dbc; };

# create test inputs
my $test_block = 'test_block';
my $test_prefix = 'test_prefix';
my $dbc;

sub get_next_from_cache {
    my $dbc = shift;
    my $block = shift;
    my $prefix = shift;

    $$dbc = db_connect->new('local');  # This line crashes pythonizer
}

# call the get_next_from_cache subroutine
get_next_from_cache(\$dbc, $test_block, $test_prefix);

# assert that the subroutine sets $dbc to the expected value
assert($dbc eq $expected_dbc);

print "$0 - test passed!\n";

