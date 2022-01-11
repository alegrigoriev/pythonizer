# Test statement as expression

use Carp::Assert;

sub testit
{
    my $j = 0;
    for(my $i=0; $i<3; $i++) {
        $j=$i, last if($i == 1);
    }

    eval {
        my $k;
        ($k = 1, $k+=1, die($k)) if($j == 1);
    };
    assert($@ =~ /^2 at test_stmt_expr/);

    my $lib;
    ($j == 1) ? ($lib = "./test_basename.pl", require $lib) : return 0;
    is('this', 'this');

    ($j == 1) ? ($j++, return $j) : 42;
}

assert(testit() == 2);

print "$0 - test passed!\n";
