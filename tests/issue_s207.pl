# issue s207: Bless with || generates incorrect code
package CGI;
use Carp::Assert;
$DefaultClass = 'CGI' unless defined $CGI::DefaultClass;

# Please explain this perl code: bless $self,ref $class || $class || $DefaultClass;
# GPT: In the line of Perl code you provided, bless is a function that creates an object of a specified class. The bless function takes two arguments: a reference to the object to be created, and the name of the class.
# In the code you provided, the first argument is $self, which is a reference to the object being created. The second argument is ref $class || $class || $DefaultClass, which is an expression that determines the name of the class to use. This expression uses the ref function to check if $class is a reference. If $class is a reference, then ref $class returns the name of the class that the reference refers to. If $class is not a reference, then ref $class returns undef, and the || operator causes the expression to evaluate to $class instead. If $class is also undef, then the expression evaluates to $DefaultClass, which is the default class to use.
# Overall, this line of code creates an object of a specified class and blesses it, which means it associates the object with the class so that it can be used as an object of that class.

sub new {
  my($class,@initializer) = @_;
  my $self = {};

  # This test case gets an implicit "return" added to it
  bless $self,ref $class || $class || $DefaultClass;
}

sub new2 {
  my($class,@initializer) = @_;
  my $self = {};

  # No implicit "return" in this one:
  bless $self,ref $class || $class || $DefaultClass;
  $self;
}

sub new3 {
  my($class,@initializer) = @_;
  my $self = {};

  # This one has explicit parens
  bless ($self, ref $class || $class || $DefaultClass);
  $self;
}

my $c = new(undef, undef);
assert ref $c eq 'CGI';
my $c = new2(undef, undef);
assert ref $c eq 'CGI';
my $c = new3(undef, undef);
assert ref $c eq 'CGI';

# explain this line of perl code: my @a = split $u || $c, $v1 || $v2;

# GPT: In the line of Perl code you provided, split is a function that splits a string into a list of substrings based on a specified delimiter. The split function takes three arguments: the delimiter to use, the string to split, and an optional maximum number of substrings to return.
# In the code you provided, the first argument is $u || $c, which is an expression that determines the delimiter to use. This expression uses the || operator to check if $u is defined. If $u is defined, then $u || $c evaluates to $u, and $u will be used as the delimiter. If $u is not defined, then $u || $c evaluates to $c, and $c will be used as the delimiter instead.
# The second argument is $v1 || $v2, which is an expression that determines the string to split. This expression uses the || operator to check if $v1 is defined. If $v1 is defined, then $v1 || $v2 evaluates to $v1, and $v1 will be split using the delimiter specified by the first argument. If $v1 is not defined, then $v1 || $v2 evaluates to $v2, and $v2 will be split using the delimiter instead.
# The third argument is not provided, so the split function will split the string into as many substrings as possible.
# After the split function is called, the resulting list of substrings is assigned to the array @a.
# Overall, this line of code splits a string into a list of substrings using a specified delimiter, and assigns the resulting list of substrings to an array.

my $u = undef;
my $c = ',';
my $v1 = undef;
my $v2 = 'a,b';
my @a = split $u || $c, $v1 || $v2;
assert($a[0] eq 'a');
assert($a[1] eq 'b');

#my $a = chr $u || ord 'a';
#assert($a eq 'a');

print "$0 - test passed!\n";
