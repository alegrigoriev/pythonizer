# issue s256 - complex ? : expression with wantarray and grep generates bad code
package CGI;
use Carp::Assert;
$ENV{HTTPS} = 'a';

my $obj = new CGI;

# Scalar context test
my $https = $obj->https();
assert(defined($https), "HTTPS value is not defined");
assert($https eq  'a', "HTTPS value is wrong: $https");

# List context test
my @https_vars = $obj->https();
assert(scalar(@https_vars) > 0, "No HTTPS variables found");
foreach (@https_vars) {
    assert(/^HTTPS(?:_|$)/, "$_ is not a HTTPS variable");
}

sub self_or_CGI { return @_ };

sub https {
    my ($self,$parameter) = self_or_CGI(@_);
######## FIRST EXPRESSION OF INTEREST: Line 25-27 #########
    return wantarray
        ? grep { /^HTTPS(?:_|$)/ } sort keys %ENV
        : $ENV{'HTTPS'};
}

sub new { bless {}, shift }

# This from issue s194 so we can get them both correct at once!
my $tag = '<tag>';
my $untag = '</tag>';
my @rest = (['a', 'b']);
sub gen_tags {
######## SECOND EXPRESSION OF INTEREST: Line 38-39 #########
    my @result = map { "$tag$_$untag" } 
                          (ref($rest[0]) eq 'ARRAY') ? @{$rest[0]} : "@rest";
    return @result;
}
@tags = gen_tags();
assert(join(' ', @tags) eq '<tag>a</tag> <tag>b</tag>');
@rest = ('a', 'b');
@tags = gen_tags();
assert(@tags == 1);
assert($tags[0] eq '<tag>a b</tag>');

print "$0 - test passed!\n";
