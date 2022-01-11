# Test lexer hanging on long if

use Carp::Assert;

sub maybe_qualify {
    my ($self,$prefix,$name) = @_;
    my $v = ($prefix eq '$#' ? '@' : $prefix) . $name;
    if ($prefix eq "") {
	$name .= "::" if $name =~ /(?:\ACORE::[^:]*|::)\z/;
	return $name;
    }
    return $name if $name =~ /::/;
    return $self->{'curstash'}.'::'. $name
	if
	    $name =~ /^(?!\d)\w/         # alphabetic
	 && $v    !~ /^\$[ab]\z/	 # not $a or $b
	 && $v =~ /\A[\$\@\%\&]/         # scalar, array, hash, or sub
	 && !$globalnames{$name}         # not a global name
	 && $self->{hints} & $strict_bits{vars}  # strict vars
	 && !$self->lex_in_scope($v,1)   # no "our"
      or $self->lex_in_scope($v);        # conflicts with "my" variable
    return $name;
}

my $self = {};
my $prefix = '';
my $name = 'nameit';
assert(maybe_qualify($self, $prefix, $name) eq 'nameit');

print "$0 - test passed!\n";
