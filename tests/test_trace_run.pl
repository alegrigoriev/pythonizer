# Test the trace run option
# pragma pythonizer -n

use v5.10;
use Carp::Assert;
use IO::File;

$SIG{__WARN__} = sub{};

$py = ($0 =~ /\.py$/);
$nul = ($^O eq 'MSWin32') ? 'nul' : '/dev/null';

open(FH, '<', $0);
close(FH);

close(STDERR);
open(STDERR, ">tmp.tmp");
$| = 1;

open(LOG, "<tmp.tmp");
$log_pos = tell LOG;

sub check {
# Check if the test passed or not
	return if not $py;
	my $pattern = shift;

	state $test_line = undef;
	state $trace_run_line = undef;
	state $main_line = undef;

	use constant{SEP=>0, ERR=>1};
	seek(LOG, $log_pos, SEEK_SET);
	my @lines = <LOG>;
	$log_pos = tell LOG;

	#print "@lines";

	assert(@lines == 2);
	$lines[SEP] =~ /- (.*?)\d? -/;
	$sep = $1;
	$sep =~ s/backtick/run/;
	$sep =~ s/qx/run/;
	$sep =~ s/say/print/;
	assert($lines[ERR] =~ /^trace $sep/);
	assert($lines[ERR] =~ /$pattern/);
	assert($lines[ERR] =~ / at $0 line (\d+)\.$/);
	if(defined $test_line) {
		assert $1 > $test_line;
		$test_line = $1;
	} else {
		$test_line = $1;
	}
}

sub test_trace_run
{
	open(FH, 'echo abc|');
	assert(<FH> =~ /abc/);

	say STDERR "---------- close ----------";
	close FH;
	check(qr/abc.*returncode=0/);

	say STDERR "---------- backtick ----------";
	`badcommand`;
	check(qr/badcommand.*returncode=1/);

	say STDERR "---------- backtick2 ----------";
	my $result = `badcommand`;
	check(qr/badcommand.*returncode=1/);

	say STDERR "---------- backtick3 ----------";
	$result = `echo def`;
	assert($result =~ /def/);
	check(qr/def.*returncode=0/);

	say STDERR "---------- backtick4 ----------";
	my @result = `echo deg`;
	assert($result[0] =~ /deg/);
	check(qr/deg.*returncode=0/);

	say STDERR "---------- system ----------";
	my $bad = "badcommand";
	system "$bad";
	check(qr/badcommand.*returncode=1/);

	say STDERR "---------- system2 ----------";
	my $good = "echo ghi";
	system "$good >$nul";
	check(qr/ghi.*returncode=0/);

	say STDERR "---------- qx ----------";
	$bad = "badcommand";
	qx/$bad/;
	check(qr/badcommand.*returncode=1/);

	say STDERR "---------- qx2 ----------";
	$good = "echo jkl";
	qx/$good/;
	check(qr/jkl.*returncode=0/);

	say STDERR "---------- qx3 ----------";
	$good = "echo mno";
	$result = qx/$good/;
	assert($result =~ /mno/);
	check(qr/mno.*returncode=0/);

	say STDERR "---------- qx4 ----------";
	$good = "echo pqr";
	@result = qx/$good/;
	assert($result[0] =~ /pqr/);
	check(qr/pqr.*returncode=0/);

	say STDERR "---------- -T ----------";
	my $is_text = -T $0;
	assert($is_text);
	check(qr/returncode=0/);

}

test_trace_run();

close(LOG);
close(STDERR);
unlink "tmp.tmp";

print "$0 - test passed!\n";
