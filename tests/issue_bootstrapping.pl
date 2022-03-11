# Issues found while bootstrapping
use Carp::Assert;
use feature 'state';
# pragma pythonizer -M

# Anonymous hashrefs weren't being initialized properly (they were being turned into sets!)
our %PREDEFINED_PACKAGES = (
	'POSIX'=>      [{perl=>'tmpnam', type=>':a', scalar=>'_tmpnam_s', scalar_type=>':S'},
			{perl=>'tmpfile', type=>':H'},
		       ],
	       );
my @all_perl;
my @all_type;
for my $pkg (keys %PREDEFINED_PACKAGES) { 
	for my $func_info(@{$PREDEFINED_PACKAGES{$pkg}}) {
		my $perl = $func_info->{perl};
		push @all_perl, $perl;
		my $type = $func_info->{type};
		push @all_type, $type;
	}
}

assert(join(' ', @all_perl) eq 'tmpnam tmpfile');
assert(join(' ', @all_type) eq ':a :H');

# Reference to __main__ as hash key was being changed to __main__()


%initialized = (__main__=>{'sys.argv'=>'a of S',
                       'os.name'=>'S',
                       EVAL_ERROR=>'S',
                       'os.environ'=>'h of s'});       # {sub}{varname} = type

assert($initialized{__main__}{EVAL_ERROR} eq 'S');

# shift @ARGV didn't generate proper code

@ARGV=('-a', '-b');
assert(shift @ARGV eq '-a');
assert(shift @ARGV eq '-b');
assert(!shift @ARGV);

# More cases of issue 129 where state variable is not interpolated

sub test_129
{
	my $arg = shift;

	state $sv = 'abc';

	$sv .= 'd';

	assert($sv eq 'abcd');
	assert("$sv" eq 'abcd');
	assert('abcd' =~ /$sv/);
	assert(`echo $sv` eq "abcd\n");
	assert(qx(echo $sv) eq "abcd\n");

	my $a = 'abcde';
	$a =~ s/$sv//;
	assert($a eq 'e');
}

test_129();

# Pythonizer.pm: a $) in a regex isn't the os grouplist

$line = ' # this is a comment';

if(  $line =~ /^\s*(#.*$)/ ){
	assert($1 eq '# this is a comment');
}

# getline: use <> to get a single line
@ARGV = ('issue_bootstrapping.pl');

sub getline
{
	my $line = <>;
	return $line;
}

$line = getline();
assert($line =~ /Issues found/);
assert($. == 1);
$line = getline();
assert($line =~ /Assert/);
assert($. == 2);
$line = getline();
assert($line =~ /^use feature/);
assert($. == 3);

@ValClass = qw/( a ) ( h ) (/;
 $balance=0;
 for ($i=0;$i<@ValClass;$i++ ){
    if( $ValClass[$i] eq '(' ){
       $balance++;
    }elsif( $ValClass[$i] eq ')' ){
       $balance--;
    }
 }
assert($balance == 1);

$closing_delim = '{';
   if( $closing_delim=~tr/{[>// ){
      $closing_delim=~tr/{[(</}])>/;
   }
assert($closing_delim eq '}');

eval {
	# Was giving a whole bunch of warning messages from the importer:
	require Net::FTP;
};

# Test matching used in sub with another match in the middle messing up the match var
# First include a reference to @- or @+ but not in the sub in question
"abc" =~ /^a/;
assert($-[0] == 0);

sub test_regex_in_the_middle
{
	my $cnt = 0;
	my $test = "test variable";
	if($test =~ /(variable)/) {
		$cnt++;
		if($test =~ /^nope/) {	# regex in the middle was messing up $1
			$cnt++;
		}
		assert($1 eq 'variable');
	}
	assert($cnt == 1);
}
test_regex_in_the_middle();

# Functions used for bootstrap:
use File::Spec::Functions qw(file_name_is_absolute catfile);   # SNOOPYJC
use Data::Dumper;    # SNOOPYJC
use Text::Balanced qw{extract_bracketed};
use Storable qw(dclone);
use open IN => ':crlf', OUT => ':raw';
use open OUT => ':encoding(UTF-8)';
use open IO => ':crlf';
use open ':std', ':encoding(UTF-8)';
use open ':std', OUT => ':encoding(UTF-8)';
use open ':std', IN => ':encoding(UTF-8)';
use open ':std', IO => ':encoding(UTF-8)';
use open qw/:std :encoding(UTF-8)/;

assert(file_name_is_absolute('/tmp/file'));
assert(!file_name_is_absolute('file'));

my $cf = catfile('/tmp', 'file');
assert($cf eq '/tmp/file' || $cf eq "/tmp\\file");

$oldhash{k1}{k2}{k3}[3] = 42;
$newhashref = dclone(\%oldhash);
%newhash = %$newhashref;
assert($oldhash{k1}{k2}{k3}[3] == 42);
assert($newhash{k1}{k2}{k3}[3] == 42);
$oldhash{k1}{k2}{k3}[3] = 43;
assert($oldhash{k1}{k2}{k3}[3] == 43);
assert($newhash{k1}{k2}{k3}[3] == 42);

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;
my $d = Dumper(\%newhash);
assert($d eq "{'k1' => {'k2' => {'k3' => [undef,undef,undef,42]}}}" or
       $d eq "Hash({'k1': Hash({'k2': Hash({'k3': Array([None, None, None, 42])})})})");

# Use every kind of quotes in a string:

my $py = 'f"""Usage: myfile.pl"""';
my $fname = 'myfile.pl';
my $pyname = $fname =~ s/\.pl$/.py/r;
$py =~ s/^(f?(?:'''|"""|'|")Usage:) $fname/$1 $pyname/;
assert($py eq 'f"""Usage: myfile.py"""');

# exclusive or shares the same token as ++/--

$ch3 = '@';
$ch = chr(ord(uc $ch3) ^ 64);
assert($ch eq "\c@");

# use Config

use Config;
assert(length($Config{path_sep}) == 1);

# \c. characters

$str = '\\c@';
$str =~ s/\\c(.)/sprintf "\\x{%x}", (ord(uc $1) ^ 64)/eg;
assert($str eq '\\x{0}');

$str = '\\c@';
$str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\c(.)/sprintf "\\x{%x}", (ord(uc $1) ^ 64)/eg;
assert($str eq '\\x{0}');

$str = '\\\\c@';
$str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\c(.)/sprintf "\\x{%x}", (ord(uc $1) ^ 64)/eg;
assert($str eq '\\\\c@');

$str = '\\\\\\c@';
$str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\c(.)/sprintf "\\x{%x}", (ord(uc $1) ^ 64)/eg;
#print $str . "\n";
assert($str eq '\\\\\\x{0}');

# pushing hashref to an array
$nesting_info{lno} = 1;
$nesting_info{is_eval} = 0;
push @nesting_stack, \%nesting_info;
$top = $nesting_stack[-1];
assert($top->{lno} == 1 && $top->{is_eval} == 0);

# Substr at end of string
$source = 'abc';
$cut=3;
$next_c = substr($source,$cut,1);
assert($next_c eq '');
$cut=2;
$next_c = substr($source,$cut,1);
assert($next_c eq 'c');

# use charnames

use charnames qw/:full :short/;

$charname = '0';
$charname = charnames::viacode($charname);
assert($charname eq 'NULL');

$charname = ord('a');
$charname = charnames::viacode($charname);
assert($charname eq 'LATIN SMALL LETTER A');

$charname = "LATIN SMALL LETTER A";
$ch = charnames::string_vianame($charname);
assert($ch eq 'a');

# Extract bracketed:

$line = '{$key{key}}[13]';
$result = '';
$cnt = 0;
while($ind = extract_bracketed($line, '{}[]', '')) {
	$result .= $ind;
	$cnt++;
}
assert($cnt == 2);
assert($result eq '{$key{key}}[13]');
assert($line eq '');

my $myline = '{$key{key}}[13]';
$result = '';
$cnt = 0;
while($ind = extract_bracketed($myline, '{}[]', '')) {
	$result .= $ind;
	$cnt++;
}
assert($cnt == 2);
assert($result eq '{$key{key}}[13]');
assert($myline eq '');

$newarr{key}[0] = '{$key{key}}[13]';
$result = '';
$cnt = 0;
while($ind = extract_bracketed($newarr{key}[0], '{}[]', '')) {
	$result .= $ind;
	$cnt++;
}
assert($cnt == 2);
assert($result eq '{$key{key}}[13]');
assert($newarr{key}[0] eq '');

# RuntimeError: dictionary keys changed during iteration

my $varclasses_at_top = {n1=>'my'};
my $varclasses_at_bottom = {n1=>'local', n2=>'global'};

for my $name (keys %{$varclasses_at_bottom}) {
    my $class = $varclasses_at_bottom->{$name};
    if($class ne 'global') {
        delete $varclasses_at_bottom->{$name};
        $varclasses_at_bottom->{$name} = $varclasses_at_top->{$name} if(exists $varclasses_at_top->{$name});
    }
}

# issue undefined package var - conditionally initialized

sub get_globals
{
	if(0) {
		;
	} elsif(0) {
		$we_are_in_sub_body = 1;
	}

	$cnt = 0;
	if(0) { 
		;
	} elsif($we_are_in_sub_body) {
		$we_are_in_sub_body = 0;
		assert(0);
	} else {
		$cnt++;
	}
	assert($cnt == 1);
}
get_globals();

# issue get from env - non-existant key

$cnt = 0;
if($hashy{key}) {
	assert(0);
} else {
	$cnt++;
}
assert($cnt == 1);

if($ENV{'PERL5LIB'}) {
	assert(0);
} else {
	$cnt++;
}
assert($cnt == 2);

check_perl5lib($ENV{'PERL5LIB'});

sub check_perl5lib
{
	$arg = shift;

	assert(!$arg);
}


# Assign to hash as array was generating bad code

my @signals = qw/ABRT ALRM BREAK BUS CHLD CLD CONT FPE HUP ILL INT KILL PIPE SEGV TERM USR1 USR2 WINCH _DFL _IGN/;
my @fhs = qw/STDERR STDIN STDOUT/;
my %sigs = map { $_ => "signal.SIG$_" } @signals;
my %f_hs = map { $_ => "sys.".lc $_ } @fhs;
our %CONSTANT_MAP = (%sigs, %f_hs);


%Constants=();
@Constants{values %CONSTANT_MAP} = values %CONSTANT_MAP;       # SNOOPYJC

assert($Constants{'sys.stderr'} eq 'sys.stderr');
assert($Constants{'signal.SIGABRT'} eq 'signal.SIGABRT');

@signals[0, 2, 4] = ('a', 'b', 'c');
assert($signals[0] eq 'a' && $signals[1] eq 'ALRM' && 
       $signals[2] eq 'b' && $signals[3] eq 'BUS' && $signals[4] eq 'c' && $signals[5] eq 'CLD');

my $prefix = '    ';
my $zone_size = 33 / 2;
my $start_of_comment_zone=$zone_size+length($prefix);
my $len = 10;
$filler = ' ' x ($start_of_comment_zone-$len);
assert(length($filler) == 10);

sub ts	# toposort in Pythonizer.pm
{
	my @out = (1,2,3);
	wantarray ? @out : \@out;
}

my @out = ts();
assert(@out == 3 && $out[0] == 1);

# sub return bracket issue

my %d = (k=>'v');
sub subd { $d{k} }
my $subref = sub { $d{k} };

assert(subd() eq 'v');
assert(&$subref() eq 'v');

# Tuple does not have a copy function
my $output_line = sub {
	my @args = @_;	# make a copy
	push @output_buffer, \@args;
};

&$output_line('a', 'b');
assert($output_buffer[0]->[1] eq 'b');

# toposort in Pythonizer.pm: Incorrect [...] were being generated on arrayref converted to an array in a for loop

$outref = \@out;

$result = '';
for my $node (@{$outref}) {
	$result .= $node;
}
assert($result eq '123');

# Posix regex patterns were not implemented
$cnt = 0;

$string = "\tabc\n";
my $escape_all = 1;
my %backslash_map = (10=>'\n', 13=>'\r', 9=>'\t', 12=>'\f', 7=>'\a', 11=>'\v');
if($string =~ /[^[:print:]]/) {
	my $new = '';
	for(my $i = 0; $i < length($string); $i++) {
	   my $ch = substr($string, $i, 1);
           if($ch !~ /[[:print:]]/ && ($escape_all || ($ch ne "\n" && $ch ne "\t"))) {    # enable newlines and tabs in multi-line strings to come thru but no other non-printable chars
               my $ord = ord $ch;
               if(exists $backslash_map{$ord}) {
                   $new .= $backslash_map{$ord};
               } else {
                   $new .= "\\x{" . sprintf('%x', ord $ch) . '}';
               }
           } else {
               $new .= $ch;
           }
       } 
       $string = $new;
}
assert($string eq '\tabc\n');

assert("ab0c" =~ /[[:alnum:]]+/);
assert("abc" =~ /[[:alpha:]]+/);
assert("abc\t\x14" =~ /[[:ascii:]]+/);
assert("\t " =~ /[[:blank:]]+/);
assert("934" =~ /[[:digit:]]+/);
assert("9\x21Z" =~ /[[:graph:]]+/);
assert("abc" =~ /[[:lower:]]+/);
assert(" a1C" =~ /[[:print:]]+/);
assert("!'([" =~ /[[:punct:]]+/);
assert("\t \n\r" =~ /[[:space:]]+/);
assert("ABC" =~ /[[:upper:]]+/);
assert("AB_0" =~ /[[:word:]]+/);
assert("AB0f" =~ /[[:xdigit:]]+/);
assert("AB0g" !~ /^[[:xdigit:]]+$/);

$string = 'ascii';

$string =~ s'ascii'\x00-\x7f'g;
# FIXME later!!  Is generating control chars by using the backslash sequence
#assert($string eq '\x00-\x7f');

# This one requires us to change from an r"..." string to a normal string, which we defer
#$string = 'ascii';
#$string =~ s/ascii/\x00-\x7f/g;
#assert($string eq "\x00-\x7f");
#
$str = '\\x{a}';
$str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\s*([A-Fa-f0-9])\s*\}/\\x0$1/g;
assert($str eq '\\x0a');

# Issue arrayref not being splatted into call

output_line(@$outref);

sub output_line
{
	my ($arg1, $arg2, $arg3) = @_;

	assert($arg1 == 1 && $arg2 == 2 && $arg3 == 3);
}

# Issue substr not giving the last char of the string

$line = "if a==2:";
$PREV_HAD_COLON = (substr($line, -1, 1) eq ':') ? 1 : 0;
assert($PREV_HAD_COLON);

assert(substr($line, -2, 2) eq '2:');
assert(substr($line, -2, 3) eq '2:');
assert(substr($line, -2, 1) eq '2');

$i = 1;
# If the start is negative, and start+length == 0, the code we generate doesn't work
# (and it's not easy to fix without making it a lot more complicated)
#$colon = substr($line, -$i, $i);
#assert($colon eq ':');
$two = substr($line, -$i-$i, $i);
assert($two eq '2');

$line = "abc";
$PREV_HAD_COLON = (substr($line, -1, 1) eq ':') ? 1 : 0;
assert(!$PREV_HAD_COLON);

sub check_colon
{
	$PREV_HAD_COLON = (substr($_[-1], -1, 1) eq ':') ? 1 : 0;
}
check_colon('', '10:');
assert($PREV_HAD_COLON);

# regex with unescaped '{...}' gives error in Python re

$cnt = 0;
$string = '{abc}';
if($string =~ /{...}/) {
	$cnt++;
}
assert($cnt == 1);

$cnt = 0;
$string = '{,}';
if($string =~ /{,}/) {
	$cnt++;
}
assert($cnt == 1);

$cnt = 0;
$string = '{,}';
if($string =~ /({,})/) {
	$cnt++;
}
assert($cnt == 1);

$cnt = 0;
$string = '{,}';
if($string =~ /(?:{,})/) {
	$cnt++;
}
assert($cnt == 1);

$cnt = 0;
$string = '{,}';
if($string =~ /a|{,}/) {
	$cnt++;
}
assert($cnt == 1);

$cnt = 0;
$string = '{1}';
if($string =~ /{1}/) {
	$cnt++;
}
assert($cnt == 1);

$cnt = 0;
$string = 'a';
if($string =~ /a{1}/) {	# This one should not get escaped
	$cnt++;
}
assert($cnt == 1);

# issue - assigning to $#list didn't escape the special name
@list = (1,2,3);
$#list = 1;
assert( $#list == 1);
assert(@list == 2);

# issue - variable reference in string with char class is not a subscript

@lines = ('class myFunc:');
$i = 0;
$func = 'myFunc';
$cnt = 0;
if($lines[$i] =~ /^class $func[(:]/) {
	$cnt++;
}
assert($cnt == 1);

# issue - "defined" didn't work on regex special vars

"abc" =~ /(def)/;	# doesn't match
assert(!defined $1);

"def" =~ /(def)/;
assert(defined $1);
assert(!defined $2);

# issue - push hashref onto an array generates wrong code

@eval_stack = ();
push @eval_stack,{eval_nest => 1, lno => 2};
assert($eval_stack[-1]->{eval_nest} == 1);
assert($eval_stack[-1]->{lno} == 2);
# Let's try an arrayref
@result = ();
push @result, [1, 2, 3];
assert(@result == 1);
assert($result[0]->[2] == 3);

# issue - @$arr[0] generated bad code

my $keys = ['key1', 'key2', 'key3'];	# Arrayref
my $key = @$keys[0];	# 0th element of arrayref turned into array
assert($key eq 'key1');


use lib '.';
use Pack;

$Packages[0] = 'package';
my $cp = get_cur_package();
assert($cp eq 'package');

assert(%Packages == 1);
assert(@Packages == 1);
assert(%Pack::Packages == 1);
assert(@Pack::Packages == 1);

print "$0 - test passed!\n";
