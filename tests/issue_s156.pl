# issue s156 - => in if statement generates bad code
use Carp::Assert;

my ($cmt, $result, $dy, @date);

$cmd = "ls -l|wc -l";
$result = `$cmd`;
assert($result > 500);
$dy = '01-01-01';
if ($result => 1) {
  $dy =~ s/-//g;
  push (@date, $dy);
}

assert(@date == 1);
assert($date[0] eq '010101');

print "$0 - test passed!\n";

