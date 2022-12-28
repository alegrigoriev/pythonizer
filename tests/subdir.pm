# part of issue s211
package subdir;
use lib '.';

use subdir::Util qw/escape/;
use subdir::subsubdir::utils qw/myutil/;

sub new {
    bless {}, shift;
}

sub identity {
    my $self = shift;
    myutil(escape($_[0]))-1;
}

1;
