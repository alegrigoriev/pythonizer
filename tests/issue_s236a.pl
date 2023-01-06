# issue s236a - Method calls via a scalar containing a string give an AttributeError
# This version uses 3 separate files
# pragma pythonizer -M
use lib '.';
use issue_s236m;
use Carp::Assert;

# Test cases:
# 1. The case that's causing the issue from CGI.pm:

$fh = 0;
$got_here = 0;

$issue_s236m::DefaultClass->binmode( ++$fh );

assert($got_here == $fh);

# 2. Use the Class object (captured in 'new')
my $obj = new issue_s236m;
assert($obj->isa('issue_s236m'));
$object = $obj;
assert($object->isa('issue_s236m'));
$issue_s236m::OurClass->binmode(++$fh);
assert($got_here == $fh);

# 3. Use a copy of the object
$::object->binmode(++$fh);
assert($got_here == $fh);

# 4. Use a regular object
$obj->binmode(++$fh);
assert($got_here == $fh);

# 5. Use a local string variable
my $str = 'issue_s236m';
$str->binmode(++$fh);
assert($got_here == $fh);

# 6. use constant string alias
use constant cgi => 'issue_s236m';
cgi->binmode(++$fh);
assert($got_here == $fh);

# 7. Use a hash key
my %hash = (key=>'issue_s236m');
$hash{key}->binmode(++$fh);
assert($got_here == $fh);

# 8. Use a hashref
my $hashref = \%hash;
$hashref->{key}->binmode(++$fh);
assert($got_here == $fh);

# 9. Use an array element
my @arr = ('issue_s236m');
$arr[0]->binmode(++$fh);
assert($got_here == $fh);

# 10. Use an arrayref
my $aref = \@arr;
$aref->[0]->binmode(++$fh);
assert($got_here == $fh);

# 11. Use a hashref containing an arrayref
$hashref->{arr} = $aref;
$hashref->{arr}->[0]->binmode(++$fh);
assert($got_here == $fh);

# 12. Use a hashref containing an arrayref in parens
($hashref->{arr}->[0])->binmode(++$fh);
assert($got_here == $fh);

# 13. Use a bareword package name
issue_s236m->binmode(++$fh);
assert($got_here == $fh);

# 14. Test MethodType subs
my $obj2 = issue_s236m->new;
assert($obj2->isa('issue_s236m'));
my $obj3 = issue_s236m->newer;
assert($obj3->isa('issue_s236m'));
my $obj4 = newer issue_s236m;
assert($obj4->isa('issue_s236m'));
# _copy is NOT a MethodType because it's used in 'use overload'
$obj4->{key} = 'value';
my $obj5 = issue_s236m::_copy($obj4);
assert($obj5->isa('issue_s236m'));
assert($obj5->{key} eq 'value');

# 15. Use the name of a subclass
use issue_s236msub;

$issue_s236msub::SubClass->binmode( ++$fh );
assert($got_here == $fh);

# 16. Use an object of a subclass
my $sobj = issue_s236msub->new;
assert($sobj->isa('issue_s236msub') && $sobj->isa('issue_s236m'));

# 17. Use a bareword subpackage name
issue_s236msub->binmode(++$fh);
assert($got_here == $fh);

print "$0 - test passed!\n";
