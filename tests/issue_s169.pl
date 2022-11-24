# issue s169 - Bogus reference to scalar warnings on array and hash references
# pragma pythonizer verbose
use Carp::Assert;
use Getopt::Long;

my $ref = {Response => [
             {Get => [] }
           ]
          };

$pGet = \@{$ref->{'Response'}[0]{'Get'}};

assert(scalar(@$pGet) == 0);

my $pProcess = [ {k1=>'v1'}, {k2=>'v2'} ];
my $traphostno = 1;

$pIProcess = \%{ $pProcess->[$traphostno] };

assert($pIProcess->{k2} eq 'v2');

my $G_index = 0;
$pGet->[0]{Configuration}[0]{SNMP}[0]{TrapHostTable}[0]{TrapHost} = ['h1', 'h2'];
$pProcess  = \@{ $pGet->[$G_index]{'Configuration'}[0]{'SNMP'}[0]{'TrapHostTable'}[0]{'TrapHost'}};
assert($pProcess->[0] eq 'h1');

# Make sure we have no warnings on GetOptions
GetOptions('test' => \$Test);

my $warnme = 7;
$w = \$warnme;          # Warning on this line!
assert($$w == 7);

my $warnme2 = [1, 2];
$w = \$warnme2->[0];   # Warning on this line too!
assert($$w == 1);

print "Check we only have warnings produced on \$warnme and \$warnme2\n";
print "$0 - test passed!\n";
