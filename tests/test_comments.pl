# test comments - check that comments appear in the proper places
# Issues found in cmt/pr_associate.pl
use Carp::Assert;

sub check1 
### Comment 0
{
   if (! $lnode_id ) {  ### Comment 1
       $line--;  ### Comment 2
   }
	### Comment 3
	sleep 5;  ### Comment 4

    @dsp=(0);   ### Comment 5
    $line;    ### Comment 6
}               ### Comment 7

$py = ($0 =~ /\.py$/);
if($py) {
    my @patterns = (qr/^### Comment 0$/,
                    qr/:\s+### Comment 1$/,
                    qr/-= 1\s+### Comment 2$/,
                    qr/^\s+### Comment 3$/,
                    qr/\(5\)\s+### Comment 4$/,
                    qr/\)\s+### Comment 5$/,
                    qr/^\s+return line\s+### Comment 6$/,
                    qr/^### Comment 7$/,
                   );

    open(PY, '<', $0) or die("Cannot open $0");
    my $ndx = 0;
    while(<PY>) {
        if($ndx < scalar(@patterns)) {
            my $pattern = $patterns[$ndx];
            $ndx++ if /$pattern/;
        }
    }
    if($ndx < scalar(@patterns)) {
        assert(0, "Never found $patterns[$ndx]");
    }
    close(PY);
}

print "$0 - test passed!\n";
