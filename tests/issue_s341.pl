# issue s341 - Bogus [Perlscan-S5450]: Unterminated string starting at line XX

use Carp::Assert;
no warnings 'experimental';

# Mock the required module
my $mod = 'TestModule';
{
    package Date::Manip::Lang::TestModule;
    our $Language = 'English';
    our @Encodings = qw( UTF-8 ISO-8859-1 );
}

# Create a test object
my $self = bless { data => {} }, 'Date::Manip::Lang::TestModule';

# The two lines of code to be tested (unchanged)
$$self{'data'}{'lang'} = ${ "Date::Manip::Lang::${mod}::Language" };
$$self{'data'}{'enc'}  = [ @{ "Date::Manip::Lang::${mod}::Encodings" } ];

# Assertions to verify the expected behavior
assert( $$self{'data'}{'lang'} eq 'English', 'Language value is correct' );
assert( @{$$self{'data'}{'enc'}} == 2, 'Encodings array has correct length' );
assert( $$self{'data'}{'enc'}[0] eq 'UTF-8', 'First encoding is UTF-8' );
assert( $$self{'data'}{'enc'}[1] eq 'ISO-8859-1', 'Second encoding is ISO-8859-1' );

# Let's change it up and try again
${ "Date::Manip::Lang::${mod}::Language" } = 'French';
@{ "Date::Manip::Lang::${mod}::Encodings" } = ('Encoding1', 'Encoding2');
assert(${ "Date::Manip::Lang::${mod}::Language" } eq 'French', "Language didn't update");
assert([@{ "Date::Manip::Lang::${mod}::Encodings" }] ~~ ['Encoding1', 'Encoding2'], "Encodings didn't update");

assert("${\"}" eq ' ', "LIST_SEPARATOR error");
assert(${"} eq ' ', "LIST_SEPARATOR error 2");  # " (fix editor)
assert("${0}" eq $0, "Program source error");
assert(${0} eq $0, "Program source error 2");
$_ = 'abcdefghi';
/def/;
assert(${`} eq 'abc', "PREMATCH error");  # ` (fix editor)
assert(${'} eq 'ghi', "POSTMATCH error"); # ' (fix editor)
assert(${^V} eq $^V, "Version error");

print "$0 - test passed!\n";
