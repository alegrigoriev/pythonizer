# issues 17 & 18: bad code for while loop on FH using implicit $_
use Carp::Assert;
use Fcntl qw/SEEK_SET/;
$| = 1;

open(FILE, "+>tmp.tmp");
print FILE "# line ignored\n";
print FILE "real line\n";
seek FILE, 0, SEEK_SET;

my $ctr = 0;
	   while (<FILE>)
           {
                   $ctr++;
		   next if /^#/;
                   assert(/^real line/);

	   }
close(FILE);
assert($ctr == 2);
END {
    eval {close(FILE)};
    eval {unlink "tmp.tmp"};
}
print "$0 - test passed\n";
