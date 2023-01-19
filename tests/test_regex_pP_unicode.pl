# Written by chatGPT
use Carp::Assert;

my $string = "The quick brown fox jumps over the lazy dog.";
my $num = '123';
my $ctrl = "\x7f\x1f";
my $hex = 'aF1';

# Test \p{Lower}
assert( $string =~ /\p{Lower}/, "Error: No lowercase letters found." );

# Test \P{Upper}
assert( $string =~ /\P{Upper}/, "Error: No non-uppercase letters found." );

# Test \p{Alnum}
assert( $string =~ /\p{Alnum}/, "Error: No alphanumeric characters found." );

# Test \P{Punct}
assert( $string =~ /\P{Punct}/, "Error: No non-punctuation characters found." );

# Test \p{Digit}
assert( $num =~ /^\p{Digit}+$/, "Error: No digits found." );
assert( $string !~ /\p{Digit}/, "Error: Digits found." );

# Test \p{Hex}
assert( $hex =~ /^\p{Hex}+$/, "Error: No hex digits found." );
assert( $hex !~ /\P{Hex}/, "Error: Non-hex digits found." );

# Test \P{Space}
assert( $string =~ /\P{Space}/, "Error: No non-whitespace characters found." );

# Test \p{Symbol}
assert( $string !~ /\p{Symbol}/, "Error: Symbol characters found." );

# Test \p{Cc}
assert( $ctrl =~ /^\p{Cc}+$/, "Error: No control characters found." );
assert( $ctrl =~ /\p{Cntrl}/, "Error: No control characters found." );
assert( $ctrl =~ /\p{Control}/, "Error: No control characters found." );
assert( $ctrl =~ /\p{XPosixCntrl}/, "Error: No control characters found." );

# Test \P{Cc}
assert( $string =~ /\P{Cc}/, "Error: Control characters found." );


# Test \pL
assert( $string =~ /\pL/, "Error: No letters found." );

# Test \pN
assert( $num =~ /^\pN+$/, "Error: No numbers found." );

# Test \pZ
assert( $string =~ /\pZ/, "Error: No whitespace found." );

# Test \pC
assert( $ctrl =~ /\pC/, "Error: No control characters found." );

# Test \PL
assert( $string =~ /\PL/, "Error: No Non-letters found." );

# Test \PN
assert( $string =~ /\PN/, "Error: No Non-numbers found." );

# Test \PZ
assert( $string =~ /\PZ/, "Error: No Non-whitespace found." );

# Test \PC
assert( $string =~ /\PC/, "Error: Non-control characters found." );

#
# Test inside character class
# 

# Test [\pL]
assert( $string =~ /[\pL]/, "Error: No letters found." );

# Test [\pN]
assert( $num =~ /^[\pN]+$/, "Error: No numbers found." );

# Test [\pZ]
assert( $string =~ /[\pZ]/, "Error: No whitespace found." );

# Test [\pC]
assert( $ctrl =~ /^[\pC]+$/, "Error: No control characters found." );

# Test [\PL]
assert( $string =~ /[\PL]/, "Error: No Non-letters found." );

# Test [\PN]
assert( $string =~ /[\PN]/, "Error: No Non-numbers found." );
assert( $num !~ /[\PN]/, "Error: Non-numbers found." );

# Test [\PZ]
assert( $string =~ /[\PZ]/, "Error: No Non-whitespace found." );

# Test [\PC]
assert( $string =~ /[\PC]/, "Error: No Non-control characters found." );
assert( $ctrl !~ /[\PC]/, "Error: Non-control characters found." );


# Test [\p{Lowercase_Letter}]
assert( $string =~ /[\p{Lowercase_Letter}]/, "Error: No lowercase letters found." );

# Test [\p{Decimal_Number}]
assert( $num =~ /^[\p{Decimal_Number}]+$/, "Error: No decimal numbers found." );

# Test [\p{White_Space}]
assert( $string =~ /[\p{White_Space}]/, "Error: No whitespace found." );

# Test [\P{Uppercase_Letter}]
assert( $string =~ /[\P{Uppercase_Letter}]/, "Error: No non-uppercase letters found." );

# Test [\P{Punctuation}]
assert( $string =~ /[\P{Punctuation}]/, "Error: No non-punctuation characters found." );

# Test [\p{Hex}]
assert( $hex =~ /^[\p{Hex}]+$/, "Error: No hex digits found." );

print "$0 - test passed!\n";
