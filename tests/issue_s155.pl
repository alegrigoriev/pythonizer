# issue s155 - nested BEGIN block generates bad code
# from netdb/cgi-bin/agn/diff_fp_router-2.cgi
use Carp::Assert;

assert($begin == 4);

my $format = 'HTML';

if($format eq 'HTML') {
    colorshow(""); # reset back to
  BEGIN {
    $begin = 1;
    my $currentcolor = "blue";
    sub colorshow {
       $shown = $currentcolor;
    }
  }

  $here = 1;
   
   
} else {
   BEGIN {
       $begin++;
   }
   $here = 2;
}

assert($shown eq 'blue');
assert($here == 1);

BEGIN {
    $begin *= 2;
}

END {
    $begin = 0;
}

assert($begin == 4);

END {
    assert($begin == 4);
}

print "$0 - test passed!\n";

