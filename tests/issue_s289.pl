# issue s289 - Setting CORE::GLOBAL::func doesn't do anything
BEGIN {
    *CORE::GLOBAL::die = sub { print STDERR "$0 - test passed!\n"; };
}
die();
