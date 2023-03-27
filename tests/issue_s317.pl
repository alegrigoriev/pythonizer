# issue s317: complex method call generates bad code

use strict;
use warnings;
use Carp::Assert;

# Mocked function to simulate the original line of code
sub get_dbms_name {
    my $dbh = shift;

    # Mock the return value
    my $name = $dbh->{ado_conn}->Properties->Item('DBMS Name')->Value;

    return $name;
}

# Mocked object classes
{
    package MockedAdoConn;
    sub Properties {
        my $self = shift;
        return bless({}, 'MockedProperties');
    }
}

{
    package MockedProperties;
    sub Item {
        my $self = shift;
        my $property = shift;
        return bless({ Value => sub { return 'Mocked DBMS Name' } }, 'MockedItem') if $property eq 'DBMS Name';
    }
}

{
    package MockedItem;
    sub Value {
        my $self = shift;
        return $self->{Value}->();
    }
}

# Test driver
sub test_get_dbms_name {
    my $mocked_dbh = {
        ado_conn => bless({}, 'MockedAdoConn'),
    };

    my $dbms_name = get_dbms_name($mocked_dbh);
    assert($dbms_name eq 'Mocked DBMS Name', "The DBMS name is $dbms_name and not 'Mocked DBMS Name'");
}

# Run the test
test_get_dbms_name();

print "$0 - test passed!\n";
