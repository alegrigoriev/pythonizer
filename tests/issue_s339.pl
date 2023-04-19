# issue s339 - Use of uninitialized value in string eq at ../../Perlscan.pm line 9614

# Define a simple class with the __calc_date_date method stubbed out
package MyBaseClass;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub __calc_date_date {
    my ($self, $mode, $date1, $tz1, $isdst1, $date2, $tz2, $isdst2) = @_;
    return [42]; # Stubbed out, returning a reference to an array with a single element
}

# A wrapper method for the code you provided
sub calculate_delta {
    my ($self, $mode, $date1, $tz1, $isdst1, $date2, $tz2, $isdst2) = @_;
    my (@delta);
    @delta = @{ $self->__calc_date_date($mode, $date1, $tz1, $isdst1, 
                                        $date2, $tz2, $isdst2) };
    return @delta;
}

package MyClass;
@ISA = ('MyBaseClass');

sub has_out_parameter {         # Causes one of the issues
    my ($self, $in_p, $out_p) = @_;

    $$out_p = $in_p;
}

package main;
use Carp::Assert;

# Test case
{
    my $obj = MyClass->new();

    my $mode = "days";
    my $date1 = 1620000000;
    my $tz1 = "UTC";
    my $isdst1 = 0;
    my $date2 = 1620003600;
    my $tz2 = "UTC";
    my $isdst2 = 0;

    my @delta = $obj->calculate_delta($mode, $date1, $tz1, $isdst1, $date2, $tz2, $isdst2);
    assert($delta[0] == 42, "Expected __calc_date_date to return an array reference with 42 as its element");

    my ($in_p, $out_p);

    $in_p = 42;
    $obj->has_out_parameter($in_p, \$out_p);

    assert($out_p == 42, "Expected has_out_parameter to return 42, not $out_p");
}

print "$0 - test passed!\n";
