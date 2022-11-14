# issue s153 - grep ! /pattern/ generates bad code
# from netdb/cgi-bin/agn/backplane.cgi
use Carp::Assert;

my $dir = ".";

opendir(DIR,$dir) or die("Can't open directory info");
@dirunsorted = grep !/^\.\.?$/, readdir(DIR);
# or die("Can't read directory info");;
closedir DIR;

my $found = 0;
foreach (@dirunsorted) {
    $found = 1 if /$0/;
}

assert($found);

# from the documentation:

my @bar = ('a', '# comment', 'b');
my @foo = grep(!/^#/, @bar);    # weed out comments
assert(@foo == 2);
assert($foo[0] eq 'a');
assert($foo[1] eq 'b');

@foo = grep {!/^#/} @bar;    # weed out comments
assert(@foo == 2);
assert($foo[0] eq 'a');
assert($foo[1] eq 'b');

print "$0 - test passed!\n";
