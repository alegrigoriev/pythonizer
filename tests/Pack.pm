package Pack;

use lib '.';
use Pscan;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw(%Packages @Packages get_cur_package);

%Packages = ();
@Packages = ();

sub get_cur_package
{
    return cur_package();
}

1;
