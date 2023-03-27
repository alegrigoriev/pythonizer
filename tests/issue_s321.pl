# issue s321 - Hash slice on LHS generates bad code
# Written by chatGPT-4

use strict;
use warnings;

sub assign_hash_slice {
    my ($ref, $NAME, $row_ref) = @_;

    my @row = @$row_ref;
    @{$ref}{@$NAME} = @row;     # This is the line of code causing the issue

    return;
}

use Carp::Assert;

sub test_assign_hash_slice {
    {
        my %test_hash;
        my @keys = qw(one two three);
        my @values = (1, 2, 3);

        assign_hash_slice(\%test_hash, \@keys, \@values);

        assert($test_hash{one} == 1, 'Test 1: Value for key "one" should be 1');
        assert($test_hash{two} == 2, 'Test 1: Value for key "two" should be 2');
        assert($test_hash{three} == 3, 'Test 1: Value for key "three" should be 3');
    }

    {
        my %test_hash;
        my @keys = qw(a b c);
        my @values = (10, 20, 30);

        assign_hash_slice(\%test_hash, \@keys, \@values);

        assert($test_hash{a} == 10, 'Test 2: Value for key "a" should be 10');
        assert($test_hash{b} == 20, 'Test 2: Value for key "b" should be 20');
        assert($test_hash{c} == 30, 'Test 2: Value for key "c" should be 30');
    }

    {
        my %test_hash;
        my @keys = qw(cat dog);
        my @values = (100, 200);

        assign_hash_slice(\%test_hash, \@keys, \@values);

        assert($test_hash{cat} == 100, 'Test 3: Value for key "cat" should be 100');
        assert($test_hash{dog} == 200, 'Test 3: Value for key "dog" should be 200');
    }

    print "$0 - test passed!\n";
}

test_assign_hash_slice();

