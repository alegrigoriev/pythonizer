# issue s162 - file size operation can generate incorrect code
use Carp::Assert;
my $DATEDIR = '.';
my $line = 162;
if(-s ("$DATEDIR/issue_s$line.pl")){
    print "$0 - test passed!\n";
} else {
    assert(0);
}

