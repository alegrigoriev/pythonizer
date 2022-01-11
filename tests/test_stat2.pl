# Test the new stat function

use Carp::Assert;
use File::stat;

$file = $0;
$st = stat($file) or die "No $file: $!";
assert(($st->mode & 0644) == 0644);
assert($st->nlink == 1);
assert($st->uid == $st->uid);
assert($st->gid == $st->gid);
assert($st->dev);
assert($st->ino);
assert($st->rdev == $st->rdev);
assert($st->size);
assert($st->atime);
assert($st->mtime);
assert($st->ctime);
assert($st->blksize);
assert($st->blocks);
assert(-f $st);
assert(! -x $st);
assert(-r $st);
use Fcntl "S_IRUSR";
assert($st->cando(S_IRUSR, 1));

print "$0 - test passed!\n";
