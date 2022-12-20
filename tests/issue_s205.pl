# issue s205 - complex method call with -barewords generates bad code
# from CGI.pm
package issue_s205;
use Carp::Assert;

sub new {
    bless {}, shift;
}

sub header {
    my $self = shift;
    #print "header: @_\n";
    assert("@_" eq '-nph 0 -type t -charset c a 1 b 2');
    return "header";
}

sub multipart_end {
    return ';';
}

sub nph {
    assert(0);  # should not be called
}

sub charset {
    assert(0);  # should not be called
}

sub TIEHASH {       # Causes the issue with -nph and -charset
    assert(0);
}

@other = ('a=1', 'b=2');
sub issue {
    my $self = shift;
    my $type = shift;
    my $charset = shift;

    return $self->header(
	-nph => 0,
	-type => $type,
    -charset => $charset,
	(map { split "=", $_, 2 } @other),
    ) . "WARNING" . $self->multipart_end;
}

$p = new issue_s205;
$result = $p->issue('t', 'c');
assert($result eq 'headerWARNING;');

print "$0 - test passed!\n";
