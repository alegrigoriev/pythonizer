# issue s218a - Return with ||= generates bad code (and object comparison is broken) - this sub-test checks object comparison when the object has a numify overloaded method
package ovr;

sub to_num {
    my $self = shift;
    return int($self->{value});
}

sub stringify {
    my $self = shift;
    return "" . $self->{value};
}

use overload "0+" => \&to_num, '""'=> \&stringify, fallback=>1;
#use overload "0+" => \&to_num, '""'=> \&stringify;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{value} = $_[0];
    $self;
}

package main;
use Carp::Assert;

my $x = ovr->new(1);
my $y = ovr->new(2);
my $z = ovr->new(2);

assert("$x $y $z" eq '1 2 2');

my $xn = 0+$x;
my $yn = 0+$y;
my $zn = 0+$z;
#print "$xn, $yn, $zn\n";
assert($xn != $yn);
assert($yn == $zn);
assert($y == $z);

print "$0 - test passed!\n";
