# issue s113 - invalid code generated for some OO function calls
# code from Softpano.pm issue 113 fix
# Error:
#    "%y%m%d_%H%M", perllib.localtime(perllib.int_(*perllib.stat(sys.argv[0])).mtime())
# TypeError: int_() takes 1 positional argument but 13 were given
# 
use Carp::Assert;
use POSIX qw/strftime/;
use File::stat;

$archive_dir = '.';
$script_name = $0;
$script_timestamp=strftime("%y%m%d_%H%M", localtime stat("$archive_dir/$script_name")->mtime);

assert($script_timestamp =~ /\d{6}_\d{4}/);

print "$0 - test passed\n";
