# issue s192 - Reference to a prior match capture group in a non-capturing match generates bad code
use Carp::Assert;

my $str = 'abcdef';

if($str =~ /(a)(b)(c)(d)(e)(f)/) {
    assert($str =~ /^$&$/);
    assert($str =~ /(a)(b)(c)(d)(e)(f)/);
    assert($str =~ /^$1$2$3$4$5$6$/);
    assert(($str.'b') =~ /^a(.)cdef\1$/);   # New match
    assert(($str.'b') =~ /^a(.)cdef\g1$/);   # New match
    assert(($str.'b') =~ /^a(.)cdef\g{1}$/);   # New match
    assert($str =~ /^a$1c(def)$/);        # $1 is the old match
    assert($1 eq 'def');
    $str =~ s/^(..)cdef$/x$1/;
    assert($str eq 'xab');
    assert($1 eq 'ab');
} else {
    assert(0);
}
print "$0 - test passed!\n";
