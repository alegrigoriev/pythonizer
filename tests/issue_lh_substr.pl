# issues with lh substrs in bootstrapping pythonizer
use Carp::Assert;
use File::Basename;

# pragma pythonizer -M

# from Perlscan::destroy:

$TokenStr = 0;  # Make it a mixed type
$TokenStr = 'abcdefgh';
$from = 2;
$howmany = 3;
substr($TokenStr,$from,$howmany)='';
assert($TokenStr eq 'abfgh');

# from pythonizer:
$k = 0;
$ValPy[$k] = 'sys.argv[1:]';
substr($ValPy[$k],-4) = '';        # Lose the '[1:]'

my $srcdir = dirname("./PyModules/IO/Handle.pm");
my $mdx = index($srcdir, 'PyModules');
substr($srcdir,$mdx) = '';      # Remove anything past the PyModules dir
assert($srcdir eq './');

print "$0 - test passed!\n";
