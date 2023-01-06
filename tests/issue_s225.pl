# issue s225 - require statement in a sub for a translated standard package doesn't work properly
use Carp::Assert;
use lib './subdir';
require 5.004;

sub check_it {
    require subsubdir::Util;

    eval {                  # Make sure require doesn't pull in the @EXPORT functions!
        myutil(0);
    };
    assert($@ =~ /myutil/);

    assert(subsubdir::Util::myutil(1) == 2);
}

check_it();

print "$0 - test passed!\n";
