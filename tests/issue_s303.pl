# issue s303 - Need to use os.environ.get(...) on fetch from $ENV{...}, not os.environ[...]
use Carp::Assert;

sub FETCH {
    my ($self) = @_;
    $ENV{$$self};
}

my $key = 'NOT_FOUND';
my $actual = FETCH(\$key);
assert(!defined $actual);

# This fix causes an issue in rttp/load_member_account_ldap:

my $index = 1;
my %my_package = ();
my $package = 'package';
$my_packages{$index++} = $package;

assert(scalar(%my_packages) == 1);
assert($index == 2);
assert($my_packages{1} eq 'package');
print "$0 - test passed!\n";
