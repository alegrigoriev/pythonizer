# Ensure we updated the version number in the pythonizer file
use Carp::Assert;

open(FH, "<../pythonizer") or die("Can't open ../pythonizer file");
while(<FH>) {
    if(/^# (\d+[.]\d+)\s+\d{4}\/\d{2}\/\d{2}\s+[A-Z]+\s+/) {
        $ver_comment = $1;
    } elsif(/\s*\$VERSION\s*=\s*'(\d+[.]\d+)';/) {
        $ver = $1;
        last;
    }
}
close(FH);
assert(defined $ver and $ver == $ver_comment);
print "$0 - test passed!\n";
