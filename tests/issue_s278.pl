# issue s278 - Any multi-line statement as the last statement of a sub causes bad code to be generated
use Carp::Assert;

sub test0 {
    2 +     # Tail comment 1
    # Line comment 1
    3 *     # Tail comment 2
    # Line comment 2
    7;      # Tail comment 3
}

assert(test0() == 23);

sub test1 {
    $i = 42;
    $
    i
}

assert(test1 == 42);

sub test2 {
    '
'
}

assert(test2 eq "\n");

sub test {
    open(FH, "<nope") or 
        ( print STDOUT "$0 - test passed!\n" and exit(0) );
}

test();

print "Test failed!";
exit(1);
