# Test the various ways of running a script

use Carp::Assert;

$cmd = "echo 123";

$res = `$cmd`;
assert($res =~ /^123/);

$res = '';
$res = qx/$cmd/;
assert($res =~ /^123/);

END {
    eval {
        rmdir "tmp.dir";
    };
}

system "mkdir tmp.dir";

assert(-d "tmp.dir");

`rmdir tmp.dir`;
assert(!-d "tmp.dir");

qx/mkdir tmp.dir/;
assert(-d "tmp.dir");
qx/rmdir tmp.dir/;
assert(!-d "tmp.dir");

print "$0 - test passed!\n";
