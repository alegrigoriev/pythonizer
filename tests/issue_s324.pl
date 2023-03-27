# issue s324 - Calling a method via a variable generates bad code

use Carp::Assert;

sub connect_to_database {
    my ($drh, $connect_meth, $dsn, $user, $pass, $attr) = @_;
    return $drh->$connect_meth($dsn, $user, $pass, $attr);
}

# Create a mock database handler object and connection methods
{
    package MockDBHandler;
    sub new { bless {}, shift; }
    sub mock_connect_success { return "Connected"; }
    sub mock_connect_failure { return "Not Connected"; }
}

# Test connect_to_database subroutine - Test Case 1
{
    my $mock_db_handler = MockDBHandler->new();
    my $connect_meth = "mock_connect_success";
    my $dsn = "dbi:MockDB:dbname=testdb";
    my $user = "username";
    my $pass = "password";
    my $attr = { RaiseError => 1, PrintError => 0 };

    # Test if the correct connection string is returned
    my $result = connect_to_database($mock_db_handler, $connect_meth, $dsn, $user, $pass, $attr);
    assert($result eq "Connected");
}

# Test connect_to_database subroutine - Test Case 2
{
    my $mock_db_handler = MockDBHandler->new();
    my $connect_meth = "mock_connect_failure";
    my $dsn = "dbi:MockDB:dbname=testdb";
    my $user = "wrong_username";
    my $pass = "wrong_password";
    my $attr = { RaiseError => 1, PrintError => 0 };

    # Test if the connection failure is detected
    my $result = connect_to_database($mock_db_handler, $connect_meth, $dsn, $user, $pass, $attr);
    assert($result eq "Not Connected");
}

# Test connect_to_database subroutine - Test Case 3
{
    my $mock_db_handler = MockDBHandler->new();
    my $connect_meth = sub { $_[0]->mock_connect_success(@_[1..$#_]) };
    my $dsn = "dbi:MockDB:dbname=testdb";
    my $user = "username";
    my $pass = "password";
    my $attr = { RaiseError => 1, PrintError => 0 };

    my $result = connect_to_database($mock_db_handler, $connect_meth, $dsn, $user, $pass, $attr);
    assert($result eq "Connected");
}

print "$0 - test passed!\n";
