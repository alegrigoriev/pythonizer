# issue s257 - .= operator with || generates incorrect code
# Code line under test from CGI.pm
# Written by chatGPT
use Carp::Assert;

sub update_url {
  my ($url, $vh) = @_;
  $url .= $vh || server_name();
  return $url;
}

sub server_name { "localhost" }

# Test case 1
my $url = "http://";
my $vh = "www.example.com";
my $expected = "http://www.example.com";
my $result = update_url($url, $vh);
assert($result eq $expected, "Test case 1 failed");

# Test case 2
$url = "http://";
$vh = "";
$expected = "http://".server_name();
$result = update_url($url, $vh);
assert($result eq $expected, "Test case 2 failed");

# Test case 3
$url = "https://";
$vh = undef;
$expected = "https://".server_name();
$result = update_url($url, $vh);
assert($result eq $expected, "Test case 3 failed");

print "$0 - test passed!\n";
