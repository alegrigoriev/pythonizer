# issue s90: Reference to unset %ENV variable gives KeyError in python version
# test LD_LIBRARY_PATH, esp if it's not set

use Carp::Assert;

$ENV{LD_LIBRARY_PATH}=$ENV{LD_LIBRARY_PATH} . ":/usr/local/lib";

assert($ENV{LD_LIBRARY_PATH} =~ m':/usr/local/lib$');

## Try an unset argument too, constant case:
#
#sub mySub
#{
#    return $_[7] . "result";
#}
#
#assert(mySub() eq 'result');
#
## Try an unset argument too, variable case:
#
#sub mySubv
#{
#    my $i = 7;
#    return $_[$i] . "result";
#}
#
#assert(mySubv() eq 'result');

print "$0 - test passed!\n";
