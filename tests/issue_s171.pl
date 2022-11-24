# issue s171 - Deleting multiple hash entries using an array undef generates bad code
# See https://github.com/Perl/perl5/issues/20537 for the bug in perl here
use Carp::Assert;
#use Data::Dumper;

my %hash = (k1=>'v1', k2=>'v2', k3=>'v3');

my @to_undef = ('k1', 'k2');

undef @hash{@to_undef};

#print Dumper(\%hash) . "\n";

assert(exists $hash{k1} && exists $hash{k2} && exists $hash{k3});
assert($hash{k3} eq 'v3');
assert(!defined $hash{k2});
my $py = ($0 =~ /\.py$/);
assert(!defined $hash{k1}) if $py;  # perl has a bug here!

undef @to_undef;
#print Dumper(\@to_undef) . "\n";
assert(@to_undef == 0);

print "$0 - test passed!\n";
