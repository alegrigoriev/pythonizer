# issue s319 - 

use strict;
use warnings;

use Carp::Assert;

BEGIN {
    # Load the mocked version of the DBI::var package
    require './MockDBIvar.pm';
}

# Mock the DBI::err variable
{
    package DBI;
    our $err;
}

# This is the statement we want to test, using the mocked DBI::var package
tie $DBI::err, 'DBI::var', '*err';

# Test the tied variable behavior
$DBI::err = 1;
assert($DBI::err == 1, 'Tied variable should have the new value');

$DBI::err = 2;
assert($DBI::err == 2, 'Tied variable should have another new value');

assert($DBI::var::fetch_called == 2);
assert($DBI::var::store_called == 2);

print "$0 - test passed!\n";
