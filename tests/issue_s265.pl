# issue s265 - use XXX in a sub, where XXX defines an import sub generates code with a bad indent
# pragma pythonizer -M
use Carp::Assert;

sub test {
    use lib '.';
    use issue_s265m;
    assert($::imported);
}

test();

print "$0 - test passed!\n";
