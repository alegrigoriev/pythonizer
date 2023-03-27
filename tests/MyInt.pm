# Part of issue_s330
package MyInt;

use strict;
use warnings;
use Carp::Assert;
use overload
  'int' => \&as_int,
  fallback => 1;

sub new {
  my ($class, $value) = @_;
  assert(defined $value, 'Value must be defined');
  assert($value =~ /^-?\d+$/, 'Value must be an integer');
  return bless { value => $value }, $class;
}

sub as_int {
  my ($self) = @_;
  return int($self->{value});
}

1;
