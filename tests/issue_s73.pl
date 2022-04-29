# issue s73: Multi-line q/.../ with line that starts with # is NOT a comment line

use Carp::Assert;

my $appease_cpants_kwalitee = q/
use strict;
use warnings;
#/;

assert($appease_cpants_kwalitee eq "\nuse strict;\nuse warnings;\n#");

# try some other cases:

my $contains_pod = '
=pod
not a pod
=cut';

assert($contains_pod eq "\n=pod\nnot a pod\n=cut");

my $contains_data = "
__DATA__
not data";

assert($contains_data eq "\n__DATA__\nnot data");

my $contains_goto = '
goto LABEL
not a goto';

assert($contains_goto eq "\ngoto LABEL\nnot a goto");

print "$0 - test passed!\n";
