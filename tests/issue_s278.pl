# issue s278 - Complicated open or (x and exit(1)) as last statement of sub generates bad code
use Carp::Assert;

sub test {
    open(FH, "<nope") or 
        ( print STDOUT "$0 - test passed!\n" and exit(0) );
}

test();

print "Test failed!";
exit(1);
