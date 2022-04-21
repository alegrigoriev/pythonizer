# issue s64: Implement new # pragma no convert regex for bootstrap
use Carp::Assert;

sub perl_regex_to_python
{
    $regex = shift;
    # pragma pythonizer no convert regex
    $regex =~ s'\\Z'$'g;

    return $regex
}

assert(perl_regex_to_python("\\Z") eq '$');

print "$0 - test passed!\n";
