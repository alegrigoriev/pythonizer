# issue s208: Method call with multiple shift operators isn't being translated properly
package CGI;
use Carp::Assert;

sub new {
  my($class,@initializer) = @_;
  my $self = {};

  bless $self,$class;
  $self->upload_hook(shift @initializer, shift @initializer);
  $self;
}

sub upload_hook {
    my $self = shift;
    ($first, $second) = @_;
}

@init = (1, 2);

my $c = new CGI(@init);

assert($first == 1);
assert($second == 2);

print "$0 - test passed!\n";
