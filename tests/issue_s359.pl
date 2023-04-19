# issue s359 - referencing an array element that doesn't exist shouldn't create it
use Carp::Assert;

@arr = ();

$r = $arr[0];
assert(!defined $r);
assert(scalar(@arr) == 0);

$r = $arr[$#arr];
assert(!defined $r);
assert(scalar(@arr) == 0);

if(@arr) {
	assert(0, "\@arr should evaluate as false");
}

$r = "$arr[0]";
assert($r eq '');
assert(scalar(@arr) == 0);

$arr[0] = 42;
$r = $arr[0];
assert($r == 42);
assert(scalar(@arr) == 1);
$r = $arr[$#arr];
assert($r == 42);

assert("$arr['0']" eq '42');

assert("$arr[1][0]" eq '');
assert(scalar(@arr) == 2);
assert(ref $arr[1] eq 'ARRAY');

assert(!defined $arr[2][0]);
assert(scalar(@arr) == 3);
assert(ref $arr[2] eq 'ARRAY');

# Check fix for related issue
assert("$hash{key}[0]" eq '');
assert(exists $hash{key});
assert(ref $hash{key} eq 'ARRAY');

sub noargs {
    my $r = $_[0];

    assert(!defined $r);
    assert(scalar(@_) == 0);
    my $zero = 0;
    $r = $_[$zero];
    assert(!defined $r);
    assert(scalar(@_) == 0);

    assert("$_[0]" eq '');
    assert(scalar(@_) == 0);

}
noargs();

$r = $ARGV[0];
assert(!defined $r);
assert(scalar(@ARGV) == 0);
assert("$ARGV[0]" eq '');

@result = ();
push @result, [1, 2, 3];        # Needs to be an Array, not a list
assert(@result == 1);
assert($result[0]->[2] == 3);

push @result, {key=>'value'};
assert(@result == 2);
assert($result[1]->{key} eq 'value');

unshift @result, [4, 5];
assert(@result == 3);
assert($result[0]->[1] == 5);

unshift @result, {k2=>'v2'};
assert(@result == 4);
assert($result[0]->{k2} eq 'v2');

my $keys = ['key1', 'key2', 'key3'];	# Arrayref
my $key = @$keys[0];	# 0th element of arrayref turned into array
assert($key eq 'key1');

my $ndx = 2;
assert((1,2,3,4)[$ndx] == 3);
assert([2,3,4]->[$ndx] == 4);

my $words = 'w1 w2 w3';
assert((split ' ', $words)[$ndx] eq 'w3');

# Test things that failed due to this code change

# Sample values for testing 
my $codeSrcDir = "/path/to/codeSrcDir"; 
my $diffcmd = "diff"; 
my $templateName = "template.txt"; 
my @xmlrouters = ("router1", "router2"); 
my $summaryOutFile = "summary.txt"; 
my $type = "type"; 
my $rversion = "1.0"; 
my $discordOutFile = "discord.txt"; 
# Test the command string 
for my $i (0 .. scalar(@xmlrouters) - 1) { 
    my $cmd = "$codeSrcDir/$diffcmd $templateName $xmlrouters[$i].xml $summaryOutFile $type \"$rversion\" >> $discordOutFile";
    my $expected_cmd = join(' ', $codeSrcDir . '/' . $diffcmd, $templateName, $xmlrouters[$i] . '.xml', $summaryOutFile, $type, '"' . $rversion . '"', '>>', $discordOutFile ); 
    assert($cmd eq $expected_cmd, "Command string ($cmd) is not as expected ($expected_cmd)"); 
}

my @cirtxt = ('A');
my $cmd = "checkScript: First line is \"$cirtxt[0]\"";
assert($cmd eq 'checkScript: First line is "A"');

my %h = (key=>'value');
$cmd = "Testing \"$h{key}\"";
assert($cmd eq 'Testing "value"');

print "$0 - test passed!\n";
