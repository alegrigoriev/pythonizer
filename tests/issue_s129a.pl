# issue s129a - implement switch - part 2 - no fallthrough
# From nested.t:

use Carp::Assert;
use Switch;
use v5.34;
no warnings qw/experimental/;
#print "1..4\n";

my $count = 1;
my @ok;
#for my $count (1..3, 'four')
for my $count (1, 2, 3, 'four')
{
	switch ([$count])
	{

=pod
=head1 Test
We also test if Switch is POD-friendly here
=cut

		case qr/\d/ {
				switch ($count) {
					case 1     { $ok[1] = 1; }
					case [2,3] { $ok[$count] = 1; }
				}
			    }
		case 'four' { $ok[4] = 1; }
        case qr/.*/ { $ok[4] = 0; }
	}
}
for(my $i = 1; $i <= 4; $i++) {
    print "ok[$i] = $ok[$i]\n" unless $ok[$i] == 1;
    assert($ok[$i] == 1);
}

# Examples from the documentation
my %found = ();
$_ = '';
for(my $val = 1; $val <= 10; $val++) {
    switch ($val) {
        assert($_ eq '');       # Switch does not set $_
        case 1      { $found{0}++; next }    # and try next case...
        case "1"    { $found{1}++; next }    # and try next case...
        case [0..9] { $found{2}++; }       # and we're done
        case /\d/   { $found{3}++; next }  # and try next case...
        case /.*/   { $found{4}++; next }  # and try next case...
    }
}
for(my $i = 0; $i <= 4; $i++) {
    if($i == 2) {
        assert($found{$i} == 9) 
    } else {
        assert($found{$i} == 1) 
    }
}

print "$0 - test passed\n";

__END__
=head1 Another test
Still friendly???
=cut


