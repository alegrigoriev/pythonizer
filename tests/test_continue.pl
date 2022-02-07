# Test loops with "continue"
use Carp::Assert;

#From the documentation:
#When followed by a BLOCK, continue is actually a flow control statement rather than a function. If there is a continue BLOCK attached to a BLOCK (typically in a while or foreach), it is always executed just before the conditional is about to be evaluated again, just like the third part of a for loop in C. Thus it can be used to increment a loop variable, even when the loop has been continued via the next statement (which is similar to the C continue statement).
# last, next, or redo may appear within a continue block; last and redo behave as if they had been executed within the main block. So will next, but since it will execute a continue block, it may be more entertaining.
#while (EXPR) {
#    ### redo always comes here
#    do_something;
#} continue {
#    ### next always comes here
#    do_something_else;
#    # then back the top to re-check EXPR
#}
#### last always comes here
#



#Samples from the 'net:

my $result = '';
$a = 0;
while($a < 3) {
    #print "Value of a = $a\n";
    $result .= $a;
} continue {
   $a = $a + 1;
}
assert($a == 3);
assert($result eq '012');

$result = '';
@list = (1, 2, 3, 4, 5);
foreach $a (@list) {
    #print "Value of a = $a\n";
   $result .= $a;
} continue {
   last if $a == 4;
}
assert($result eq '1234');

# My own example:
my @ctr = (0,0,0,0,0,0,0);
OUTER:
while(1) {
    while(1) {
        $ctr[1]++;
        redo if($ctr[1] == 1);
        $ctr[2]++;
        next if($ctr[2] == 2);
        $ctr[3]++;
        last if($ctr[3] == 3 && $ctr[0] == 0);
    } continue {
        $ctr[4]++;
	#next if($ctr[4] == 1);
        $ctr[5]++;
	#redo if($ctr[5] == 2);
        $ctr[6]++;
        last if($ctr[6] == 6 && $ctr[0] == 1);
        last OUTER if($ctr[0] == 2);
    }
} continue {
    $ctr[0]++;
}
assert(join('', @ctr) eq '2987777');

print "$0 - test passed!\n";
