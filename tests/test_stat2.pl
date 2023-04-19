# Test the new stat function

use Carp::Assert;
use File::stat qw/stat_cando stat/;
use Fcntl "S_IRUSR";
use Cwd qw/getcwd realpath/;

open(my $fh, '<', "$0");

sub is_wsl_mounted_directory {
    my $current_directory = getcwd();

    # Resolve symbolic link if it exists
    if (-l $current_directory) {
        $current_directory = realpath($current_directory);
    }

    # Check if the path is under /mnt/ or is a symlink to /mnt/
    return $current_directory =~ m{^/mnt/[a-zA-Z]/};
}

for $file ($0, $fh) {
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
    assert(! -x $st) unless is_wsl_mounted_directory();
    assert(-r $st);
    assert($st->cando(S_IRUSR, 1));
    assert(stat_cando(stat($file), S_IRUSR, 1));
}

close($fh);

print "$0 - test passed!\n";
