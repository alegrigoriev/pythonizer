# Test whitespace after sigil
# It's amazing what perl will accept!!

use Carp::Assert;

$i = 10;
$s = 'a';
@a = (1,2);
%h = (k=>'v');

assert($ i == 10);
assert($	s eq 'a');
assert(@  a == 2);
assert($  h { k } eq 'v');
assert(scalar(% h ) == 1);
assert(scalar(% 
		h ) == 1);
assert(scalar(% 		# hey look at this!
# you still with me?
		h ) == 1);

assert(1
	%
	2 == 1);

assert($
	i == 10);

assert($			# comment in the middle of a variable!
				# how about another comment?
# one more just for good measure!
	i			# and another here
       	== 10);			# comment city!

assert($
	s eq 'a');

assert(@ 
a == 2);

assert(@ 		# How about a comment here too?
a == 2);

assert($ 
	h {
		k
	} eq 'v');

assert("$ i" == 10);

assert("$
i"
==
10);

assert("$
	0" =~ /test_ws/);

assert("@ a" eq '@ a');
#assert("$a [ 0 ]" eq ' [ 0 ]');
#assert("$h {k}" eq ' {k}');

# from HTTP::Date.pm: Pythonizer was trying to marry the '$' with the '#'

$_ = "Jan 3 12:22:13 EST 2022 ";
        (
        ( $mon, $day, $hr, $min, $sec, $tz, $yr )
        = /^
     (\w{1,3})             # month
        \s+
     (\d\d?)               # day
        \s+
     (\d\d?):(\d\d)        # hour:min
     (?::(\d\d))?          # optional seconds
        \s+
     (?:([A-Za-z]+)\s+)?   # optional timezone
     (\d+)                 # year
        \s*$               # allow trailing whitespace
    /x
        );
assert($mon eq 'Jan');
assert($day == 3);
assert($hr == 12);
assert($min == 22);
assert($sec == 13);
assert($tz eq 'EST');
assert($yr == 2022);

print "$0 - test passed!\n";
