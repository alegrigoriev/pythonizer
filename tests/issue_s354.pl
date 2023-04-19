# issue s354: defined on an arrayref gives error on get operation
use Carp::Assert;
my @tests = (
    {
        'input' => 'now,UTC',
        'expected' => ['nowzone', undef, 'UTC', undef],
    },
    {
        'input' => 'now,std,UTC',
        'expected' => ['nowzone', 'std', 'UTC', undef],
    }
);

assert(!defined $tests[0]->{expected}->[1]);
assert(defined $tests[1]->{expected}->[1]);

print "$0 - test passed!\n";
