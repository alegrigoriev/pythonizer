# issue s288 - warn doesn't work like perl
use Carp::Assert;
no warnings 'experimental';

open(SAVERR, '>&STDERR');
open(STDERR, '>tmp.tmp');

sub runtest {
    warn;
    warn undef;
    warn '';
    $@ = 'exception value';
    warn;
    warn 'my warning';
    warn 2;
    warn('function');
    warn "warning with newline\n";
    warn "warn", "with", "multiple", "items";
    warn "warn", "with", "multiple", "items", "and", "newline\n";
    my @warnarray = ('Warn with', 'array');
    warn @warnarray;
    my @twoarray = ('second', "array\n");
    warn @warnarray, @twoarray;
    # Include $. in the message
    open(my $fh, "<$0") or die "Can't open $0";
    my $line = <$fh>;
    warn "1st warning with input";
    open(IN, "<$0") or die "Can't open $0";
    my $line = <IN>;
    warn "2nd warning with input";
    close(IN);
    push @ARGV, $0;
    $line = <>;
    warn "3rd warning with input";
}
runtest();
close(STDERR);
open(STDERR, '>&SAVERR');
my @expected_results = (
    qr/Warning: something's wrong at issue_s288.p. line \d+./,
    qr/Warning: something's wrong at issue_s288.p. line \d+./,
    qr/Warning: something's wrong at issue_s288.p. line \d+./,
    qr/exception value\t...caught at issue_s288.p. line \d+./,
    qr/my warning at issue_s288.p. line \d+./,
    qr/2 at issue_s288.p. line \d+./,
    qr/function at issue_s288.p. line \d+./,
    qr/warning with newline/,
    qr/warnwithmultipleitems at issue_s288.p. line \d+./,
    qr/warnwithmultipleitemsandnewline/,
    qr/Warn witharray at issue_s288.p. line \d+./,
    qr/Warn witharraysecondarray/,
    qr/1st warning with input at issue_s288.p. line \d+, <\$?fh> line 1./,
    qr/2nd warning with input at issue_s288.p. line \d+, <IN> line 1./,
    qr/3rd warning with input at issue_s288.p. line \d+, <.*> line 1./,
);
open(TMP, '<tmp.tmp') or die "Can't open tmp.tmp";
my @actual_results = <TMP>;
close(TMP);
chomp @actual_results;
sub checkresults {
    assert(scalar(@actual_results) == scalar(@expected_results), "Expecting " . scalar(@expected_results) . " results, got " . scalar(@actual_results) . $_[0]);
    #assert(@expected_results ~~ @actual_results, "Expecting @expected_results, got @actual_results");
    for(my $i = 0; $i < scalar(@expected_results); $i++) {
        my $actual = $actual_results[$i];
        my $expected = $expected_results[$i];
        assert($actual =~ /$expected/, "Expecting $expected on line $i, got ${actual}$_[0]");
    }
}
checkresults('');
unlink "tmp.tmp";

# Now set a custom warning handler and make sure it's called

@actual_results = ();
$SIG{__WARN__} = sub { push @actual_results, $_[0] };
$@ = '';
runtest();
$expected_results[-1] = qr/3rd warning with input at issue_s288.p. line \d+, <.*> line 2./;
# In python, we always see the fileinput result first, so allow either answer
$expected_results[-2] = qr/2nd warning with input at issue_s288.p. line \d+, <.*> line 1./;
$expected_results[-3] = qr/1st warning with input at issue_s288.p. line \d+, <.*> line 1./,
checkresults(' with handler');

# Now try a custom warning handler that calls warn - make sure it doesn't cause a recursive loop

$SIG{__WARN__} = sub { warn("$0 - $_[0]") };

warn("test passed!\n");
#print "$0 - test passed!\n";
