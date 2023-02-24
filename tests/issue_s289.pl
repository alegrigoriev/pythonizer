# issue s289 - Setting CORE::GLOBAL::func doesn't do anything
use Carp::Assert;
BEGIN {
    $warns = 0;
    *CORE::GLOBAL::warn = sub { $warns++ };
    *CORE::GLOBAL::die = sub { print STDERR "$0 - test passed!\n"; };
}
warn;
assert($warns == 1);
die();
