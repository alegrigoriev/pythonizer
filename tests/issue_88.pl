# issue 88 - -bareword not handled

use Carp::Assert;

# Unary "-" performs arithmetic negation if the operand is numeric, including any string that looks like a number. If the operand is an identifier, a string consisting of a minus sign concatenated with the identifier is returned. Otherwise, if the string starts with a plus or minus, a string starting with the opposite sign is returned. One effect of these rules is that -bareword is equivalent to the string "-bareword"

assert(-23 == 0-23);
assert(-bareword eq "-bareword");
assert(-bare_word eq "-bare_word");

print "$0 - test passed!\n";
