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

my $is_wsl = 0;
if (open(my $fh, '<', '/proc/version')) {
    my $version_info = <$fh>;
    close($fh);
    $is_wsl = 1 if $version_info =~ /microsoft/i;
}

chmod 0444, "tmp.tmp";
my $perm = (stat "tmp.tmp")[2];
if($is_wsl) {       # WSL can turn on the +x bit
    assert(($perm & 0666) == 0444);
} else {
    assert(($perm & 0777) == 0444);
}

chmod 0644, "tmp.tmp";
$perm = (stat "tmp.tmp")[2];
if($is_wsl) {       # WSL can turn on the +x bit
    assert(($perm & 0644) == 0644);
} else {
    assert(($perm & 0700) == 0600); # Windows does something strange with the group/world bits
}

END {
    eval {
        unlink "tmp.tmp";
    };
}

print "$0 - test passed!\n";
