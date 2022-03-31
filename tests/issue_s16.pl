# issue s16 - named capture groups are not properly translated into python (?P...)
# Rules: (?<NAME>pattern) => (?P<NAME>pattern)
#        \g{NAME} => (?P=NAME)
#        (?&NAME) => (?P>NAME)  [NOT SUPPORTED BY PYTHON!]
use Carp::Assert;

my $string = "Why did the chicken cross the road?";

if($string =~ /Why (?<WORD2>\w+) (?<THE>the) \w+ \w+ \g{THE}/) {
    assert($#+ == 2);
    assert("$#+" eq '2');
    assert($1 eq 'did');
    assert($+{WORD2} eq 'did');
    assert($+{'WORD2'} eq 'did');
    assert("$+{WORD2}" eq 'did');
    assert("$+{'WORD2'}" eq 'did');
    assert($2 eq 'the');
    assert($+{THE} eq 'the');
    assert("$-[1], $+[1]" eq '4, 7');
    assert($-[2] == 8);
    assert($+[2] == 11);
} else {
    assert(0);
}


# Three alternate forms of \g using \k:

if($string =~ /Why (?<WORD2>\w+) (?<THE>the) \w+ \w+ \k{THE}/) {
    assert($+{WORD2} eq 'did');
    assert($+{THE} eq 'the');
} else {
    assert(0);
}

if($string =~ /Why (?<WORD2>\w+) (?<THE>the) \w+ \w+ \k<THE>/) {
    assert($+{WORD2} eq 'did');
    assert($+{THE} eq 'the');
} else {
    assert(0);
}

if($string =~ /Why (?<WORD2>\w+) (?<THE>the) \w+ \w+ \k'THE'/) {
    assert($+{WORD2} eq 'did');
    assert($+{THE} eq 'the');
} else {
    assert(0);
}

print "$0 - test passed!\n";
