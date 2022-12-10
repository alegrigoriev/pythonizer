# test which function read we call
#
# From the documentation:
#
# OVERRIDING CORE FUNCTIONS
# To override a Perl built-in routine with your own version, you need 
# to import it at compile-time. This can be conveniently achieved with 
# the subs pragma. This will affect only the package in which you've 
# imported the said subroutine:

use subs 'chdir';
sub chdir { 14 }
my $somewhere;
assert(chdir $somewhere == 14);

use Carp::Assert;

sub read {
    assert(0);      # wrong read - no use subs on it
}

my $fh;

read($fh, $buf, 10);

print "$0 - test passed!\n";
