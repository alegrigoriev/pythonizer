# tests for File::Path, from the documentation
use Carp::Assert;
use Data::Dumper;

use File::Path qw(make_path remove_tree);

@created = make_path('foo/bar/baz', './zug/zwang');
assert($created[0] eq 'foo');
assert($created[1] eq 'foo/bar');
assert($created[2] eq 'foo/bar/baz');
assert($created[3] eq './zug');
assert($created[4] eq './zug/zwang');
assert($#created == 4);
assert(-d 'foo/bar/baz');
assert(-d './zug/zwang');

@created = make_path('foo/bar/baz', './zug/zwang', {
    verbose => 1,
    mode => 0711,
});
assert(@created == 0);
assert(-d 'foo/bar/baz');
assert(-d './zug/zwang');

make_path('foo/bar/baz', './zug/zwang', {
    chmod => 0777,
});
assert(-d 'foo/bar/baz');
assert(-d './zug/zwang');

$removed_count = remove_tree('foo', 'zug', {
    #verbose => 1,
    #error  => \my $err_list,
    safe => 1,
});

assert($removed_count eq 5);
assert(!-d 'foo/bar/baz');
assert(!-d 'foo/bar');
assert(!-d 'foo');
assert(!-d './zug/zwang');
assert(!-d './zug');

print "$0 - test passed!\n";

END {
	eval {rmdir "foo/bar/baz"};
	eval {rmdir "foo/bar"};
	eval {rmdir "foo"};
	eval {rmdir "./zug/zwang"};
	eval {rmdir "./zug"};
}
