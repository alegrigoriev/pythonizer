# pragma pythonizer pythonize stdlib
use CGI::Cookie;
use Carp::Assert;

sub test_cgi_cookie {
  # Test the new function
  my $cookie1 = CGI::Cookie->new(-name => 'cookie1', -value => 'value1');
  assert($cookie1->name eq 'cookie1', 'Cookie name is correct');
  assert($cookie1->value eq 'value1', 'Cookie value is correct');

  # Test the bake function
  # The simplest way to send a cookie to the browser is by calling the bake() method:
  # $c->bake;
  # This will print the Set-Cookie HTTP header to STDOUT using CGI.pm. CGI.pm will be loaded for this purpose if it is not already
  do {
      local *STDOUT;
      open(STDOUT, '>tmp.tmp');
      $cookie1->bake;
      close(STDOUT);
  };
  open(IN, '<tmp.tmp');
  my @lines = <IN>;
  close(IN);
  assert($lines[0] eq "Set-Cookie: cookie1=value1; path=/\r\n");
  #Date: Sat, 24 Dec 2022 02:04:37 GMT
  assert($lines[1] =~ /^Date: [A-Z][a-z][a-z], \d+ [A-Z][a-z][a-z] \d\d\d\d \d\d:\d\d:\d\d GMT/);
  assert($lines[2] eq "Content-Type: text/html; charset=ISO-8859-1\r\n");
  assert($lines[3] eq "\r\n");

  # Test the parse function
  my %cookie2 = CGI::Cookie->parse($cookie1->as_string);
  use Data::Dumper;
  #print Dumper(\%cookie2);
  my $cookie2 = $cookie2{cookie1};
  assert($cookie2->name eq 'cookie1', 'Parsed cookie name is correct');
  assert($cookie2->value eq 'value1', 'Parsed cookie value is correct');

  # Test the expires attribute
  my $cookie3 = CGI::Cookie->new(-name => 'cookie3', -value => 'value3', -expires => '+1M');
  #print STDERR "exp:" . $cookie3->expires . "\n";
  my $exp = $cookie3->expires;
  #print Dumper(\$exp);
  #'Mon, 23-Jan-2023 01:59:47 GMT'
  assert($cookie3->expires =~ /^[A-Z][a-z][a-z], \d+-[A-Z][a-z][a-z]-\d\d\d\d \d\d:\d\d:\d\d GMT$/, 'Cookie expires attribute is correct');
}

test_cgi_cookie();

END {
    unlink "tmp.tmp";
}
print "$0 - test passed!\n";
