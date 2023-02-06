# Class::Struct test based on File::Stat
package F::S;
use Carp::Assert;
#use lib '..';
use Class::Struct qw(struct);
struct 'F::S' => [
     map { $_ => '$' } qw{
     dev ino mode nlink uid gid rdev size
     atime mtime ctime blksize blocks
     }
];

sub populate {
    my $stob = new();
    @$stob = @_;
    return $stob;
}
my $result = populate(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);

my $cnt = 0;
for(my $i = 0; $i < scalar(@$result); $i++) {
    assert($result->[$i] == $i+1);
    $cnt++;
}
assert($cnt == 13);
assert($result->mtime == 10);
print "$0 - test passed!\n";
