# issue s164 - Passing a -pragma on a use statement is not translated correctly
use Carp::Assert;

eval {
    use CGI qw(:standard -nph);
};

assert(!$@ || $@ =~ /No module named/);

print "$0 - test passed!\n";
