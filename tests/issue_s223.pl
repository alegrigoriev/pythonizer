# issue s223 - converting a $class to a string and also ref $class gives incorrect result
use Carp::Assert;

package CGI;
use Carp::Assert;

$classref = \__PACKAGE__;
assert($$classref eq 'CGI');

$hashref->{+__PACKAGE__} = {key=>value}; # the + prevents __PACKAGE__ from being changed to a string
assert($hashref->{CGI}->{key} eq 'value');

sub new {
    $class = shift;

    #print "$class\n";
    assert($class eq 'CGI');
    $rf = ref $class;
    #print "$rf\n";
    assert(!$rf);

    bless {}, $rf || $class;
}

package main;

my $cgi = CGI->new;
assert(ref $cgi eq 'CGI');

END {
    unlink "tmp.tmp";
}
print "$0 - test passed!\n";
