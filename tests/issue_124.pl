# Regex with DEFAULT_VAR and capturing groups needs to always set the DEFAULT_MATCH
use Carp::Assert;

$_ = '2020-01-23';
{
    last if(! /(\d+)-(\d+)-(\d+)/);
    $cnt++;
    assert($1 == 2020 && $2 == 1 && $3 == 23);
}

assert($cnt == 1);

# Another similar issue found in netflow.pl:
#

sub process_file {

    my $in = shift;
    next if not $in =~ /(flows)\.(\d+)\.gz/;
    $cnt++;
}

@files = ('nomatch', 'flows.12.gz', 'netflows.13.gz');
for my $file (@files){
    process_file($file);
}
assert($cnt == 3);


print "$0 - test passed!\n";

