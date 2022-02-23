# issue string exprs - expressions in string interpolation didn't work
# pragma pythonizer -M
use Carp::Assert;

# $answer = "STRING @{[ LIST EXPR ]} MORE STRING";
# $answer = "STRING ${\( SCALAR EXPR )} MORE STRING";

my $n = 10;

assert("I have ${\($n + 1)} guanacos." eq "I have " . ($n + 1) . " guanacos.");

$rec = "a:b:c";

assert("What you want is @{[ split /:/, $rec ]} items" eq 'What you want is a b c items');

$naughty = "Customer";
$cn = 10;

# This line replaced below since we can't handle multiple statements: Date: @{ [ do { my $now="2/9/2022\n"; chomp $now; $now } ]} (today)
check_mail(<<"EOTEXT");
To: $naughty
From: Your Bank
Cc: @{ [get_manager_list($naughty)] }
Date: ${\("2/9/2022")} (today)
Dear $naughty,

Today, you bounced check number ${\(500+$cn)}. Your account is now closed.

Sincerely,
The Management
EOTEXT

sub check_mail {
	my $arg = shift;

	my @lines = split /\n/, $arg;
	my $i = 0;
	assert($lines[$i++] =~ /To: Customer/);
	assert($lines[$i++] eq 'From: Your Bank');
	assert($lines[$i++] eq 'Cc: George Harry Mary');
	assert($lines[$i++] eq 'Date: 2/9/2022 (today)');
	assert($lines[$i++] =~ /Dear Customer,/);
	assert(!$lines[$i++]);
	assert($lines[$i++] =~ /number 510\. Your/);
}

sub get_manager_list {
	return ("George", "Harry", "Mary");
}

# here is one from bootstrapping Pythonizer.pm:


$top = {key=>'val'};
$val = "updated nesting_info=@{[%{$top}]}";
assert($val eq 'updated nesting_info=key val');

print "$0 - test passed!\n";
