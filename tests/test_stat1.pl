# Test the old-school stat function (ref: tms-cgi-lib.pl)

use Carp::Assert;

# Note we do NOT use File::stat
#

my $writefiles = '/usr/bin/xxx';
stat ($writefiles);
$writefiles = "/tmp" unless  -d _ && -r _ && -w _;

assert($writefiles eq '/tmp');

$_ = $0;
stat;
assert((!-d _) && -r _ && -w _);

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
    $atime,$mtime,$ctime,$blksize,$blocks)
       = stat "./" . $0;

assert(($mode & 0644) == 0644);
#assert($uid);
#assert($gid);
assert($size);
assert($atime);

my ($dev1,$ino1,$mode1,$nlink1,$uid1,$gid1,$rdev1,$size1,
    $atime1,$mtime1,$ctime1,$blksize1,$blocks1) = stat _;

assert($ino1 == $ino);
assert($size1 == $size);
assert($mtime1 == $mtime);
assert($uid1 == $uid);

# test stat FILEHANDLE
open(my $fh, '<', $0);

my ($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
    $atime2,$mtime2,$ctime2,$blksize2,$blocks2) = stat $fh;

assert($ino2 == $ino);
assert($size2 == $size);
assert($mtime2 == $mtime);
assert($uid2 == $uid);

assert((!-d _) && -r _ && -w _);
close($fh);

# test stat DIRHANDLE

opendir(my $dh, '.');
my @stat = stat $dh;
assert(-d _ && -r _ && -w _);
closedir($dh);

print "$0 - test passed!\n";
