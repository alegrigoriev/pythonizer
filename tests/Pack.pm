package Pack;

use lib '.';
use Pscan;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw(%Packages @Packages get_cur_package);

%Packages = ();
@Packages = ();

if(0) { # Define a file handle to see how it is in the symbol table
    open(FH, '<file');
}

sub get_cur_package
{
    return cur_package();
}

1;
