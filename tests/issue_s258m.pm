package issue_s258m;
use parent 'Exporter';
our @EXPORT_OK = qw(escape);

sub escape {
  # If we being called in an OO-context, discard the first argument.
  shift() if @_ > 1 and ( ref($_[0]) || (defined $_[1] && $_[0] eq $issue_s258::DefaultClass));
  my $toencode = shift;
  return undef unless defined($toencode);
  return $toencode;
}
1;
