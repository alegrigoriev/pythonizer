# issue s114: improper interpretation of interpolated string leads to bad code in next sub
# Code from pythonizer (bootstrap)
use Carp::Assert;

sub gen_statement
{
	my $arg = shift;
	assert($arg eq 'sys.argv[1:] = _ap_rem');
}

$ARG_PARSER="_ap";

sub getopts_fun                 # issue s67: implement getopt/getopts
{
    gen_statement("sys.argv[1:] = ${ARG_PARSER}_rem");      # issue 24
    #		   0.........1.........2.........3.
    #		   01234567890123456789012345678901
}

sub GetOptionsHandled           # issue 48: Can we handle this GetOptions call?
{
    my $start = shift;

    assert($start eq 'start');

}

getopts_fun();
GetOptionsHandled('start');

# additional test case from CGI.pm:
package CGI;
use Carp::Assert;
sub _style {
      my @result = ();
      if(0) {
          ;
      } else {
           my $src = $s;
           push(@result,$XHTML ? qq(<link rel="$rel" type="$type" href="$src" $other/>)
                               : qq(<link rel="$rel" type="$type" href="$src"$other>));
      }
      @result;
}

# The 'push' line above never got unstacked so the reference parameters in this next
# function are not recognized because we still think we are in a conditional!


sub _set_values_and_labels {
    my $self = shift;
    my ($v,$l,$n) = @_;
    $$l = $v if ref($v) eq 'HASH' && !ref($$l);
    return $self->param($n) if !defined($v);
    return $v if !ref($v);
    return ref($v) eq 'HASH' ? sort keys %$v : @$v;
}

sub new {
    bless {}, shift;
}

my $self = new CGI;
$values = {k1=>'v1', k2=>'v2'};
my ($labels, $name);
@values = $self->_set_values_and_labels($values,\$labels,$name);
assert($labels->{k1} eq 'v1');
assert($labels->{k2} eq 'v2');
assert(@values == 2);
assert($values[0] eq 'k1');
assert($values[1] eq 'k2');

print "$0 - test passed\n";
