# issue s166 - open(COPY, '>&HANDLE') does not generate proper code
# Ref: docstore.mik.ua/orelly/perl4/cook/ch07_11.htm

use Carp::Assert;

# Doesn't work well on windows:
#my $joe_random_program = 'echo stdout
#echo stderr 1>&2';

# take copies of the file descriptors 
open(OLDOUT, ">&STDOUT"); 
#open(OLDERR, ">&STDERR"); 
open(OLDERR, ">&", STDERR);     # try the 3-argument style
# redirect stdout and stderr 
open(STDOUT, "> tmp.tmp") or die "Can't redirect stdout: $!"; 
open(STDERR, ">&STDOUT") or die "Can't dup stdout: $!"; 
# run the program 
#system($joe_random_program); 
system('echo stdout');
system('echo stderr 1>&2');
# close the redirected filehandles 
close(STDOUT) or die "Can't close STDOUT: $!"; 
close(STDERR) or die "Can't close STDERR: $!"; 
# restore stdout and stderr 
open STDERR, ">&OLDERR"  or die "Can't restore stderr: $!"; 
open(STDOUT, ">&OLDOUT") or die "Can't restore stdout: $!"; 
# avoid leaks by closing the independent copies 
close(OLDOUT) or die "Can't close OLDOUT: $!"; 
close(OLDERR) or die "Can't close OLDERR: $!"; 

open(TMP, '<tmp.tmp') or die "Can't open tmp.tmp: $!";
open(ALIAS, ">&=TMP") or die "Can't create alias of TMP: $!";
my $alias_fno = fileno ALIAS;
open(FH, "<&=", $alias_fno) or die "Can't open FH from fileno $alias_fno: $!";
chomp(@lines = <FH>);
close(TMP); close(ALIAS); close(FH);
assert(@lines == 2);
assert($lines[0] eq 'stdout');
assert($lines[1] =~ /^stderr/); # Could have a space after it (python on Windoze)

# test numeric filename
my $fn = 11111135;
open(NUM, '<', $fn) or die "Can't open $fn with numeric filename: $!";
while(<NUM>) {
    assert(0);      # file should be empty!
}
close(NUM);

# test opening a file defined by a program argument (from cmt/so.pl):
@ARGV = ($0);
open (SETA, "<", $ARGV[0]) or die "$ARGV[0]: $?";
$line = <SETA>;
close(SETA);
assert(substr($line,0,1) eq '#');

END {
    unlink "tmp.tmp";
}

print "$0 - test passed!\n";
