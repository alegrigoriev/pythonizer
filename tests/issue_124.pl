# Regex with DEFAULT_VAR and capturing groups needs to always set the DEFAULT_MATCH
use Carp::Assert;

$_ = '2020-01-23';
{
    last if(! /(\d+)-(\d+)-(\d+)/);
    $cnt++;
    assert($1 == 2020 && $2 == 1 && $3 == 23);
}

assert($cnt == 1);

print "$0 - test passed!\n";

