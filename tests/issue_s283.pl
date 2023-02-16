# issue s283 - Bad code geenrated for CORE::die(@_)
use Carp::Assert;

sub realdie { CORE::die(@_); }

eval {
    realdie "message";
};

assert($@ =~ /message/);

print "$0 - test passed!\n";
