# issue s213 - Constant hashref dereference generates bad code
# From CGI.pm
use Carp::Assert;

sub getSL {
    my $OS = shift;

    $SL = {
 UNIX    => '/',  OS2 => '\\', EPOC      => '/', CYGWIN => '/', NETWARE => '/',
 WINDOWS => '\\', DOS => '\\', MACINTOSH => ':', VMS    => '/'
}->{$OS};
    return $SL;
}

assert(getSL('UNIX') eq '/');
assert(getSL('DOS') eq '\\');
assert(getSL('MACINTOSH') eq ':');

sub getSL2 {
    my $OS = shift;

    return {
 UNIX    => '/',  OS2 => '\\', EPOC      => '/', CYGWIN => '/', NETWARE => '/',
 WINDOWS => '\\', DOS => '\\', MACINTOSH => ':', VMS    => '/'
}->{$OS};
}

assert(getSL2('UNIX') eq '/');
assert(getSL2('DOS') eq '\\');
assert(getSL2('MACINTOSH') eq ':');

sub getDB {
    my $ndx = shift;

    [0,2,4,6,8,10]->[$ndx];
}

sub getTR {
    my $ndx = shift;

    (0,3,6,9,12,15)[$ndx];
}

assert(getDB(2) == 4);
assert(getTR(3) == 9);

print "$0 - test passed!\n";
