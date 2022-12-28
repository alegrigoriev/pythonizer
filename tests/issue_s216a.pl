# issue s216a - tie class methods need to be set on a subclass of the class, not on the tied class
# This test uses a combo class that can be either a hash or an array
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

# Stupid array that only supports element 0
sub TIEARRAY {
    my $cls = shift;
    my $self = bless([], $cls);
    $self->[0] = 1;
    $self;
}

sub FETCH {
    my($self, $key) = @_;

    if($key eq '0') {
        return exists $self->[$key] ? $self->[$key] : undef;
    }

    return exists $self->{$key} ? $self->{$key} : undef;
}

my $STORE_called = 0;
sub STORE {
    my($self, $key, $value) = @_;

    $STORE_called++;
    if($key eq '0') {
        $self->[$key] = $value;
        return $value;
    } elsif($key ne 'key') {
        die "This hash only supports 'key' not '$key'";
    }
    $self->{$key} = $value;
}

sub EXISTS {
    my($self, $key) = @_;

    return 1 if $key eq '0' && exists $self->[$key];
    exists $self->{$key};
}

sub FETCHSIZE {
    return 1;
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
for (keys %h) {
    assert($_ eq 'key');
    $cnt++
}
assert($cnt == 1);

eval {
    $h{new_key} = 'oops';
};
assert($@ =~ /This hash only/);

my $aref = tie(my @a, 'tie_it');
assert($a[0] == 1);
$a[0] = 3;
assert($a[0] == 3);
assert(join(' ', @a) eq '3');
$cnt = 0;
for (@a) {
    assert $_ == 3;
    $cnt++;
}
assert($cnt == 1);
assert($STORE_called == 3);

print "$0 - test passed!\n";
