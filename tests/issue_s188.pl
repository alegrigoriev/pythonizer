# issue s188 - Handle \*main::STDIN and \*STDIN as alternates to STDIN
use Carp::Assert;
use Math::Complex ();
# pragma pythonizer -M

*Math::Complex::STDIN = 0;
*Math::Complex::STDOUT = 0;
*Math::Complex::STDERR = 2;

assert(\*main::STDIN == \*STDIN);
assert(\*STDIN != \*Math::Complex::STDIN);
assert(\*main::STDOUT == \*STDOUT);
assert(\*STDOUT != \*Math::Complex::STDOUT);
assert(\*main::STDERR == \*STDERR);
assert(\*::STDERR == \*STDERR);
assert(\*STDERR != \*Math::Complex::STDERR);

sub print_to {
    my $fh = shift;
    print $fh $_[0];
}

sub read_from {
    my $fh = shift;
    <$fh>;
}

close(STDOUT);
open(STDOUT, '>tmp.tmp') or die "Cannot create tmp.tmp";
print_to(\*STDOUT, "l1\n");
print_to(\*::STDOUT, "l2\n");
print_to(\*main::STDOUT, "l3\n");
print_to(STDOUT, "l4\n");
print STDOUT "l5\n";
print "l6\n";       # Defaults to STDOUT
close(STDOUT);
close(STDIN);
open(STDIN, '<tmp.tmp') or die "Cannot open tmp.tmp";
assert(read_from(\*STDIN) eq "l1\n");
assert(read_from(\*::STDIN) eq "l2\n");
assert(read_from(\*main::STDIN) eq "l3\n");
assert(read_from(STDIN) eq "l4\n");
assert(<STDIN> eq "l5\n");
assert(<> eq "l6\n");
close(STDIN);

open(FD, '<tmp.tmp') or die "Cannot open FD on tmp.tmp";
assert(read_from(\*FD) eq "l1\n");
assert(read_from(\*::FD) eq "l2\n");
assert(read_from(\*main::FD) eq "l3\n");
assert(read_from(FD) eq "l4\n");
assert(<FD> eq "l5\n");
assert(<FD> eq "l6\n");

assert(\%ENV == \%::ENV);
assert(\%ENV == \%main::ENV);
assert(\@ARGV == \@::ARGV);
assert(\@ARGV == \@main::ARGV);
assert($#ARGV == $#::ARGV);
assert($#ARGV == $#main::ARGV);
assert(\@INC == \@::INC);
assert(\@INC == \@main::INC);
assert($#INC == $#::INC);
assert($#INC == $#main::INC);

assert($ENV{PATH} eq $::ENV{PATH});
assert($ENV{PATH} eq $main::ENV{PATH});
assert($INC[0] eq $::INC[0]);
assert($INC[0] eq $main::INC[0]);

our @arr = (1, 2, 3);
our @brr = (2, 3, 4);
assert(\@arr != \@brr);

END {
    unlink "tmp.tmp";
}

print_to( STDERR, "$0 - test passed\n");
