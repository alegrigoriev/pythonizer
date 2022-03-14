# issues detected in the ddts code
# pragma pythonizer no implicit global my

use Carp::Assert;
use Data::Dumper;

my $ln;
open (IN, "<$0") or die "Couldn't open input";
$cnt = 0;
while (chop($ln = <IN>)) {
	$cnt++;
}
assert($cnt > 10);

open (IN, "<$0") or die "Couldn't open input";
$cnt = 0;
while (chop($line = <IN>)) {
	$cnt++;
}
assert($cnt > 10);
close(IN);

open (IN, "<$0") or die "Couldn't open input";
$cnt = 0;
while (chop($hash{key}[0] = <IN>)) {
	$cnt++;
}
assert($cnt > 10);
close(IN);


sub ABEND_PROCESS {
 #&SEND_EMAIL("$_[0]");
 if ($_[0] =~/Error/ig) { die; }
}

ABEND_PROCESS("Warn");

eval {
	ABEND_PROCESS("error");
};
#print "$@\n";
assert($@);

$string = "Error here and error there";
@matches = $string =~ /Error/ig;

assert($matches[0] eq 'Error' && $matches[1] eq 'error' && 2 == @matches);

#$match = $string =~ /Error/ig;
#assert($match);
#assert(pos $string == 5);

#$match = $string =~ /Error/ig;
#assert($match);
#assert(pos $string == 20);

sub make_attuid
{
	$rds_hrid = shift;
       if ($rds_hrid =~/ABNORD/i) { $attuid = 'xx9999' }      
        elsif (length($rds_hrid) == 0) { $attuid = 'xx9999' } else { $attuid = lc($rds_hrid) };
	return $attuid;
}

assert(make_attuid('abnord') eq 'xx9999');
assert(make_attuid('') eq 'xx9999');
assert(make_attuid('AB1111') eq 'ab1111');

# issue - using wrong equality on a regex

$rds_rds_number = '12345';
$cnt = 0;
$_ = ' ';
# This actually checks if $_ matches the pattern and then compares that boolean with $rds_rds_number
if ($rds_rds_number !=/\s+/){
	$cnt++;
} else {
	assert(0);
}
assert($cnt == 1);

#$rds_rds_number = 1;
#$cnt = 0;
#if ($rds_rds_number !=/\s+/){
#	assert(0);
#} else {
#	$cnt++;
#}
#assert($cnt == 1);

# issue - extra comma in list is ignored by perl

assert(join('|', 'a', 'b', , 'c') eq 'a|b|c');

# issue - assigning to a sub arg in control stmt generates bad code

sub PAGE_RESPONSE {
	$result = $_[0];
	if ($_[0] =!/ERROR/ig) { return "ERROR FOUND" ; }
	else { return ""; }
}

$_ = '';
$pr = '';
assert(PAGE_RESPONSE($pr) eq 'ERROR FOUND');

# issue - print with bogus \n generates bad code

$verbose = 0;
print STDOUT "error at ", $request->url, '\n' if $verbose;

# issue - string of numbers after @ is a varname

@2017 = ('@2017');

$password="Wonder@2017";

#print "<$password>\n";
assert($password eq 'Wonder@2017');

# Call with no parens but curly brackets generates bad code

sub mySender
{
	#print "mySender(" . Dumper(\@_) . "\n";
	assert($_[0]->{smtp} eq 'localhost');
	assert($_[0]->{from} eq 'do_not_reply@roammail.ims.att.com');
}

$sender = mySender { smtp => 'localhost', from => 'do_not_reply@roammail.ims.att.com' };

eval {
	require Mail::Sender;
	$sender = new Mail::Sender { smtp => 'localhost', from => 'do_not_reply@roammail.ims.att.com' };
};

# From Sys::Hostname:
# issue local $SIG{__DIE__} and evals separated by ||

{
    local $ENV{PATH} = '/usr/bin:/bin:/usr/sbin:/sbin'; # Paranoia.

    # method 2 - syscall is preferred since it avoids tainting problems
    # XXX: is it such a good idea to return hostname untainted?
    eval {
        local $SIG{__DIE__};
        require "syscall.ph";
        $host = "\0" x 65; ## preload scalar
        syscall(&SYS_gethostname, $host, 65) == 0;
    }

    # method 2a - syscall using systeminfo instead of gethostname
    #           -- needed on systems like Solaris
    || eval {
        local $SIG{__DIE__};
        require "sys/syscall.ph";
        require "sys/systeminfo.ph";
        $host = "\0" x 65; ## preload scalar
        syscall(&SYS_systeminfo, &SI_HOSTNAME, $host, 65) != -1;
    }

    # method 3 - trusty old hostname command
    || eval {
        local $SIG{__DIE__};
        local $SIG{CHLD};
        $host = `(hostname) 2>/dev/null`; # BSDish
    }

    || eval {				# Windows
    	chomp($host = `hostname 2> NUL`) unless defined $host;
    	return $host;
    };
    $host =~ tr/\0\r\n//d;
}

assert($host =~ /\w+/);

# issue - variable declared with type (we need to ignore it)

my Carp::Assert $msg = "abc";
assert($msg eq 'abc');

use Sys::Hostname;

#print hostname() . "\n";
assert(hostname() eq $host);

# issue - sub that modifies arg via re.sub needs to get arglist copied

sub myTRIM{
  $_[0] =~ s/\'//g;
  
  return $_[0]; 	
}

my $var = "don't";
assert(myTRIM($var) eq 'dont');

# issue - local hash init with list is messed up

local(%MONTH)=('JAN',0,'FEB',1,'MAR',2,'APR',3,'MAY',4,'JUN',5,'JUL',6,'AUG',7,'SEP',8,'OCT',9,'NOV',10,'DEC',11);

assert($MONTH{FEB} == 1 && $MONTH{DEC} == 11);

print "$0 - test passed!\n";

