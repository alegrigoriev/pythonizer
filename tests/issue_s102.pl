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

sub make_attuid
{
	$rds_hrid = shift;
       if ($rds_hrid =~/ABNORD/i) { $attuid = 'xx9999' }      
        elsif (length($rds_hrid) == 0) { $attuid = 'xx9999' } else { $attuid = lc($rds_hrid) };
	# cause it to insert 3 'return' stmts: return $attuid;
}

assert(make_attuid('abnord') eq 'xx9999');
assert(make_attuid('') eq 'xx9999');
assert(make_attuid('AB1111') eq 'ab1111');

sub writebytefile
{
	$key = 'k';
	$q = 'q';
	$classout = join('|', keys %{$bytes{$key}{$q}{classes}{out}});
	assert($classout eq '');
}

%bytes = (key=>'value');
assert(scalar(%bytes) == 1);
my %b = makecbbbytes();
assert(scalar(%b) == 0);
assert(scalar(%bytes) == 1);
print "$0 - test passed!\n";
