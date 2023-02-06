# issue s269 - naming a package 'bytes' should generate an escaped name
use lib '.';
use bytes;
use Carp::Assert;

assert($bytes::ran_import);
print "$0 - test passed!\n";
