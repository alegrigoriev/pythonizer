# issue s235 - Syntax  error in generated code $selected{$_}++ for $self->param($name);
use Carp::Assert;

package CGI;
use Carp::Assert;
sub new { bless {}, shift }
sub param {
    my ($self, $arg) = @_;
    assert(ref $self eq 'CGI');
    assert($arg eq 'input');
    return wantarray ? ('a', 'b') : 'a';
}
package main;

my $self = new CGI;
my $name = 'input';

$selected{$_}++ for $self->param($name);

assert(scalar(%selected) == 2);
assert($selected{a} == 1);
assert($selected{b} == 1);

print "$0 - test passed!\n";
