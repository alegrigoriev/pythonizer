# issue s216 - tie class methods need to be set on a subclass of the class, not on the tied class
use Carp::Assert;
package tie_it;

sub new {
    my $self = bless {}, shift;
    $self->{key} = 'value';
    return $self;
}

sub get {
    my ($self, $key) = @_;
    $key = 'key' unless defined $key;
    return $self->{$key};
}

# Stupid hash that only supports one key
sub TIEHASH {
    my $cls = shift;

    my $self = new $cls;
    return $self;
}

sub FETCH {
    my($self, $key) = @_;

    return exists $self->{$key} ? $self->{$key} : undef;
}

my $STORE_called = 0;
sub STORE {
    my($self, $key, $value) = @_;

    $STORE_called++;
    if($key ne 'key') {
        die "This hash only supports 'key' not '$key'";
    }
    $self->{$key} = $value;
}

sub EXISTS {
    my($self, $key) = @_;
    exists $self->{$key};
}

sub FIRSTKEY {
    return 'key';
}
sub NEXTKEY {
    return undef;
}

package main;

my $o = new tie_it;
assert($o->get eq 'value');
assert(!$STORE_called);
tie(my %h, 'tie_it');

assert($h{key} eq 'value');
$h{key} = 'new_value';
assert($h{key} eq 'new_value');
assert(exists $h{key});
assert($STORE_called);

eval {
    $h{new_key} = 'oops';
};
assert($@ =~ /This hash only/);

print "$0 - test passed!\n";
