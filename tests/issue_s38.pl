# Assigning to a hashref marked as an array with a qw containing the keys generates bad code.  Who writes code like this LOL?  (From File::Path.pm)
use Carp::Assert;

$data = {depth=>1};
my $narg = {%$data};
my ($cur_dev, $cur_inode, $updir, $canon) = (1, 2, '..', 'canon');
@{$narg}{qw(device inode cwd prefix depth)} =
                  ( $cur_dev, $cur_inode, $updir, $canon, $data->{depth} + 1 );

assert($narg->{device} == 1);
assert($narg->{inode} == 2);
assert($narg->{cwd} eq '..');
assert($narg->{prefix} eq 'canon');
assert($narg->{depth} == 2);

print "$0 - test passed!\n";
