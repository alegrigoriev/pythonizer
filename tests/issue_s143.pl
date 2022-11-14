# issue s143 - complex hash assignment with regex substitute generates incorrect code
# from netdb/common/components/rocdb/src/interface.pl
use Carp::Assert;

my $if = {description=>['This is the description with some "quotes"', '']};
my %rec = (
        description => ''
    );
($rec{description} = @{$if->{description}}[0]) =~
        s/"/'/g if(defined $if->{description}); #'"

assert($rec{description} eq "This is the description with some 'quotes'");

print "$0 - test passed!\n";

