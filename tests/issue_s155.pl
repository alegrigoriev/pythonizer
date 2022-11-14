# issue s155 - nested BEGIN block generates bad code
# from netdb/cgi-bin/agn/diff_fp_router-2.cgi
use Carp::Assert;

my $format = 'HTML';

if($format eq 'HTML') {
    colorshow(""); # reset back to
  BEGIN {
    my $currentcolor = "blue";
    sub colorshow {
       $shown = $currentcolor;
    }
  }

  $here = 1;
   
   
} else {
   $here = 2;
}

assert($shown eq 'blue');
assert($here == 1);

print "$0 - test passed!\n";

