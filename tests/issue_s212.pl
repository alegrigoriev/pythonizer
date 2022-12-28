# issue s212 - shift->{key} generates bad code
package My_BaseClass;
use Carp::Assert;
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{attribute} = 'value';
    return $self;
}
sub attribute { shift->{attribute} }

my $obj = My_BaseClass->new;
assert($obj->attribute eq 'value');

# Try non-OO cases

sub getkey {
    shift->{key};
}
sub gethashelem {
    shift->{shift()};
}
sub gethashelem2 {
    shift()->{shift()};
}
sub getzero {
    shift->[0];
}
sub getarrayelem {
    shift->[shift];
}

my $hashref = {key=>'value'};
assert(getkey($hashref) eq 'value');
assert(gethashelem($hashref, 'key') eq 'value');
assert(gethashelem2($hashref, 'key') eq 'value');
my $arrref = [42, 43];
assert(getzero($arrref) == 42);
assert(getarrayelem($arrref, 1) == 43);

print "$0 - test passed!\n";
