# issue s260 - caller() doesn't return the proper result if methods have perllib.tie_call applied
package A;
use Carp::Assert;
sub TIEARRAY { }
sub a {
    @caller = caller;
    #print STDERR "@caller\n";
    assert($caller[0] eq 'B');
    assert($caller[1] eq $0);
    assert($caller[2] =~ /\d+/);
    my $i = 0;
    my $results = [
        ['B', $0, 0, qr/A.*a/, 1],
        ['C', $0, 0, qr/B.*b/, 1],
        ['D', $0, 0, qr/C.*c/, 1],
        ['E', $0, 0, qr/D.*d/, 1],
        ['main', $0, 0, qr/E.*e/, 1],
        [undef, ],
    ];
    while(1) {
        @caller = caller($i);
        #print STDERR "$i, @caller\n";
        assert($caller[0] eq $results->[$i]->[0]);
        last if !defined $caller[0];
        assert($caller[1] eq $results->[$i]->[1]);
        assert($caller[2] =~ /\d+/);
        assert($caller[3] =~ $results->[$i]->[3]);
        assert($caller[4] == $results->[$i]->[4]);
        $i++;
    }
}

package B;
sub TIEHASH { }
sub b {
    A->a();
}

package C;
sub TIEHASH { }
sub c {
    B->b();
}

package D;
sub TIEHASH { }
sub d {
    C->c();
}

package E;
sub e {
    D->d();
}

package main;
E->e();

# Try wantarray
use Carp::Assert;
sub wa {
    @result = (1, 2);
    my @caller = caller(0);
    #print "wa caller @caller\n";
    assert($caller[0] eq 'main');
    if(wantarray) {
        assert($caller[5], "Incorrect wantarray when true");
    } else {
        assert(!$caller[5], "Incorrect wantarray when false");
    }
    return wantarray ? @result : $result[0];
}

my @arr = wa();
my $sca = wa();

# Try a _fNN
package FNN;
use Carp::Assert;
sub use_fnn {
    my ($v1, $v2) = (1, 2);
    for ($v1, $v2) {
        my @caller = caller(0);
        #print "@caller\n";
        assert($caller[0] eq 'FNN');
        assert($caller[3] =~ /use_fnn/);
        $_ = caller;
    }
    assert($v1 eq 'FNN');
    assert($v2 eq 'FNN');
}
use_fnn();

print "$0 - test passed!\n";
