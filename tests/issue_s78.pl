# issue s78 - sort with complex {...} doesn't work properly
use Carp::Assert;

%params_as_hash = (c=>0, a=>1, b=>2, d=>3, content_a=>4, content_b=>5, e=>6);
@result = ();

foreach my $k (
    # sort keys alphabetically but favour certain keys before others
    # specifically for the case where there could be several options
    # for a param key, but one should be preferred (see GH #155)
    sort {
        if    ( $a =~ /content/i ) { return 1 }
        elsif ( $b =~ /content/i ) { return -1 }
        else  { $a cmp $b }
    }
    keys( %params_as_hash )
) {
	push @result, $k;
}

assert($result[0] eq 'a');
assert($result[1] eq 'b');
assert($result[2] eq 'c');
assert($result[3] eq 'd');
assert($result[4] eq 'e');
assert($result[5] =~ /content/);
assert($result[6] =~ /content/);
assert($result[5] ne $result[6]);

# Try a slightly simpler one

@result = sort {$global = $a; $a cmp $b} keys (%params_as_hash);

my $found = 0;
foreach my $k (keys %params_as_hash) {
	if($global eq $k) {
		$found = 1;
		last;
	}
}
assert($found);
assert("@result" eq 'a b c content_a content_b d e');

print "$0 - test passed!\n";
