# open with one arg opens the file with the global scalar the same as the FH
use Carp::Assert;

$ARTICLE = 'tmp.tmp';

END {
    eval 'close(ARTICLE)';
    eval 'unlink "tmp.tmp"';
}

open(FH, '>tmp.tmp');
print FH "line in file\n";
close(FH);

open(ARTICLE);

assert(<ARTICLE> eq "line in file\n");

close(ARTICLE);

print "$0 - test passed!\n";
