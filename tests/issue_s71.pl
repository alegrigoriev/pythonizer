#! /usr/bin/perl
# issue s71 - Getopt::Std generates wrong code if -M is active
# pragma pythonizer no implicit my

use Getopt::Std;
use Carp::Assert;
%options = ();
@ARGV=qw/-d D -m 2.5 -c 42.2 -D -i -i -n42 file1.f file2.fy/;
getopts("fDin:d:m:c:", \%options);
#print %options;
assert($options{d} eq 'D');
assert($options{m} == 2.5);
assert($options{c} == 42.2);
assert($options{D});
assert($options{i});
assert($options{n} == 42);
assert(!exists $options{f});
assert(scalar(@ARGV) == 2);

@ARGV=qw/-t -T TABLE -D -i -i -n/;
our $opt_t;
getopts('ftDinT:');
assert($opt_t);
assert($opt_D);
assert($opt_T eq 'TABLE');
assert($opt_i);
assert($opt_n);
assert(!defined $opt_f);
assert(scalar(@ARGV) == 0);

%options = ();
@ARGV=qw/-d D -m 2.5 -c 42.2 -D -i -i -n42 file1.f file2.fy/;
getopt("ndmc", \%options);
#print %options;
assert($options{d} eq 'D');
assert($options{m} == 2.5);
assert($options{c} == 42.2);
assert($options{D});
assert($options{i});
assert($options{n} == 42);
assert(!exists $options{f});
assert(scalar(@ARGV) == 2);

sub test_getopt_in_sub {
	@ARGV=qw/-t -T TABLE -D -i -i -n -a/;
	undef $opt_t, $opt_D, $opt_i, $opt_n;
	local $opt_T;	# Throw it a curve ball
	getopt('T');
	assert($opt_t);
	assert($opt_D);
	assert($opt_T eq 'TABLE');
	assert($opt_i);
	assert($opt_n);
	assert(!defined $opt_f);
	assert($opt_a);
	assert(scalar(@ARGV) == 0);
}

test_getopt_in_sub();

print "$0 - test passed!\n";
