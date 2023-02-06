# issue s268 - shift->method(...) generates bad code
use Carp::Assert;

package Encoding;

sub new { bless {}, shift }

sub encode {
    my $self = shift;
    my $arg = shift;

    return lc $arg;
}

sub fromUnicode { shift->encode(@_) }
sub fromUnicode2 { shift()->encode(@_) }
sub fromUnicode3 { shift(@_)->encode(@_) }

package main;

my $obj = new Encoding;

my $arg = "Hello World!";
my $expected_result = "hello world!";

assert($obj->encode($arg) eq $expected_result, "Encode($arg) ne $expected_result");

assert($obj->fromUnicode($arg) eq $expected_result, "fromUnicode($arg) ne $expected_result");
assert($obj->fromUnicode2($arg) eq $expected_result, "fromUnicode($arg) ne $expected_result");
assert($obj->fromUnicode2($arg) eq $expected_result, "fromUnicode($arg) ne $expected_result");

eval { Encoding::fromUnicode() };
assert($@ =~ /encode/);

print "$0 - test passed!\n";
