# Test the traceback option
# pragma pythonizer -T

use v5.10;
use Carp::Assert;
use IO::File;

$SIG{__WARN__} = sub{};

$py = ($0 =~ /\.py$/);

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
	state $traceback_line = undef;
	state $main_line = undef;

	use constant{SEP=>0, ERR=>1, TB=>2, MN=>3};
	seek(LOG, $log_pos, SEEK_SET);
	my @lines = <LOG>;
	$log_pos = tell LOG;

    if(@lines == 5 && $lines[1] =~ /sh:/) { # happens on unix
        @lines = @lines[0,2..4];
    }
	assert(@lines == 4);
	$lines[SEP] =~ /- (.*?)2? -/;
	$sep = $1;
	$sep =~ s/backtick/run/;
	$sep =~ s/qx/run/;
	$sep =~ s/say/print/;
	assert($lines[ERR] =~ /^$sep/);
	assert($lines[ERR] =~ /failed/);
	assert($lines[ERR] =~ /$pattern/);
	assert($lines[ERR] =~ / at $0 line (\d+)\.$/);
	if(defined $test_line) {
		assert $1 > $test_line;
		$test_line = $1;
	} else {
		$test_line = $1;
	}
	assert($lines[TB] =~ /^\s+test_traceback\(42\) called at $0 line (\d+)$/);
	if(defined $traceback_line) {
		assert($1 == $traceback_line);
	} else {
		$traceback_line = $1;
	}
	assert($lines[MN] =~ /^\s+main_?\('abc', 'def'\) called at $0 line (\d+)$/);
	if(defined $main_line) {
		assert($1 == $main_line);
	} else {
		$main_line = $1;
	}
}

sub test_traceback
{
	say STDERR "---------- open ----------";
	open(FH, '<', 'non-exist.file');
	check(qr/exist/);

        #say STDERR "---------- close ----------";
        #close FH;
        #check(qr/closed/);

	say STDERR "---------- opendir ----------";
	opendir(DH, 'non-exist.dir');
	check(qr/exist/);

	say STDERR "---------- backtick ----------";
	`badcommand`;
	check(qr/badcommand/);

	say STDERR "---------- backtick2 ----------";
	my $result = `badcommand`;
	check(qr/badcommand/);

	say STDERR "---------- system ----------";
	my $bad = "badcommand";
	system "$bad";
	check(qr/badcommand/);

	say STDERR "---------- qx ----------";
	my $bad = "badcommand";
	qx/$bad/;
	check(qr/badcommand/);

	say STDERR "---------- print ----------";
	print FH "text\n";
	check(qr/closed/);

	say STDERR "---------- say ----------";
	say FH "text";
	check(qr/closed/);

	say STDERR "---------- read ----------";
	read(FH, $buf, 1);
	check(qr/closed/);

	say STDERR "---------- sysread ----------";
	sysread(FH, $buf, 1);
	check(qr/fileno/);

	say STDERR "---------- mkdir ----------";
	mkdir ".";
	check(qr/exists/);

	say STDERR "---------- seek ----------";
	seek(FH, 0, 0);
	check(qr/closed/);

	say STDERR "---------- tell ----------";
	tell(FH);
	check(qr/closed/);

	say STDERR "---------- truncate ----------";
	truncate FH, 0;
	check(qr/closed/);

	say STDERR "---------- truncate2 ----------";
	truncate "not.exist", 0;
	check(qr/exist/);
}

sub main
{
	test_traceback(42);
}

@arr = ('abc', 'def');

main(@arr);

close(LOG);
close(STDERR);
unlink "tmp.tmp";

print "$0 - test passed!\n";
