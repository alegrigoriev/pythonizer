# issue s249 - Multiple globs with 'log' generates bad code
use Carp::Assert;
use Data::Dumper;

my $logdir = './issue_s249';

# Create test log directory
`mkdir -p $logdir`;

# Create test log files
`touch $logdir/info.0.gz`;
`touch $logdir/info.1.gz`;
`touch $logdir/info.2.gz`;
`touch $logdir/info.log.0.gz`;
`touch $logdir/info.log.1.gz`;
`touch $logdir/ssl-info.log.0.gz`;

my @expected_files = (
    "$logdir/info.0.gz",
    "$logdir/info.1.gz",
    "$logdir/info.2.gz",
    "$logdir/info.log.0.gz",
    "$logdir/info.log.1.gz",
    "$logdir/ssl-info.log.0.gz"
);

my @found_files;

for my $logfile (<$logdir/info.[0-9]*.gz>,<$logdir/info.log.*.gz>,<$logdir/ssl-info.log.*.gz>) {
    push @found_files, $logfile;
}

# Compare found files to expected files using the assert_deep_equals subroutine
sub assert_deep_equals {
    my ($left, $right) = @_;
    if (ref $left eq 'ARRAY' && ref $right eq 'ARRAY') {
        if (@$left != @$right) {
            die "Expected array of length @{[scalar @$right]}, but got array of length @{[scalar @$left]}: " . Dumper($left);
        }
        for (my $i = 0; $i < @$left; $i++) {
            assert_deep_equals($left->[$i], $right->[$i]);
        }
    } else {
        # On windoze, $left may have a backslash in it instead of a slash
        $left =~ s+\\+/+g;
        return if $left eq $right;
        die "Expected: " . Dumper($right) . " but got: " . Dumper($left);
    }
}
assert_deep_equals(\@found_files, \@expected_files);

# Clean up test files and directory
END {
    `rm -r $logdir`;
}

print "$0 - test passed!\n";
