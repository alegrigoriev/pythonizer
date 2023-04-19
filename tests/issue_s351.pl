# issue s351 - sort that looks like a sub call generates incorrect code
no warnings 'experimental';
use Carp::Assert;

@tmp1 = ('abc', 'a', 'ab');
@tmp1 = sort _sortByLength @tmp1;	# _sortByLength is a custom comparator
assert(@tmp1 ~~ ['abc', 'ab', 'a']);

@tmp2 = ('abc', 'a', 'ab');

@tmp2 = sort _sortByLength(@tmp2);	# _sortByLength is a custom comparator
assert(@tmp2 ~~ ['abc', 'ab', 'a']);

@tmp2l = sort _sortByLength('ab', 'a', 'abc');	# _sortByLength is a custom comparator
assert(@tmp2l ~~ ['abc', 'ab', 'a']);

sub _sortByLength {
	   return (length $b <=> length $a);
   }

sub returnArray {
	return @_;
}

@tmp3 = sort &returnArray(@tmp2);	# returnArray is NOT a custom comparator
assert(@tmp3 ~~ ['a', 'ab', 'abc']);

@tmp4 = sort (returnArray(@tmp2));	# returnArray is NOT a custom comparator
assert(@tmp4 ~~ ['a', 'ab', 'abc']);

print "$0 - test passed!\n";

