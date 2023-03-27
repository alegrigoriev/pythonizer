# issue s327 - List with hashes generates bad code
use strict;
use warnings;
use Carp::Assert;
no warnings 'experimental';

sub apply_override {
    my ($attr, $override_attr) = @_;
    # issue is caused by the fact that the ? : expression doesn't have 
    # consistent type as if it's true it's an array, and if it's 
    # false, it's a hash.  Also, the 2 hashes inside the sub-array need to
    # be expanded to lists and joined.
    my %at = %$attr;
    my %ap = ( ($override_attr) ? (%at, %$override_attr ) : %at );
    my $apply = { ($override_attr) ? (%$attr, %$override_attr ) : %$attr };
    assert(\%ap ~~ $apply);
    return $apply;
}

# Test case 1: No override attributes
{
    my $attr         = { key1 => 'value1', key2 => 'value2' };
    my $override_attr = undef;
    my $expected     = { key1 => 'value1', key2 => 'value2' };
    my $result       = apply_override($attr, $override_attr);

    assert(($result ~~ $expected), 'Test case 1: No override attributes');
}

# Test case 2: With override attributes
{
    my $attr         = { key1 => 'value1', key2 => 'value2' };
    my $override_attr = { key2 => 'new_value2', key3 => 'value3' };
    my $expected     = { key1 => 'value1', key2 => 'new_value2', key3 => 'value3' };
    my $result       = apply_override($attr, $override_attr);

    assert(($result ~~ $expected), 'Test case 2: With override attributes');
}

print "$0 - test passed!\n";
