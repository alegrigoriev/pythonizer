package issue_s236m;
use Carp::Assert;
# This is the default class for the issue_s236m object to use when all else fails.
$DefaultClass = 'issue_s236m' unless defined $issue_s236m::DefaultClass;

sub new { 
    my $cls = shift;
    $OurClass = $cls;
    bless {}, $cls }

sub newer { bless {}, shift }

sub _copy {
    my $self = shift;
    my $clone = {%$self};
    bless $clone,__PACKAGE__;
    return $clone;
}

use overload '=' => \&_copy, fallback=>1;        # Not a MethodType

sub binmode {
    $class = $_[0];
    assert($class eq 'issue_s236m' || UNIVERSAL::isa($class, 'issue_s236m'));
    $::got_here = $_[1];
}
1;
