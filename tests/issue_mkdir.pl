# issue mkdir - mkdir didn't return 1 on success

use Carp::Assert;
my $passed = 0;

END {
    rmdir "test_dir";
    rmdir "default_dir";
    rmdir "mode_dir";
    assert(!-d "test_dir");
    assert(!-d "default_dir");
    assert(!-d "mode_dir");
    print "$0 - test passed!\n" if($passed);
}

$_ = "default_dir";
assert(mkdir);
assert(-d $_);

if(mkdir "test_dir") {
    ;
} else {
    assert(0);
}

assert(!mkdir "test_dir");
assert($! =~ /exists/);

$i = mkdir "mode_dir", 0700;
# The mode doesn't do anything on windows so skip testing it
#printf "%o\n", (stat "test_dir")[2];
#printf "%o\n", (stat "mode_dir")[2];

assert($i);
$passed = 1;

assert(-d "test_dir");

