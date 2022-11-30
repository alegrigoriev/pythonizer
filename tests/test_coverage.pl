# Additional tests to increase code coverage
use Carp::Assert;
use Data::Dumper;
use v5.10;

# Pass 0 coverage issues
# pragma pythonizer no implicit global my, no pythonize stdlib, no import perllib, no autovivification, no black, no replace usage, author, autodie, trace run, traceback
if(0) {
	print "Usage: test_coverage.pl";
}
# Check the generated code that these options are on!
$py = ($0 =~ /\.py$/);
if($py) {
	open(my $source, '<', "$0");
	@source = <$source>;
	# Do one pass thru checking for a python line corresponding to each of the options given above
	$cnt = 0;
	for (@source) {
		$cnt++ if /^__author__ =/;	# author
		$cnt++ if /^AUTODIE = 1/;	# autodie
		$cnt++ if /^TRACE_RUN = 1/;	# trace run
		$cnt++ if /^TRACEBACK = 1/;	# traceback
		$cnt++ if /^def _init_package/;	# no import perllib
		$cnt++ if /^main\.py_v =/;	# no implicit global my
		$cnt++ if /^main\.blank_v = ''/;	# no black
		$cnt++ if /Usage: test_coverage.pl/;	# no replace usage - this will count also so we add 1 to the assert value
		$cnt++ if /^main\.main_a = \['main'\]/;	# no autovivification
	}
	assert($cnt == 10);
}

# Perlscan coverage issues:
# loop_ndx_with_label: case with Label
# We can't do this because it's only used by 'redo' and redo with label is not supported!
=pod
LAB:
while($i < 10) {
	while($j < 10) {
		$cnt++;
		do {$j++; redo LAB} if($j == 2);
	} continue {
		$j++;
	}
} continue {
	$i++;
}
assert($cnt == 10);
=cut

# prepare_local with len in ValPy
sub try_local
{
	local @arr;

	@arr = ();
	assert(@arr == 0);	# scalar context
}
try_local();

# issue 39 - change f to f""" - not possible - skip

# CORE'xxx Carp'xxx UNIVERSAL'xxx
assert(&CORE'abs(-1) == 1);
assert(&UNIVERSAL::isa(\$i, 'SCALAR'));
assert(&UNIVERSAL'isa(\$i, 'SCALAR'));
if(0) {
	&Carp'cluck('Test Failed');
}

# tr with d flag and len(arg2) > len(arg1)
$str = 'abcdef';
$tr = $str =~ tr/abc/defg/dr;
assert($tr eq 'defdef');

# tr with s flag preceded by ~ token
$str = 'ddeeff';
$str =~ tr/def/g/s;
assert($str eq 'g');

# ref @INC
assert(ref \@INC eq 'ARRAY');

# @::var, %::var
@main = ('main');
assert(@::main == 1 && $::main[0] eq 'main');
%main = (main=>'main');
assert(%::main == 1 && $::main{main} eq 'main');

# delete=>
%delete = (delete=>'delete');
assert($delete{delete} eq 'delete');

# \ in bracketed f string with SPECIAL_ESCAPES, and same at end of string
$blank='';
assert("\U${blank}upper\Qquo'ted\E\E" eq 'UPPERQUO\\\'TED');

# \ not bracketed
assert("\U\-" eq '-');
assert("\-" eq '-');

# issue 47, is_escaped
assert("\$ \@" eq '$ @');
assert('@$?' =~ /^\@\$/);

# @{ [...] } in string
%ha = (key1 => 'val1', key2 => 'val2');
assert(($s="@{[%ha]}") eq 'key1 val1 key2 val2' || $s eq 'key2 val2 key1 val1');
assert(($t="@{ [%ha] }") eq 'key1 val1 key2 val2' || $t eq 'key2 val2 key1 val1');

# use lib qw/.../
use lib qw/. ../;
# @ARGV, @INC in string
@ARGV=('arg1', 'arg2');
assert("@ARGV" eq 'arg1 arg2');
assert("@INC" =~ /^\. \.\./);

# import name, then reference fully qualified version
use charnames qw/viacode/;
$charname = '0';
$charname = charnames::viacode($charname);
assert($charname eq 'NULL');

# a-a range in tr
$str = 'abc';
$str =~ tr/a-a/z/;
assert($str eq 'zbc');

# @arr = <>
close(STDIN);
@ARGV=("$0");
@lines = <>;
assert(@lines > 100);
assert(grep {/viacode/} @lines);

# $-( or $+( as token 0,1???
#$str = 'abc';
#$str =~ /abc/;
#$+[0] += 0;
#assert($+[0] == 0);
#$-[0] -= 0;
#assert($-[0] == 3);

# use overload
use test_overload qw/new/;
$to1 = new test_overload(3);
$to2 = new test_overload(4);
$to3 = $to1 + $to2;	# + does a * in this test
assert($to3 == 12);

# special var full
assert(!${^TAINT});

# $#INC, $#ARGV
assert($#INC == (@INC - 1));
assert($#ARGV == (@ARGV - 1));

# main'var
assert($main'str eq $str);

# $INC
assert($INC[0] eq '.' && $INC[1] eq '..');

# ~ match within a string (lol not sure what this is)

# Pythonizer coverage issues:

# use subs qw/.../

use subs qw/cos sin/;

sub cos { -shift }
sub sin { 1/shift }

assert(cos(-1) == 1);
assert(sin(0.5) == 2);

# SpecialHashType

assert(!defined $ENV{non_existant});

# goto to skip code
goto ContinueHere;
sub not_even_compiled {
	assert(0);
}
not_even_compiled();
ContinueHere:

# pythonizer coverage issues:

# gen_author option
# (tested above)

$i = 0;
$k = $i += 1;
assert($i == 1 && $k == 1);

# own (we removed this - there is no "own")

# @a=@b=@_

sub hasargs
{
	@a=@b=@_;

	assert(scalar(@a) == scalar(@_));
	assert(scalar(@b) == scalar(@_));
	assert($a[0] == $_[0]);
	assert($b[0] == $_[0]);
	$b[0] = 42;
	assert($a[0] == $_[0]);
	assert($b[0] == 42);
}
hasargs(1,2,3);

# return outside of function
if(0) {
	return;
}

# goto \&localSub;

sub goesLocal
{
	goto \&localSub;
}

sub localSub {
	return (shift) + 1;
}

assert(goesLocal(2) == 3);

# goto &$subref;

my $subref = sub { 8 };

sub return8 { goto &$subref }

assert(return8() == 8);

# localsub(split / /, $line)

sub howMany
{
	return scalar(@_);
}

$line = "a b c";
assert(howMany(split / /, $line) == 3);

# Converter needed for += and friends

my $mixed = 0;
$mixed = '' if(0);

$mixed += 1;
assert($mixed == 1);
$mixed -= 1;
assert($mixed == 0);

# open as last stmt of sub

sub returnFH
{
	open($fh, '<', "$0");
}

my $status = returnFH();
assert($status);
$line = <$fh>;
assert(substr($line,0,1) eq '#');
close($fh);

sub returnFHH
{
    open(FH, '<', "$0");
    assert(defined FH);
    open(FILE, '<', "$0");
}
$status = returnFHH();
assert($status);
$line = <FILE>;
assert(substr($line,0,1) eq '#');
close($fh);

# printf with array where array[0] is the format
#
open(OUT, '>', 'tmp.tmp');

@arr = ('%d%d', 4, 5);
printf OUT @arr;
close(OUT);
open(OUT, '<', 'tmp.tmp');
chomp($line = <OUT>);
assert($line eq '45');
close(OUT);

# multi-assignment with array and hash refs

%hash = ();
($arr[0], $hash{key}) = (42, 'value');
assert($arr[0] == 42);
assert($hash{key} eq 'value');

# @hash{k1,k2}=...

@hash{qw/key1 key2/} = ('value1', 'value2');
assert($hash{key1} eq 'value1');
assert($hash{key2} eq 'value2');
assert($hash{key} eq 'value');

# tokens: s([si"])=() - issue 36

my $hashref = {};
$hash{key}=%$hashref;	# Makes this a hash of hashes
$hash{key}{k} = 'v';
assert($hash{key}{k} eq 'v');

# $arrref = []

$arrayref = [];
push @$arrayref, 1;
assert(scalar(@$arrayref) == 1);
assert($arrayref->[0] == 1);

# tr with r flag

$str = 'abcdef';
$str =~ tr/abc/z/r;
assert($str eq 'abcdef');
$new = $str =~ tr/abc/z/r;
assert($str eq 'abcdef');
assert($new eq 'zzzdef');

# tr that can't use = with flags

assert(($str =~ tr/abc/def/s) == 3);
assert($str eq 'defdef');

# tr with count that can't use =

assert($str =~ tr/def/ghi/r eq 'ghighi');

# tr Case 4 with r flag

my $old = 'abc';
(my $new = $old) =~ tr/abc/def/r;
assert($old eq 'abc');
assert($new eq 'abc');

# tr Case 4 that can't use = with no r flag

assert((($new = $old) =~ tr/abc/def/) == 3);
assert($old eq 'abc');
assert($new eq 'def');

# tr Case 5
my $st = 'abc';
($global = $st) =~ tr/abc/def/;
assert($global eq 'def');
assert($st eq 'abc');

# re that uses find
assert($st =~ 'a');

# re Case 2, no =
my ($var, $cnt);
$var = 'ab';
assert(($cnt = $var =~ s/a/b/) == 1);

# re Case 4 with r flag
$old = 'abc';
($new = $old) =~ s/a/b/r;
assert($old eq 'abc');
assert($new eq 'abc');

# re Case 5 with r flag

($global = $old) =~ s/a/b/r;
assert($old eq 'abc');
assert($global eq 'abc');

($global = $old) =~ s/a/b/;
assert($old eq 'abc');
assert($global eq 'bbc');

# complex expr in if starting with undef

if((undef, $var) = (2, 3)) {
	;
} else {
	assert(0);
}
assert($var == 3);

# if(<$fh>)

open($fh, '<', "$0");
if(<$fh>) {
	$cnt++;
} else {
	assert(0);
}

# if(/pat1/ .. /pat2/)
## FIRST COMMENT
## NEXT COMMENT
## LAST COMMENT

$cnt = 0;
while(<$fh>) {
	if(/^## FIRST COMMENT/ .. /^## LAST COMMENT/) {
		$cnt++;
	} elsif($cnt) {
		last;
	}
}
assert($cnt == 3);

# while($line = <$fh>) {...}

$cnt = 0;
while($line = <$fh>) {
	chomp($line);
	$cnt++;
}
assert($cnt > 20);
close($fh);

# localSub($_) foreach(@arr)

$total = 0;
sub process_element
{
	$total += shift;
}

@arr = (5,6,7);
process_element($_) foreach (@arr);
assert($total == (5+6+7));

# substr with neg arg2, constant arg1

$str = 'abcdef';
assert(substr($str, 2, -2) eq 'cd');

# substr with neg arg2

my $two = 2;
assert(substr($str, $two, -2) eq 'cd');

# substr with constant arg1, variable arg2

my $three = 3;
assert(substr($str, 1, $three) eq 'bcd');

# index with two commas

$str = 'abcabc';
assert(index($str,'a',0) == 0);
assert(index($str,'a',1) == 3);
assert(index($str,'a',4) == -1);

# return {}, [], ()

sub hashref { {} };
my $hr = hashref();
assert(scalar(%$hr) == 0);
$hr->{key} = 'value';
assert(scalar(%$hr) == 1);
assert($hr->{key} eq 'value');

sub arrayref { [] };
my $ar = arrayref();
assert(scalar(@$ar) == 0);
push @$ar, 1;
assert(scalar(@$ar) == 1);
assert($ar->[0] == 1);

sub array { () };
my @ar = array();
assert(scalar(@ar) == 0);
push @ar, 1;
assert(scalar(@ar) == 1);
assert($ar[0] == 1);

# (ref $self)->method

# wantarray

sub wa
{
	wantarray ? () : 0;
}

@arr = wa;
assert(scalar(@arr) == 0);
$v = wa;
assert($v == 0);

@arr = wa();
assert(scalar(@arr) == 0);
$v = wa();
assert($v == 0);

assert(wa() == 0);

# return expr in eval

my $result = eval {
	$i = 0;
	$i or return 42;
};

assert($result == 42);

# call a class method
# We did this above

# ++$arr[ndx]; $arr[ndx]--

@arr = (1,2);
++$arr[0];
assert($arr[0] == 2);
$arr[1]--;
assert($arr[1] == 1);

# read w/o parens

open($fh, '<', "$0");
my $scalar = '';
read $fh, $scalar, 1, 0;
assert($scalar eq '#');
close($fh);

# $obj->var
$obj = new test_overload(4);
assert($obj->stringify);

# substitute_global

$global = 'abc';
$global =~ s/a/b/;
assert($global eq 'bbc');

# IOFile_open or fdopen not at token 0

use IO::File;

$fh = IO::File->new();
if($fh->open("< $0")) {
	$line = <$fh>;
	assert(substr($line,0,1) eq '#');
	$fh->close;
} else {
	assert(0);
}

# tr w/o ~ with r flag

$_ = 'abcdef';
assert(tr/abc/def/r);
assert($_ eq 'abcdef');

# math.exp(large#) == math.inf

assert(exp(1000) > 1E100);

# bless w/o , (tested in test_overload.pm)

# open arg2 ends with '&' (dup)

# open arg2 is scalar

$read = '<';
open($fh, $read, $0);
chomp($line = <$fh>);
assert($line =~ /^#/);
close($fh);

# open mode is <- or ->

# open mode contains :

open($fh, '<:utf8', $0);
chomp($line = <$fh>);
assert($line =~ /^#/);
close($fh);

# open in if w/o target
if(open $fh, $0) {
	chomp($line = <$fh>);
	assert($line =~ /^#/);
	close($fh);
} else {
	assert(0);
}

$ARTICLE=$0;
if(open(ARTICLE)) {
	chomp($line = <ARTICLE>);
	assert($line =~ /^#/);
	close(ARTICLE)
} else {
	assert(0);
}

# opendir in if
if(opendir DH, '.') {
	closedir DH;
} else {
	assert(0);
}

# split "str", ...
$line = 'abc';
@line = split 'b', $line;
assert(@line == 2);
assert($line[0] eq 'a');
assert($line[1] eq 'c');

# split with 3rd arg in scalar context

$scalar = split 'b', $line, 2;
assert($scalar == 2);

# stat of $_ with :=

$_ = '.';
if(@arr = stat) {
	assert(@arr == 13);
	assert(-d _);
} else {
	assert(0);
}

# select w/o args

assert(select == STDOUT);

# select not token 0 and args

assert(select(STDOUT) == STDOUT);

# undef followed by ? : or )

my $a = 1 == 0 ? undef : 4;
assert($a == 4);
$a = (1 == 1 ? 5 : undef);
assert($a == 5);

# chomp or chop with no args

$_ = "a\n";
chomp;
assert($_ eq 'a');

# reverse hash in scalar context

%hash = (k1=>'v1', k2=>'v2');
$scalar = reverse %hash;
assert($scalar eq '2v2k1v1k' or $scalar eq '1v1k2v2k');

# binmode not token 0

open $fh, '<', $0;
if(binmode $fh, ':utf8') {
	chomp($line = <$fh>);
	assert($line =~ /^#/);
	close($fh);
} else {
	assert(0);
}

# return {k=>v, ...}

sub hashRet{ {k=>'v', j=>'u'} }

$hr = hashRet();
assert($hr->{k} eq 'v' && $hr->{j} eq 'u');

# s57: 'HASH' eq ref ...

assert('HASH' eq ref $hr);

# use autoflush w/o perllib

$| = 1;

# multiple assignment with the last being an increment

my ($x, $y) = (0,0);
$x = $y+=1;
assert($x == 1);
assert($y == 1);

# my var = wantarray sub call w/o args
my @array = wa;
assert(scalar(@array) == 0);
my $variable = wa;
assert($variable == 0);

# multiple state vars with all the same init
sub test_state {
	state ($s1, $s2, $s3);

	my ($arg1, $arg2, $arg3) = @_;

	$s1 += $arg1;
	$s2 += $arg2;
	$s3 += $arg3;

	return $s1*10+$s2*5+$s3;
}

assert(test_state(1,2,3) == 23);
assert(test_state(1,2,3) == 46);

use constant three=>3;

# Constant, localsub, and string hash values
my %hi = ('key0', 0, 'key1', three, 'key2', two);
assert($hi{key0} == 0);
assert($hi{key1} == 3);
assert($hi{key2} == 'two');

# hash assignment w/o autoviv

%hc = %hi;
assert(scalar(%hc) == scalar(%hi));
$hc{key3} = 'v3';
assert($hc{key3} eq 'v3');
assert(!exists $hi{key3});

# sort a hash sorts the keys and the values
@arr = sort %hi;

# arr = hash

@arr = %hi;
assert(scalar(@arr) == scalar(%hi)*2);
for my $k (keys %hi) {
	$found = 0;
	for(my $i = 0; $i < @arr; $i++) {
		if($arr[$i] eq $k) {
			$found++;
			assert(($i % 2) == 0);
		}
	}
	assert($found == 1);
}
for my $v (values %hi) {
	$found = 0;
	for(my $i = 0; $i < @arr; $i++) {
		if($arr[$i] eq $v) {
			$found++;
			assert(($i % 2) == 1);
		}
	}
	assert($found == 1);
}

# (expr) or (expr)=value

@arr = (1,2);
($x1, $x2) = @arr;
assert($x1 == 1 && $x2 == 2);
($x1 > $x2) || ($x1 = 4);
assert($x1 == 4);

# Eval w/o any reference to $@

eval {
	$x1 = $x1 / ($x1 - $x1);	# generates an expected exception
};
assert($x1 == 4);

print "$0 - test passed!\n";

END {
	eval { close(OUT) };
	eval { unlink "tmp.tmp" };
}
