use Carp::Assert;

open (STDOUT, ">tmp.tmp");

print "12 terms of the fibonacci series\n";
$a = 0 ;
$b = 1 ;
print "$a $b ";
for ( $i = 2; $i <= 12; $i++)
{
   $c = $a + $b;
   print "$c ";
   $a = $b ;
   $b = $c ;
}
print "\n";
close STDOUT;
open(FD, "<tmp.tmp");
my $line;
chomp($line = <FD>);
assert($line eq "12 terms of the fibonacci series");
chomp($line = <FD>);
assert($line eq "0 1 1 2 3 5 8 13 21 34 55 89 144 ");
close FD;
unlink "tmp.tmp";

say STDERR "$0 - test passed!";
