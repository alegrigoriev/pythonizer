# issue 54 - Incorrect translation of perl chdir, chmod
use Carp::Assert;

chdir "..";
chomp($cwd = `pwd`);
assert($cwd !~ /tests/);
chdir "tests";
chomp($cwd = `pwd`);
assert($cwd =~ /tests/);

open(FH, ">tmp.tmp");
close(FH);

chmod 0444, "tmp.tmp";
my $perm = (stat "tmp.tmp")[2];
assert(($perm & 0777) == 0444);

chmod 0644, "tmp.tmp";
$perm = (stat "tmp.tmp")[2];
assert(($perm & 0700) == 0600); # Windows does something strange with the group/world bits

END {
    eval {
        unlink "tmp.tmp";
    };
}

print "$0 - test passed!\n";
