# issue s315 - push with grep generates bad code
# Code from DBI.pm
sub filter_by_data_type {
    my ($tia, $data_type, $dt_idx) = @_;

    my @ti;
    my @data_type_list = (ref $data_type) ? @$data_type : ($data_type);
    foreach my $data_type (@data_type_list) {
        if (defined($data_type) && $data_type != SQL_ALL_TYPES()) {
            push @ti, grep { $_->[$dt_idx] == $data_type } @$tia;
        }
        else {
            push @ti, @$tia;
        }
        last if @ti; # found at least one match
    }

    return @ti;
}

use Carp::Assert;

# Define SQL_ALL_TYPES
sub SQL_ALL_TYPES { -9999 }

# Define test data
my $tia = [    [1, 2, 3],
    [4, 5, 6],
    [7, 2, 9],
    [10, undef, 12],
    [13, 14, 15],
];

# Test filtering by a single data type
my @result = filter_by_data_type($tia, 2, 1);
assert((scalar @result) == 2);
foreach my $ti (@result) {
    assert($ti->[1] == 2);
}

# Test filtering by multiple data types
@result = filter_by_data_type($tia, [2, 5], 1);
assert((scalar @result) == 2);
my $count = 0;
foreach my $ti (@result) {
    if ($ti->[1] == 2 || $ti->[1] == 5) {
        $count++;
    }
}
assert($count == 2);

# Test filtering with undefined data type
@result = filter_by_data_type($tia, undef, 1);
assert((scalar @result) == 5);

# Test filtering with SQL_ALL_TYPES
@result = filter_by_data_type($tia, SQL_ALL_TYPES, 1);
assert((scalar @result) == 5);

# These tests are testing things that the fix for s315 broke:

# from cmt/diffdata.py:

sub bymixed {
   my $slot1;
   my $slot2;
   my $subslot1;
   my $subslot2;

   ($slot1,$subslot1) = ($_[0] =~ /(\d*)(\D*)/);
   ($slot2,$subslot2) = ($_[1] =~ /(\d*)(\D*)/);

   $slot1 <=> $slot2 or $subslot1 cmp $subslot2;
}

# Test cases for the bymixed subroutine
my @test_cases = (
    # Numeric parts are equal, non-numeric parts are equal
    ["123abc", "123abc", 0],
    # Numeric parts are equal, non-numeric parts are different
    ["0abc", "0def", -1],
    ["0def", "0abc", 1],
    ["123abc", "123xyz", -1],
    # Numeric parts are different, non-numeric parts are equal
    ["123xyz", "456xyz", -1],
    ["12xyz", "1xyz", 1],
    # Numeric parts are different, non-numeric parts are different
    ["123abc", "456xyz", -1],
    ["789abc", "456xyz", 1],
);

# Run each test case and assert the expected result
foreach my $test (@test_cases) {
    my ($input1, $input2, $expected) = @$test;
    my $result = bymixed($input1, $input2);
    assert($result == $expected, "Test failed: bymixed('$input1', '$input2') returned $result but expected $expected");
}

# from cmt/facility.py:

sub extract_node_and_name {
    my ($x) = @_;
    my ($node, $name) = ($x ? $x =~ /([a-z0-9]*)(.*)/ : ());
    return ($node, $name);
}

# Test case 1: $x is defined and matches the regular expression
my $x = "abc123 some string";
my ($node, $name) = extract_node_and_name($x);
assert($node eq "abc123");
assert($name eq " some string");

# Test case 2: $x is undefined
undef $x;
($node, $name) = extract_node_and_name($x);
assert(!defined $node);
assert(!defined $name);

# Test case 3: $x does not match the regular expression
$x = "abc!@#";
($node, $name) = extract_node_and_name($x);
assert($node eq 'abc');
assert($name eq '!@#');

# Test case 4: empty $x
$x = '';
($node, $name) = extract_node_and_name($x);
assert(!defined $node);
assert(!defined $name);

# from cmt/ndss.pl:

my %rinspans = (
  rin1 => {
    1 => 'value1',
    2 => 'value2',
    3 => 'value3'
  },
  rin2 => {
    1 => 'value4',
    2 => 'value5'
  }
);

my $rsdat = '';

foreach my $rin (sort keys %rinspans) {
  my $size = scalar keys %{$rinspans{$rin}};

  foreach my $seq (reverse sort {$a<=>$b} keys %{$rinspans{$rin}}) {
    $rsdat .= join("|","TPPDLEMBED|TDL0010498",
               $rin,$rinspans{$rin}{$seq},($size-$seq)+1)  . "\n";
  }
}

assert($rsdat eq "TPPDLEMBED|TDL0010498|rin1|value3|1
TPPDLEMBED|TDL0010498|rin1|value2|2
TPPDLEMBED|TDL0010498|rin1|value1|3
TPPDLEMBED|TDL0010498|rin2|value5|1
TPPDLEMBED|TDL0010498|rin2|value4|2
",
       "The constructed string should be as expected, not $rsdat");
# from cmt/peers.pl:

sub calculate_network_address {
    my ($ip1, $ip2, $ip3, $ip4, $mask1, $mask2, $mask3, $mask4) = @_;
    my $net = join ".", ($ip1 & $mask1), ($ip2 & $mask2), ($ip3 & $mask3), ($ip4 & $mask4);
    return $net;
}

sub test_calculate_network_address {
    my @test_cases = (
        {
            ip_address   => '192.168.1.1',
            subnet_mask  => '255.255.255.0',
            expected_net => '192.168.1.0',
        },
        {
            ip_address   => '10.0.0.1',
            subnet_mask  => '255.0.0.0',
            expected_net => '10.0.0.0',
        },
        {
            ip_address   => '172.16.32.5',
            subnet_mask  => '255.255.255.240',
            expected_net => '172.16.32.0',
        },
    );

    foreach my $test_case (@test_cases) {
        my $ip_address = $test_case->{ip_address};
        my $subnet_mask = $test_case->{subnet_mask};
        my $expected_net = $test_case->{expected_net};

        my @ip_octets = split /\./, $ip_address;
        my @mask_octets = split /\./, $subnet_mask;

        # NOTE: This is interpreted as calculate_network_address(map({int $_;} @ip_octets, map({int $_;} @mask_octets)))
        # e.g. the second map output is passed to the first map function
        my $net = calculate_network_address(map { int($_) } @ip_octets, map { int($_) } @mask_octets);

        assert($net eq $expected_net, "Test failed: IP: $ip_address, Mask: $subnet_mask, Expected: $expected_net, Got: $net");
    }
}

test_calculate_network_address();

print "$0 - test passed!\n";
