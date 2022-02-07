# issue 72 - No code is generated to be able to open input or output pipes

use Carp::Assert;

my $rawfile = "f.txt.gz";
if (not open(FILE,"| gzip -c >$rawfile")) { die("Can't gzip to $rawfile $!") }
print FILE "test line 1\n";
print FILE "test line 2\n";
close(FILE);

if (not open(FILE,"gzip -dc $rawfile |")) { die("Can't unzip $rawfile $!") }
assert(<FILE> eq "test line 1\n");
assert(<FILE> eq "test line 2\n");
assert(!<FILE>);

print "$0 - test passed!\n";

END {
    eval {
        close(FILE);
    };
    eval {
        unlink "f.txt.gz";
    };
    sleep 3;
}
