# issue s311 - Use of uninitialized value within @ValClass in string eq at ../../pythonizer line 8392
use Carp::Assert;
no warnings 'experimental';

my %hash_of_arrays = (
    'a' => [1, 2, 3],
    'b' => [4, 5, 6],
    'c' => [7, 8, 9],
);

my @bind_ids = ('a', 'b', 'c');
my $maxlen = 3;

my $tuple_idx = 0;
my $fetch_tuple_sub = sub {
    return if $tuple_idx >= $maxlen;
    my @tuple = map {
        my $a = $hash_of_arrays{$_};
        ref($a) ? $a->[$tuple_idx] : $a
    } @bind_ids;
    ++$tuple_idx;
    return \@tuple;
};

my $expected_tuple = [1, 4, 7];
#assert( "@{$fetch_tuple_sub->()}" eq "@$expected_tuple" );
assert($fetch_tuple_sub->() ~~ $expected_tuple);


use strict;
use warnings;
use Carp::Assert;

# Include the provided code
{
    package DBD::_::db;

    sub make {
        my $class = shift;
        my $self  = {};
        bless $self, $class;
        return $self;
    }

    sub table_info {
        my $self = shift;
        my $sth  = DBD::_::st->new;
        return $sth;
    }

    sub get_info {
        return undef;
    }

    sub quote_identifier {
        my $self = shift;
        return join('.', @_);
    }

    sub tables {
        my ($dbh, @args) = @_;
        my $sth    = $dbh->table_info(@args[0,1,2,3,4]) or return;
        my $tables = $sth->fetchall_arrayref or return;
        my @tables;
        if (defined($args[3]) && $args[3] eq '%' # special case for tables('','','','%')
            && grep {defined($_) && $_ eq ''} @args[0,1,2]
        ) {
            @tables = map { $_->[3] } @$tables;
        } elsif ($dbh->get_info(29)) { # SQL_IDENTIFIER_QUOTE_CHAR
            @tables = map { $dbh->quote_identifier( @{$_}[0,1,2] ) } @$tables;
        }
        else {		# temporary old style hack (yeach)
            @tables = map {
            my $name = $_->[2];
            if ($_->[1]) {
                my $schema = $_->[1];
                # a sad hack (mostly for Informix I recall)
                my $quote = ($schema eq uc($schema)) ? '' : '"';
                $name = "$quote$schema$quote.$name"
            }
            $name;
            } @$tables;
        }
        return @tables;
    }
}

{
    package DBD::_::st;

    sub new {
        my $class = shift;
        my $self  = {};
        bless $self, $class;
        return $self;
    }

    sub fetchall_arrayref {
        my $self = shift;
        return [
            [ undef, 'Schema1', 'Table1' ],
            [ undef, 'Schema2', 'Table2' ],
        ];
    }
}

# Create a mocked object
my $dbh = DBD::_::db->make;

# Call the 'tables' method and store the result
my @tables = DBD::_::db::tables($dbh, '', '', '%');

# Test the temporary old style hack (yeach)
#print "@tables\n";
assert( $tables[0] eq '"Schema1".Table1', 'First table name is correct' );
assert( $tables[1] eq '"Schema2".Table2', 'Second table name is correct' );

print "$0 - test passed!\n";
