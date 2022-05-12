# issue s76: Assignment to a typeglob ref of an anonymous function doesn't work
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

assert(a('1', '2') eq 'a12');
assert(h1('heading') eq 'h1heading');

print "$0 - test passed!\n";
