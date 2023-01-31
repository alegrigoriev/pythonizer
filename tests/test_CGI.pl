# Written mostly by chatGPT
# pragma pythonizer pythonize stdlib
# Import the CGI and Carp::Assert modules
use CGI;
use Carp::Assert;

# Create a new CGI object
my $cgi = CGI->new;

# Test the param() method
assert(!defined($cgi->param('foo')), 'param() should return undef for an undefined parameter');

# Test the header() method
assert($cgi->header eq "Content-Type: text/html; charset=ISO-8859-1\r\n\r\n", 'header() should return the default content type');

# Test the redirect() method
assert($cgi->redirect('http://www.example.com') eq "Status: 302 Found\r\nLocation: http://www.example.com\r\n\r\n", 'redirect() should return the correct location header');

# Test the cookie() method
assert(!defined($cgi->cookie('foo')), 'cookie() should return undef for an undefined cookie');

# Test the path_info() method
assert(!($cgi->path_info), 'path_info() should return "" by default');

# Test the query_string() method
assert(!($cgi->query_string), 'query_string() should return "" by default');

# Test the server_name() method
assert($cgi->server_name eq 'localhost', 'server_name() should return "localhost" by default');

# Test the self_url() method
assert($cgi->self_url eq 'http://localhost', 'self_url() should return the default URL');

# Test the header() method
assert($cgi->header(-type => 'text/html') eq "Content-Type: text/html; charset=ISO-8859-1\r\n\r\n", 'header() sets the correct content type');

# Test the start_html() method
my $start = qq(<!DOCTYPE html\n\tPUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n\t "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">\n<head>\n<title>Test Page</title>\n<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />\n</head>\n<body>\n);
assert(&is_eq($cgi->start_html(-title => 'Test Page'), $start), 'start_html() generates the correct HTML');

# Test the h1() method
assert($cgi->h1('Test Header') eq '<h1>Test Header</h1>', 'h1() generates the correct HTML');

# Test the end_html() method
assert(&is_eq($cgi->end_html , "\n</body>\n</html>"), 'end_html() generates the correct HTML');

sub is_eq {
    my ($s1, $s2) = @_;
    return 1 if $s1 eq $s2;
    my $ls1 = length($s1);
    my $ls2 = length($s2);
    print "ls1 = $ls2, ls2 = $ls2\n" if($ls1 != $ls1);
    my $i = 0;
    for($i = 0; $i < $ls1; $i++) {
        my $c1 = substr($s1, $i, 1);
        my $c2 = substr($s2, $i, 1);
        if($c1 ne $c2) {
            print "Mixmatch at pos $i: $c1 != $c2 (" . ord($c1) . " != " . ord($c2) . ")\n";
            last;
        }
    }
    print "$s1\n";
    print "$s2\n";
    print ' ' x $i;
    print "^\n";
    return 0;
}

print "$0 - test passed!\n";
