# issue s14: $#Package::Var doesn't generate correct code
use lib '.';
use Pscan;
use Carp::Assert;

assert(@Pscan::PythonCode == 1);
assert($#Pscan::PythonCode == 0);

if($Pscan::PythonCode[-1] eq '*') {
    $#Pscan::PythonCode--;
}
assert(scalar(@Pscan::PythonCode) == 0);
push @Pscan::PythonCode, 'x';
--$#{Pscan::PythonCode};
assert(scalar(@Pscan::PythonCode) == 0);

# another issue:

sub p_insert
{
    my ($package,$pos) = @_;
    if($pos <= $#{$package->{type}}) {
        splice(@{$package->{type}},$pos,0,'');
    } else {
        $package->{type}->[$pos] = '';
    }
}

@_ValType = ('t1', 't2');
my $package = {type=>\@_ValType};
p_insert($package, 0);
assert($package->{type}[0] eq '' && $package->{type}[1] eq 't1');

print "$0 - test passed!\n";
