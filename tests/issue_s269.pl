# issue s269 - naming a package 'bytes' should generate an escaped name
use lib '.';
use bytes;
require 'yield.pm'; # require 'yield.pm'
use yield;          # use yield
use Carp::Assert;

assert($bytes::ran_import);
assert($yield::ran_import);
print "$0 - test passed!\n";
