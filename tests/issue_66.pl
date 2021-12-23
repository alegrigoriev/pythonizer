# issue 66 - diamond operator with glob expression
use Carp::Assert;
sub THISFILE () {"issue_66.pl"}
$count = 0;
while (<*.pl>) {
	assert(/^issue/ or /^test/);
	$count++;
	last;
}
assert($count);

my $pat = '*.pl';
$count = 0;
while (<$pat >) {		# note the space makes it a glob not a readline
	assert(/^issue/ or /^test/);
	$count++;
	last;
}
assert($count);

$count = 0;
while (<${pat}>) {	# another glob
	assert(/^issue/ or /^test/);
	$count++;
	last;
}
assert($count);

$count = 0;
%options = (extra=>'.');
while (<$options{extra}/*.pl>) {	# another glob with a relative path
	assert(/issue/ or /test/);
	$count++;
	last;
}
assert($count);

$count = 0;
while (<*>) {	# another glob - thru all files
        next if not /\.pl$/;
	assert(/^issue/ or /^test/);
	$count++;
	last;
}
assert($count);

$i = 10;
$j = 20;
assert($i<11&&$j>19);		# Not a diamond operator!

assert(($i <=> $j) == -1);      # Not a diamond operator!

open(FD, THISFILE);
while(<FD>) {
    assert($_ =~ /issue 66/) if($. == 1);
    last;
}
close FD;
open($fd, '<', THISFILE);
while(<$fd>) {
    assert($_ =~ /issue 66/) if($. == 1);
    last;
}
close $fd;

open(FD, THISFILE);
undef $/;               # Enable slurp mode
my $file = <FD>;           # Read entire file into this string variable
$/="\n";                # Disable slurp mode
my @lines = split /\n/, $file;
assert(@lines > 50);
assert($lines[0] =~ /issue 66/);

@ARGV = (THISFILE);
# This is the emulation of what actually happens, from perldoc perlop
#$did_one = 0;
#unshift(@ARGV, '-') unless @ARGV;
#while ($ARGV_ = shift) {
#open(ARGV, $ARGV_);
#while (<ARGV>) {
#assert($_ =~ /issue 66/) if($. == 1);
#assert($ARGV_ =~ /issue_66.pl/);
#$did_one = 1;
#last;
#}
#}
#assert($did_one);
#@ARGV = (THISFILE);

$did_one = 0;
while(<>) {		# reads THISFILE, not STDIN
    if($. == 1) {
        assert($_ =~ /issue 66/) if($. == 1);
        assert($ARGV =~ /issue_66.pl/);
    }
    $did_one = 1;
    last;
}
assert($did_one);
@ARGV = (THISFILE);
$did_one = 0;
while(<<>>) {		# only can be a literal filename, not a pipe
    if($. == 1) {
        assert($_ =~ /issue 66/) if($. == 1);
        assert($ARGV =~ /issue_66.pl/);
    }
    $did_one = 1;
    last;
}
assert($did_one);
if($0 eq 'issue_66.py') {
    # We are running in python - check the code generation for the lines below this
    open(SOURCE, '<', 'issue_66.py');
    $found_start = 0;
    $with = 0;
    $while = 0;
    while(<SOURCE>) {
        $found_start = 1 if(substr($_,0,6) eq '######');
        if($found_start) {
            if(/^    with/) {
                $with++;
                assert(index($_, "fileinput.input('-') as _dia:") > 0);
            } elsif(/^        while/) {
                $while++;
                assert(index($_, "(_d:=next(_dia, None)):") > 0) if($while==1);
                assert(index($_, "(line:=next(_dia, None)):") > 0) if($while>1);
            }
        }
    }
    assert($with == 3);
    assert($while == 3);
}

###### START OF CODE CHECK ######
if(0) {
	while(<STDIN>) {	# Manually check the generated code
		;
	}
	while(my $line = <STDIN>) {
		;
	}
	while($line = <STDIN>) {
		;
	}
}

print "$0 - test passed!\n";
