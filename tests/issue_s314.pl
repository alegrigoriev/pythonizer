# issue s314 - Call via $subref->() in interpolated string generates incorrect code
# Written by chatGPT
use Carp::Assert;

my $subref1 = sub { return "Hello, world!" };
my $message1 = "The message is: @{ [ $subref1->() ] }";
assert($message1 eq "The message is: Hello, world!", "Incorrect message");

my $subref2 = sub { 
    my ($name, $age) = @_;
    return "$name is $age years old."; 
};

my $name = "Alice";
my $age = 25;
my $message2 = "The message is: @{ [ $subref2->($name, $age) ] }";
assert($message2 eq "The message is: Alice is 25 years old.", "Incorrect message");

$name = "Bob";
$age = 30;
$message2 = "The message is: @{ [ $subref2->($name, $age) ] }";
assert($message2 eq "The message is: Bob is 30 years old.", "Incorrect message");

$name = "Charlie";
$age = 40;
$message2 = "The message is: @{ [ $subref2->($name, $age) ] }";
assert($message2 eq "The message is: Charlie is 40 years old.", "Incorrect message");

$expected_tuple = [ 1, 4, 7 ];
my $fetch_tuple_sub = sub { 
    if(scalar(@_)) {
        my @result = map {$_ * $_[0]} @$expected_tuple;
        return \@result;
    }
    return $expected_tuple;
};
assert( "@{$fetch_tuple_sub->()}" eq "@$expected_tuple" );
my $double_tuple = [2, 8, 14];
assert( "@{$fetch_tuple_sub->(2)}" eq "@$double_tuple" );
my $two = 2;
assert( "@{$fetch_tuple_sub->($two)}" eq "@$double_tuple" );

assert("$two($two), $two(2), $two()" eq '2(2), 2(2), 2()');

# Error found in netdb/ixc/components/netlintdb/src/diff_ip_prefix.pl:

# define input data and expected output
my $newCLI = "ip prefix-list EXAMPLEc1-c2 seq 10 deny";
my $expectedOutput = "ip prefix-list c1-c2 seq <variable> deny";

# define %new2oldMap1
my %new2oldMap1 = (
    "ip prefix-list EXAMPLEc1-c2 seq 10 deny" => "EXAMPLE",
    # add more mappings as needed
);

# This is the line under test:
$newCLI =~s/^ip prefix-list $new2oldMap1{$newCLI}(\w+-*\w+) seq \d+ deny/ip prefix-list $1 seq <variable> deny/;

#print "$newCLI\n";
assert($newCLI eq $expectedOutput, "Substitution failed");

print "$0 - test passed!\n";
