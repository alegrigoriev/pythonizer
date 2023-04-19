# issue s348 - Copies of @_ need to be autovivified
use Carp::Assert;

sub test {
	my(@args) = @_;
	assert(!$args[0], "$args[0] should evaluate to false");
}

test();

sub test2 {
	my @args = @_;
	assert(!$args[0], "$args[0] should evaluate to false");
}

test2();

sub test3 {
	my($class, @args) = @_;
	assert($class eq 'class');
	assert(!$args[0], "$args[0] should evaluate to false");
}
test3('class');

sub obj {			# from Date::Manip::Obj
	my(@args) = @_;
	$class = shift(@args);
	assert($class eq 'class');
	if(ref($args[0]) =~ /^Date::Manip/) {
		assert(0, "ref $args[0] should not match the pattern");
	}
}

obj('class');

print "$0 - test passed!\n";
