# Issues found while bootstrapping
use Carp::Assert;
use feature 'state';
# pragma pythonizer -M, no pl_to_py, no replace usage

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

# issue escapes in single quoted strings were not escaped in the output
# Perl: A backslash represents a backslash unless followed by the delimiter or another backslash, in which case the delimiter or backslash is interpolated.

assert(q(\x91) eq ('\\' . 'x91'));
assert('\x91' eq ('\\' . 'x91'));
assert('\\x91' eq ('\\' . 'x91'));
assert('\091' eq ('\\' . '091'));
assert('\71' eq ('\\' . '71'));
assert('\91' eq ('\\' . '91'));
assert('\u91' eq ('\\' . 'u91'));
assert('\U91' eq ('\\' . 'U91'));
assert('\N{91}' eq ('\\' . 'N{91}'));
assert('\n91' eq ('\\' . 'n91'));
assert('\\n91' eq ('\\' . 'n91'));
assert('\t91' eq ('\\' . 't91'));
assert('\z91' eq ('\\' . 'z91'));
assert('\{91' eq ('\\' . '{91'));
assert('\\91' eq ('\\' . '91'));
assert('\'91' eq ("'" . '91'));
assert('\"91' eq ('\\' . '"91'));
assert(q(\'91) eq ('\\' . "'" . '91'));
assert(q(\)91) eq ')91');
assert(q(\(91) eq '(91');
assert(q/\/91/ eq '/91');
assert('\
91' eq ('\\' . "\n" . '91'));

# issue s/// rhs with single quotes was being interpolated

my $regex = '[:punct:]';
$regex =~ s'\[:punct:\]'!"\#%&\'()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$'g;
#print "$regex\n";
assert($regex eq '!"\#%&\'()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$');

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

# issue: For the RHS of an re.sub(), escape any non-allowed escape sequence such as \xNN with an extra '\'
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

# issue - unbounded local variable

sub split_up_multiple_assignment
{
	my $test_only = $_[0] if(scalar(@_) > 0);
	return 1 if($test_only);

	0;
}

assert(split_up_multiple_assignment() == 0);
assert(split_up_multiple_assignment(1) == 1);

# issue - return insertion on unshift expression - should return the # of elements in the array
# Note: Push returns the # of elements too

sub unquote_string
{
	return $_[0];
}

sub douselib
{
	@libs = ('lib1', 'lib2');
	unshift @UseLib, map {unquote_string($_)}  @libs;
}

assert(douselib() == 2);
assert(@UseLib == 2 && $UseLib[0] eq 'lib1' && $UseLib[1] eq 'lib2');

sub douselibp
{
	@libs = ('lib1', 'lib2');
	push @UseLibp, map {unquote_string($_)}  @libs;
}

#assert(douselibp() == 2);
douselibp();
assert(@UseLibp == 2 && $UseLibp[0] eq 'lib1' && $UseLibp[1] eq 'lib2');

# issue - using wrong names for conflicting vars with complex reference pattern

use lib '.';
use Pack;

$Packages[0] = 'package';
my $cp = get_cur_package();
assert($cp eq 'package');

assert(%Packages == 1);
assert(@Packages == 1);
assert(%Pack::Packages == 1);
assert(@Pack::Packages == 1);
assert("@Pack::Packages" eq 'package');

# issue returning an anonymous hashref generated bad code

sub rethref
{
	return {};
}
my $n = rethref();
assert(scalar(%$n) == 0);

# issue - escaped square (or curly) brackets should not generate '\' in output code:

sub gen_chunk
{
	$arg = shift;
	return $arg;
}
$start = 0;
$ValPy[$start] = 'a';
$arg1=3;
$arg2=7;
assert(gen_chunk("$ValPy[$start]\[$arg1:$arg2\]") eq 'a[3:7]');
assert(gen_chunk("$ValPy[$start]\{$arg1:$arg2\}") eq 'a{3:7}');
# Try some other escapes
assert(gen_chunk("$ValPy[$start]\[$arg1:$arg2\]\"\\\q\n") eq "a[3:7]\"\\q\n");

# issue - interpolation of array of hash into string failed
%h = (k1=>'v1', k2=>'v2');
push @stk, \%h;
$str = "@stk";
assert($str =~ /HASH/ || ($str =~ /k1/ && $str =~ /v2/));

# issue - wrong context for regex match

sub could_be_anonymous_sub_close { 0 }

$source = '};';
$cnt = 0;
$tno=1;
if(0) {
	;
}elsif($tno>0 && (length($source)==1 || $source =~ /^}\s*$/ ||
       $source =~ /^}\s*#/ || 
       could_be_anonymous_sub_close() ||       
       $source =~ /^}\s*(?:(?:(?:else|elsif|while|until|continue|)\b)|;)/)){
	$cnt++;
}
assert($cnt == 1);

# issue - wrong code for regex match with regex in variable

sub unescaped_match
# Given a string and a regex to match, return the position of the next unescaped match
{
    my $string = shift;
    my $pat = shift;

    for(my $i = 0; $i < length($string); $i++) {
        my $ch = substr($string,$i,1);
        if($ch eq "\\") {       # Skipped escaped chars
            $i++;
            next;
        }
        return $i if($ch =~ $pat);
    }
    return -1;
}

$quote = 'a$abc';
$pos = unescaped_match($quote, qr'[$@]');
assert($pos == 1);

# issue - open of SYSIN instead opens STDIN

# issue stdin open (STDIN, '<',$fname) || die("Can't open $fname for reading");
$fname = $0;
open (SYSIN, '<',$fname) || die("Can't open $fname for reading");     # issue stdin
my $line = <SYSIN>;
assert($line =~ /^#/);
close(SYSIN);

# issue - references to our variables from other packages weren't being remapped properly
use RefsMain qw/set_main/;

$main_var_set = 0;

assert($main_var_set == 0);
set_main(1);
assert($main_var_set == 1);
assert($in == 42);	# set by the sub

# issue - longest common prefix didn't work

sub lcp {               # Longest common prefix - LOL don't ask me how it works!
    return (join("\0", @_) =~ /^ ([^\0]*) [^\0]* (?:\0 \1 [^\0]*)* $/sx)[0];
}

assert(length(lcp('S', 'm')) == 0);
assert(lcp('a', 'a') eq 'a');
assert(lcp('a of S', 'a') eq 'a');
assert(lcp('a', 'a of S') eq 'a');
assert(lcp('a of m', 'a of S') eq 'a of ');

# issue - hash key not getting converted from int

@nesting_stack = ();
push @nesting_stack, {lno=>29};

%line_locals = (29=>['*local,$@%'], 32=>['$myLocal']);

sub push_locals
{
	my $top = $nesting_stack[-1];
	my $lno = $top->{lno};
	my $cnt=0;
	for my $local (@{$line_locals{$lno}}) {
		$cnt++;
	}
	assert($cnt == 1);
	my @locals = @line_locals{29, 32};
	assert(scalar(@locals) == 2 && ($locals[1]->[0] eq '$myLocal'));
	my @lines = (29,32);
	my @locals2 = @line_locals{@lines};
	assert(scalar(@locals2) == 2 && ($locals2[1]->[0] eq '$myLocal'));
	my @lines2 = @lines[0,1];
	assert(scalar(@lines2) == 2 && join(',', @lines2) eq '29,32');
	my @ndx = ('0', '1');
	my @lines3 = @lines[@ndx];
	assert(scalar(@lines3) == 2 && join(',', @lines3) eq '29,32');
	my %h = (0=>1, 1=>1);
	my @lines4 = @lines[keys %h];
	assert(scalar(@lines4) == 2 && (join(',', @lines4) eq '29,32' || join(',', @lines4) eq '32,29'));
}

push_locals();

sub gen_try_block_finally
{
	my $top = $nesting_stack[-1];
	my $lno = $top->{lno};
	my $cnt=0;
	for my $local (reverse @{$line_locals{$lno}}) {
		$cnt++;
	}
	assert($cnt == 1);
}

gen_try_block_finally();

# issue - delete with 2 keys instead deletes the first one!

$NeedsInitializing{sub}{var1} = 'I';
$NeedsInitializing{sub}{var2} = 'I';
my $subname = 'sub';
my $varname = 'var1';
delete $NeedsInitializing{$subname}{$varname};
assert($NeedsInitializing{sub}{var2} eq 'I');

# issue - left hand substring from -1 for 1 char gives wrong result

$val = '0.';
substr($val, -1, 1) = '';
assert($val eq '0');

# issue - slice with range stopped generating proper code


@ValClass = (1,2,3,4,5,6,7,8,9);
$start = 3;
$k = 5;
@DeferredValClass=@ValClass[$start..$k];
assert(join('', @DeferredValClass) eq '456');

# issue - excess escapes in substitution rhs need to be removed

$quote = '$hash{key}';
{
     no warnings 'uninitialized';
     $quote =~ s/(?<![{\$])(->)?\{([A-Za-z_][A-Za-z0-9_]*)\}/$1\{\'$2\'\}/g;     # issue 13: Remove bare words in $hash{...}
}
assert($quote eq q/$hash{'key'}/);

# issue - global var not being converted to num

use Pscan qw/set_breakpoint_lno/;
$breakpoint = 9999;
set_breakpoint_lno('42');
assert($breakpoint == 42);

# issue - decode_scalar: substitution rhs was getting extra \ added before {

$source = q/$SIG{'ALRM'}/;
$source =~ s/\{['"](\w+)['"]\}/{$1}/;        # Change $SIG{'ALRM'} to $SIG{ALRM}
assert($source eq '$SIG{ALRM}');

# issue reference to "$var\[0]" wasn't generating the package name or the _v suffix

$DEFAULT_MATCH='_m';
$split=-1;
$ValPy[$split+1] = "($DEFAULT_MATCH:=re.search";
$ValPy[$split+1] =~ s/\($DEFAULT_MATCH:=re\.search/[$DEFAULT_MATCH\[0] for $DEFAULT_MATCH in (re.finditer/;
assert($ValPy[$split+1] eq '[_m[0] for _m in (re.finditer');

# issue - removing one element from array in another package was generating bad code

if($Pscan::PythonCode[-1] eq '*') {
    $#Pscan::PythonCode--;
}
assert(scalar(@Pscan::PythonCode) == 0);

# issue - tr was losing the s flag!

$name = undef;		# give it a mixed type
$name = 'Package::var';
$name=~tr/:/./s;
assert($name eq 'Package.var');

# issue - substitution in a sub arg generates bad code
$package_dir = "pd";
my $filepy = "file.py";

my $f = catfile($package_dir, $filepy =~ s'.py$'/__init__.py'r);
assert($f eq "pd/file/__init__.py" || $f eq "pd\\file/__init__.py");

$cnt = 0;
for my $fp2 (catfile($package_dir, $filepy), catfile($package_dir, $filepy =~ s'.py$'/__init__.py'r)) {
	if($fp2 eq "pd/file.py" || $fp2 eq "pd\\file.py") { $cnt++ }
	if($fp2 eq "pd/file/__init__.py" || $fp2 eq "pd\\file/__init__.py") { $cnt++ }
}
assert($cnt == 2);

# issue loop control raising wrong exception in labeled loop

$cnt = 0;
OUTER:
    for(my $ndx = 0; $ndx < 4; $ndx++) {
	    next if($ndx == 2);
	    $ndx++ if(0);
	    $cnt++;
    }

assert($cnt == 3);

# issue (w/s3) elsif w/exists failing translation

$name = 'name';
%LocalSub = ();
%VarType = (name=>{__main__=>'S'});
$cnt = 0;
if(0) {
	;
} elsif($LocalSub{$name} || (exists $VarType{$name} && exists $VarType{$name}{__main__})) {
	$cnt++;
}
assert($cnt == 1);

# issue - creating a hashref doesn't make it a Hash type with autovivification

$IntactLno = 1;
$IntactLine = 'line1';
@args=('arg1', 'arg2');
@output_buffer = ();
my $push_record = {lno=>$., ilno=>$IntactLno, iline=>$IntactLine, args=>\@args};
push @output_buffer, $push_record;
$IntactLine = 'line2';
$output_buffer[-1]->{line} .= "\n" . $IntactLine;	# this code was actually a mistake!
assert($output_buffer[0]->{iline} eq 'line1');
assert($output_buffer[0]->{line} eq "\nline2");

# issue - exists fails with exception if base value is not there because it was copied from a non-existing
# element

%Subattributes = ();
$cur_pos = 0;
$ValPy[$cur_pos] = 'mySub';
#
# We didn't implement this change because it causes other issues: 
####### $SubAttributes{mySub} = $SubAttributes{nonExist};	# causes it to be "None"
# Here is the code for ArrayHash if we ever revisit it:
#
#     def get(self, key, default=None):
#        if key in self:
#            return self[key]
#        if default is None:
#            return ArrayHash()
#        return default
#
# It was causing these tests to fail: issue_53, issue_s3, test_autovivification, test_complex,
# test_defined.  Basically any code that checks "defined" on the result of a hash fetch that
# doesn't exist fails with this update.  Instead we changed the source code in Perlscan.pm only to
# copy the value if it exists.

$cnt = 0;
if(exists $SubAttributes{$ValPy[$cur_pos]}{wantarray}) {
	assert(0);
} else {
	$cnt++;
}
assert($cnt == 1);
$SubAttributes{mySub}{wantarray} = 1;
if(exists $SubAttributes{$ValPy[$cur_pos]}{wantarray}) {
	$cnt++;
} else {
	assert(0);
}
assert($cnt == 2);

# issue - checking if array element is defined generates '.get(index)' which returns None if the index
# is negative.

@ValCom = ('', '# Comment');
$c = '';
if( defined $ValCom[-1]  && length($ValCom[-1]) > 1  ){
	$c = $ValCom[-1];
}
assert($c eq '# Comment');

$c = '';
if( defined $ValCom[1]  && length($ValCom[1]) > 1  ){
	$c = $ValCom[1];
}
assert($c eq '# Comment');

$c = '';
$m1 = -1;
if( defined $ValCom[$m1]  && length($ValCom[$m1]) > 1  ){
	$c = $ValCom[$m1];
}
assert($c eq '# Comment');

$c = '';
$p1 = 1;
if( defined $ValCom[$p1]  && length($ValCom[$p1]) > 1  ){
	$c = $ValCom[$p1];
}
assert($c eq '# Comment');

$ValCom[-1] = undef;

$c = '';
if( defined $ValCom[-1]  && length($ValCom[-1]) > 1  ){
	$c = $ValCom[-1];
}
assert($c eq '');

$c = '';
if( defined $ValCom[1]  && length($ValCom[1]) > 1  ){
	$c = $ValCom[1];
}
assert($c eq '');

$c = '';
$m1 = -1;
if( defined $ValCom[$m1]  && length($ValCom[$m1]) > 1  ){
	$c = $ValCom[$m1];
}
assert($c eq '');

$c = '';
$p1 = 1;
if( defined $ValCom[$p1]  && length($ValCom[$p1]) > 1  ){
	$c = $ValCom[$p1];
}
assert($c eq '');

$#ValCom = 0;		# delete the last element

$c = '';
if( defined $ValCom[-1]  && length($ValCom[-1]) > 1  ){
	$c = $ValCom[-1];
}
assert($c eq '');

$c = '';
if( defined $ValCom[1]  && length($ValCom[1]) > 1  ){
	$c = $ValCom[1];
}
assert($c eq '');

$c = '';
$m1 = -1;
if( defined $ValCom[$m1]  && length($ValCom[$m1]) > 1  ){
	$c = $ValCom[$m1];
}
assert($c eq '');

$c = '';
$p1 = 1;
if( defined $ValCom[$p1]  && length($ValCom[$p1]) > 1  ){
	$c = $ValCom[$p1];
}
assert($c eq '');

# issue do until causes "Use of uninitialized values in concatentation in Perlscan line 2527

use constant {l_mode => 1, u_mode=>2, L_mode=>4, U_mode=>8, F_mode=>16, Q_mode=>32};
my $result = '';
my @special_escape_stack = ("0,4,f1", "0,1,f2");

  do {          # only \L \U \F and \Q have corresponding \E, if anything else, keep popping
      my $stacked = pop @special_escape_stack;
      ($special_escape_mode, $new_semode, $func) = split /,/, $stacked;
      $result.=$func;
  } until($new_semode & (L_mode|U_mode|F_mode|Q_mode));
assert(@special_escape_stack == 0);
assert($result eq 'f2f1');

# issue - string with both ' and " generates bad code

$cnt = 0;
$i = 0;
$ValPy[$i] = "'t'";
if(index(q('"), substr($ValPy[$i],0,1)) >= 0) {
    $cnt++;
}
$ValPy[$i] = '"t"';
if(index(q('"), substr($ValPy[$i],0,1)) >= 0) {
    $cnt++;
}
assert($cnt == 2);


# issue: "'''" is NOT the start of a multi-line string (in move_defs_before_refs)

sub escape_triple_singlequotes          # SNOOPYJC
# We are making a '''...''' string, make sure we escape any ''' in it (rare but possible)!
{
    my $string = shift;

    my $local_var = $global_var;

    $string =~ s/'''/''\\'/g;
    return $string;
}

# issue - =pod code is causing unterminated string in the output

assert(escape_triple_singlequotes("'''") eq "''\\'");sub sub_before_pod { 1 }

=pod    # issue s48
sub arg_type_from_pos                           # SNOOPYJC
# If this token is a function arg, return what arg type it is, else return 'u'
{
    my $k = shift;

    my ($i, $arg);

    for($i = $k; $i >= 0; $i--) {
        if($ValClass[$i] eq '(') {
           if($i-1 >= 0 && $ValClass[$i-1] eq 'f') {
              $i--;
              last;
           }
           return 'u';
        } elsif($ValClass[$i] eq 'f' && $i != $k) {
            last;
        } elsif($ValClass[$i] eq ')') {
            $i = reverse_matching_br($i);
            return 'u' if($i < 0);
        # issue s48 } elsif($ValClass[$i] eq '=' && $ValPy[$i] ne ':=') {
        # issue s48 return 'u';
        }
    }
    return 'u' if($i < 0 || $ValClass[$i] ne 'f');
    my $fname = $ValPerl[$i];
    my $pname = $ValPy[$i];
    if($ValClass[$i+1] eq '(') {
        my $q = matching_br($i+1);
        return 'u' if($k > $q);               # not in the parens like f(...)..k..
        $i++;
    }
    # Figure out which arg of the function this is: note some functions the first arg
    # is not separated from the second arg with spaces
    if($k == $i+1) {
        $arg = 0;           # That was easy
    } else {
        $arg = 1;
        my $j = $i+2;
        $j++ if($j <= $k && $ValClass[$j] eq ',');
        for( ; $j<=$k; $j++) {
            last if($k == $j);
            $arg++ if($ValClass[$j] eq ',');
            #$j = matching_br($j) if($ValClass[$j] eq '(');
            $j = &::end_of_variable($j);
            return 'u' if($j < 0);
        }
    }
    my $ty = arg_type($fname, $pname, $arg);
    if($::debug > 3) {
        say STDERR "arg_type_from_pos($k): ($fname, $pname, $arg) = $ty";
    }
    return $ty;
}
=cut
sub sub_after_pod { 2 }

assert(sub_before_pod() == 1);
assert(sub_after_pod() == 2);

# issue - array with scalar(array) as subscript generates incorrect code

#@ValClass = (1,2,3,4,5,6,7,8,9);
sub append
{
   $ValClass[scalar(@ValClass)]=$_[0];
}

append('0');
assert(join('', @ValClass) eq '1234567890');

#
# NOTE: Insert new test cases before here!!
#

# issue - print of arglist was generating a tuple syntax in the output

sub print_args
{
	print @_;
}
print_args($0, ' - test', ' passed!', "\n");
