# issue_108: Implement local
use Carp::Assert;

# Local at the file level is the same as 'my':

local ($a, @b, %c);
$a = 'a';
@b = ('b');
%c = (c=>'d');
assert($a eq 'a');
assert(@b == 1 && $b[0] eq 'b');
assert($c{c} eq 'd');

# Variables named 'local':

$local = 'abc';
@local = ('a', 'b', 'c');
%local = (k1=>'v1');
assert($local eq 'abc');
assert($local[0] eq 'a');
assert($local{k1} eq 'v1');

sub getLocals
{
    return ($local, \@local, \%local);
}

sub testLocal
{
    local *local;

    assert(!defined $local);
    assert(!@local);
    assert(!%local);

    $local = 'def';
    @local = ('d', 'e', 'f');
    %local = (k2=>'v2');

    assert($local eq 'def');
    assert($local[0] eq 'd');
    assert($local{k2} eq 'v2');

    ($v, $a, $h) = getLocals();

    assert($v eq 'def');
    assert($a->[0] eq 'd');
    assert($h->{k2} eq 'v2');
}

testLocal();

assert($local eq 'abc');
assert($local[0] eq 'a');
assert($local{k1} eq 'v1');

sub subtest
{
    assert($arg == 14);
}

sub testLocal2
{
    local $arg = shift;
    local ($i, $j, $k) = (7,7,7);
    assert($i == 7 && $j == 7 && $k == 7);
    subtest();
    if(1) {
        local $inner = 42;
        assert($inner == 42);
        local $noninit;
        assert(!$noninit);
    }
    return $arg;
}

assert(!defined $arg);
assert(testLocal2(14) == 14);
assert(!defined $arg);
assert(!defined $inner);

# now the fun part - combine locals with a block that needs a try/except for loop control

my $ctr = 0;
OUTER:
for(my $i=0; $i < 2; $i++) {
    local $outer_loop = $i;
    assert($outer_loop == $i);
    for(my $j=0; $j < 2; $j++) {
        $ctr++;
        local $inner_loop = $j;
        assert($inner_loop == $j);
        last OUTER if($j == 1);
    }
}
assert($ctr == 2);
assert(!defined $inner_loop);
assert(!defined $outer_loop);

my $save_stdout = STDOUT;
{
    local *STDOUT;

    open(STDOUT, '>tmp.tmp');
    print "This goes to the file\n";
    close(STDOUT);
    open(FH, '<tmp.tmp');
    chomp(my $line = <FH>);
    assert($line eq 'This goes to the file');
}
assert(STDOUT == $save_stdout);

# More tests from some real code

sub useFILE
{
    local *FILE;

    open(FILE, '>tmp.tmp');
    print FILE "file output\n";
    close(FILE)

}

useFILE();

if(print FILE "file output\n") {
    assert(0);
}

sub useBRACKETS
{
      local ( ${query}, @{lines}, @{tmp}, @{fields}, ${i}, ${j} );

      ${query} = "select NAME from TABLE ";
      @lines = ("f1|f2", "f3|f4");
      @{fields} = split( /\|/, ${lines[${i}]} );
      ${f1} = ${fields[0]};
      ${f2} = ${fields[1]};
      assert($f1 eq 'f1' && $f2 eq 'f2');
}
useBRACKETS();

assert(!$query);
assert(!@lines);

sub useCONDITIONAL
{
    local (*in) = shift if @_;
    local (*incfn,
        *inct,
        *insfn) = @_;

    if($incfn eq 'use_in') {
        $in = join('&', keys %in);
        @in = split(/[&;]/, $in);
        assert(scalar(@in) == 2 && (($in[0] eq 'in0' && $in[1] eq 'in1') ||
                            ($in[0] eq 'in1' && $in[1] eq 'in0')));
    } else {
        assert(scalar(@_) == 0);
    }
}
useCONDITIONAL({in0=>'y', in1=>'y'}, \'use_in');
useCONDITIONAL();

@arr = (1,2,3);
%hash = (key=>'value');
%h2 = (cat=>'puddy');

sub useArrHash
{
    local $arr[1] = 6;
    local $hash{key} = "val";
    local ($h2{cat}) = 'ralph';

    assert(join('', @arr) eq '163');
    assert($hash{key} eq 'val');
    assert($h2{cat} eq 'ralph');
}

assert(join('', @arr) eq '123');
assert($hash{key} eq 'value');
assert($h2{cat} eq 'puddy');
useArrHash();
assert(join('', @arr) eq '123');
assert($hash{key} eq 'value');
assert($h2{cat} eq 'puddy');

END {
    eval {unlink "tmp.tmp"};
}

print "$0 - test passed!\n";
