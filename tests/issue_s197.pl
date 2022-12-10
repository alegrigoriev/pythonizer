# issue s197 - complex ? : with defined and split generates bad code
# from CGI.pm
package issue_s197;
use Carp::Assert;

sub new {
    bless {}, shift;
}


sub Accept {
    my $self = shift;


    my(@accept) = defined $self->http('accept') 
                ? split(',',$self->http('accept'))
                : ();
    return @accept;
}

my $result = undef;

sub http {
    my $self = shift;
    my $arg = shift;

    assert($arg eq 'accept');
    return $result;
}

my $p = new issue_s197;
my @arr = $p->Accept();
assert(@arr == 0);

$result = 'a,b';
@arr = $p->Accept();
assert(@arr == 2);
assert($arr[0] eq 'a');
assert($arr[1] eq 'b');

print "$0 - test passed!\n";


