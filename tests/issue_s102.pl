# issue s102 - NoneType has no attribute keys when fetching hash from empty data structure, also implicit return statement is not applying the package name on -M option
# issue found in qosbytes.pl
# pragma pythonizer -M
use Carp::Assert;

sub makecbbbytes
{
    local %bytes=();
    writebytefile();
    %bytes=();

}

sub writebytefile
{
	$key = 'k';
	$q = 'q';
	$classout = join('|', keys %{$bytes{$key}{$q}{classes}{out}});
	assert($classout eq '');
}

makecbbbytes();
print "$0 - test passed!\n";
