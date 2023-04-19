# issue_s357 - IO::File open fails as it calls open_ instead
use Carp::Assert;
use IO::File;

sub _get_curr_zone {
	my @methods = ('a');
	my $cnt = 0;
	while(@methods) {
		my $method = shift(@methods);
		if(1) {		# make it conditional
			my $in = new IO::File;
			$in->open($0) || next;

			while (! $in->eof) {
				my $line = <$in>;

				assert(substr($line,0,1) eq '#');
				last;
			}

			$in->close();
		}
		$cnt++;
	}
	assert($cnt == 1);
}

_get_curr_zone();

print "$0 - test passed!\n";
