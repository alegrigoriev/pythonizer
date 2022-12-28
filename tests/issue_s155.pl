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

# Additional test cases

{
    package my_pack;
    use Carp::Assert;
    sub two { 2 };
    assert(two() == 2);
}

assert(!defined &main::two);

INIT {
    package init_pack;
    $init = 1;
    sub three { 3 };
    $init++;
}
assert(init_pack::three() == 3);
assert($init_pack::init == 2);

BEGIN {
    sub one { 1 }
}

assert(one() == 1);
assert(main::one() == 1);

print "$0 - test passed!\n";

