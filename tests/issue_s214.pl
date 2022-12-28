# issue s214 Assignment to a typeglob ref of an anonymous function doesn't work - this tests it in a class
# Based on issue_s76 
package issue_s214;
use Carp::Assert;

sub _all_html_tags {
	return qw/a h1/;
}

for my $tag ( _all_html_tags() ) {
	*$tag = sub {return _tag_func($tag,@_); };
}

sub _tag_func
{
	my $tagname = shift;

	my $result = $tagname;

	for my $arg (@_) {
		$result .= $arg;
	}
	return $result;
}

sub new {
    bless {}, shift;
}

my $is = new issue_s214;

assert(a('1', '2') eq 'a12');
assert(h1('heading') eq 'h1heading');

# from issue s31
my $field = "UNIX";
$_ = "UNIX";

*{"_IS_$_"} = $field eq $_ ? sub () { 1 } : sub () { 0 };

assert(_IS_UNIX() == 1);

assert(&{*{"_IS_$_"}}() == 1);

sub setattr {   # make sure we don't steal the name of the python builtin function
    return $_[0];
}
assert(setattr(1) == 1);

print "$0 - test passed!\n";
