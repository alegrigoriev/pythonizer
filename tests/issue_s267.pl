# issue s267 - Regex pattern [\s\-_] should not be turned into a range
use Carp::Assert;
my @Alias = ();

define_alias(qr/\bkoi8[\s\-_]*([ru])$/i => '"koi8-$1"');

sub define_alias {
    while (@_) {
        my $alias = shift;
        my $name = shift;
        unshift( @Alias, $alias => $name )    # newer one has precedence
            if defined $alias;
    }
}

my %cases = ('Koi8 r'=>'"koi8-$1"', 'KOI8-U'=>'"koi8-$1"', 'koi8_u'=>'"koi8-$1"');
for my $key (keys %cases) {
    if($key =~ $Alias[0]) {
        assert($Alias[1] eq $cases{$key});
    }
}

print "$0 - test passed!\n";
