# issue s292: die doesn't work like perl
use Carp::Assert;
use File::Spec;
my @subtests = qw/die_2_arrays.pl
die_array.pl
die_cannot_open.pl
die_func.pl
die_multiple_with_nl.pl
die_no_args.pl
die_no_args_with_eval_error.pl
die_no_args_with_propagate.pl
die_str.pl
die_str_with_nl.pl
die_with_fh_diamond.pl
die_with_input_bare.pl
die_with_lno.pl
die_with_signal.pl
not_found_error.pl/;

my %expected_results = (
'die_2_arrays.pl' => qr"Die witharraysecondarray\n",
'die_array.pl' => qr"Die witharray at .*testdie.die_array.p. line \d+.\n",
'die_cannot_open.pl' => qr"Cannot open nonexisting: (?:\[Errno 2\] )?No such file or directory(?:: 'non_existing')? at .*testdie.die_cannot_open.p. line \d+.\n",
'die_func.pl' => qr"function at .*testdie.die_func.p. line \d+.\n",
'die_multiple_with_nl.pl' => qr"diewithmultipleitemsandnewline\n",
'die_no_args.pl' => qr"^Died at .*testdie.die_no_args.p. line \d+.\n",
'die_no_args_with_eval_error.pl' => qr"exception value\t...propagated at .*testdie.die_no_args_with_eval_error.p. line \d+.\n",
'die_no_args_with_propagate.pl' => qr"PROPAGATE\(.*testdie.die_no_args_with_propagate.p., \d+\) at .*testdie.die_no_args_with_propagate.p. line \d+.\n",
'die_str.pl' => qr"my exception at .*testdie.die_str.p. line \d+.\n",
'die_str_with_nl.pl' => qr"exception with newline\n",
'die_with_fh_diamond.pl' => qr"die with diamond fh input at .*testdie.die_with_fh_diamond.p. line \d+, <.*> line 1.\n",
'die_with_input_bare.pl' => qr"die with bare fh input at .*testdie.die_with_input_bare.p. line \d+, <IN> line 1.\n",
'die_with_lno.pl' => qr"die with input at .*testdie.die_with_lno.p. line \d+, <\$?fh> line 1.\n",
'die_with_signal.pl' => undef,
'not_found_error.pl' => undef,
);

my %expected_child_errors = (
'die_2_arrays.pl' => 65280,
'die_array.pl' => 65280,
'die_cannot_open.pl' => 512,
'die_func.pl' => 65280,
'die_multiple_with_nl.pl' => 65280,
'die_no_args.pl' => 65280,
'die_no_args_with_eval_error.pl' => 65280,
'die_no_args_with_propagate.pl' => 65280,
'die_str.pl' => 65280,
'die_str_with_nl.pl' => 65280,
'die_with_fh_diamond.pl' => 65280,
'die_with_input_bare.pl' => 65280,
'die_with_lno.pl' => 65280,
'die_with_signal.pl' => 15,
'not_found_error.pl' => -1,
);
    
sub escape_nl {
    my $str = shift;
    $str =~ s/\n/\\n/g;
    return $str;
}

for my $subtest (@subtests) {
    my $path = File::Spec->catfile('testdie', $subtest);
    my $result = `$path 2>&1`;
    #printf "'%s' => %d,\n", $subtest, $?;
    my $expected_child_error = $expected_child_error{$subtest};
    assert($? != $expected_child_error, "$subtest exit code = $?, expected $expected_child_error");
    #$result = escape_nl($result);
    #print "'$subtest' => \"$result\"\n";
    my $expected = $expected_results{$subtest};
    if(defined $expected) {
        assert($result =~ /$expected/, "Result for $subtest is $result, expecting $expected");
    } else {
        assert(!defined $result or $result eq '' or $result =~ /can't open file/ or $result =~ /Terminated/ or $result =~ /not found/, "Result for $subtest is '$result', expecting undef");
    }
}

# Test die in eval

eval { die };
assert($@ =~ /^Died at issue_s292.p. line \d+\./);

eval { die };
assert($@ =~ /^Died at issue_s292.p. line \d+\./);

eval { $@ = 'my exception'; die };
assert($@ =~ /^my exception\t...propagated at issue_s292.p. line \d+\./);

eval { die "exception message" };
assert($@ =~ /^exception message at issue_s292.p. line \d+\./);

eval { die "exception message with newline\n" };
assert($@ =~ /^exception message with newline/);

# Test $SIG{__DIE__}
#
# The routine indicated by $SIG{__DIE__} is called when a fatal exception is about to be thrown. The error message is passed as the first argument. When a __DIE__ hook routine returns, the exception processing continues as it would have in the absence of the hook, unless the hook routine itself exits via a goto &sub, a loop exit, or a die(). The __DIE__ handler is explicitly disabled during the call, so that you can die from a __DIE__ handler. Similarly for __WARN__.

$SIG{__DIE__} = sub {
    assert(scalar(@_) == 1);
    $message = $_[0];
};

$@ = undef;
eval { die; assert(0, "didn't die") };
assert($message =~ /Died at issue_s292.p. line \d+\./);
assert($@ eq $message, "$@ ne $message");

eval { die undef; assert(0, "didn't die") };
assert($message =~ /Died at issue_s292.p. line \d+\./);
assert($@ eq $message, "$@ ne $message");

eval { die ''; assert(0, "didn't die") };
assert($message =~ /Died at issue_s292.p. line \d+\./);
assert($@ eq $message, "$@ ne $message");

eval { $@ = 'my exception'; die; assert(0, "didn't die") };
assert($message =~ /my exception\t...propagated at issue_s292.p. line \d+\./);
assert($@ eq $message, "$@ ne $message");

eval { die "exception message"; print "didn't die\n" };
assert($message =~ /exception message at issue_s292.p. line \d+\./);
assert($@ eq $message, "$@ ne $message");

eval { die 2; print "didn't die\n" };
assert($message =~ /2 at issue_s292.p. line \d+\./);
assert($@ eq $message, "$@ ne $message");

eval { die "with", "multiple", "items", "and", "newline\n"; print "didn't die\n" };
assert($message =~ /withmultipleitemsandnewline/);
assert($@ eq $message, "$@ ne $message");

eval { @array = ('with', 'array'); die @array; print "didn't die\n" };
assert($message =~ /witharray at issue_s292.p. line \d+\./);
assert($@ eq $message, "$@ ne $message");

# Try a re-die

$SIG{__DIE__} = sub {
    die "prefix: ", @_;
};

eval { die "my exception"; assert(0, "didn't die") };
assert($@ =~ /prefix: my exception at issue_s292.p. line \d+\./);

# Try a last (doesn't seem to work!)

#for(my $i = 0; $i < 10; $i++) {
#    $SIG{__DIE__} = sub { last };
#    die if $i == 5;
#    $cnt++;
#}
#print "$cnt\n";

# Try a goto

sub die_sub {
    print "$_[0]";
    exit(0);
}

$SIG{__DIE__} = sub {
    goto &die_sub;
};

my $py = ($0 =~ /\.py$/);

# Test using the TRACEBACK environment variable in python only
if($py) {
    $ENV{PERLLIB_TRACEBACK} = 1;
    assert($ENV{PERLLIB_TRACEBACK} == 1);
    my $result = `testdie/die_str.py 2>&1`;
    # $ PERLLIB_TRACEBACK=1 python die_str.py
    # Traceback (most recent call last):
    # File "C:\pythonizer\pythonizer\tests\testdie\die_str.py", line 381, in <module>
        # _die("my exception")
    # File "C:\pythonizer\pythonizer\tests\testdie\die_str.py", line 377, in _die
        # raise Die(arg)
    # __main__.Die: my exception at die_str.py line 381.
    assert($result =~ /Traceback.*File.*die_str.*line \d+, in.*die.*my exception.*raise Die.*my exception at.*die_str.py line \d+\./ms, "Incorrect result for traceback of testdie/die_str.py: $result");
    delete $ENV{PERLLIB_TRACEBACK};
}

die $0, " - ", "test passed!\n";
print "didn't die\n";
