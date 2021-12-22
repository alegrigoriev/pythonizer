# issue 92 - everything has the same name and it causes conflicts
use Carp::Assert;
@name = (1,2,3);
%name = (k1=>'v1');
$name = "abc";
sub name { return "name"; }

assert($name[0] == 1);
assert($name{k1} eq 'v1');
assert($name eq "abc");
assert(&name() eq 'name');

assert("$name[0] $name{k1} $name" eq '1 v1 abc');

# Now try one that's also a python keyword:

@in = (4,5);
%in = (in=>'out');
$in = 'in';
assert($in[0] == 4);
assert($in{in} eq 'out');
assert($in eq 'in');
assert("$in[0] $in{in} $in" eq "4 out in");

sub mysub {
    my @sum = (42);
    my $sum;
    foreach my $name (@name) {
        $sum += $name;
    }
    assert($sum == 6);
    return $sum[0];
}

assert(mysub() == 42);

my $FH = "fh";
open FH, ">tmp.tmp";
print FH "data\n" or die("Can't write to file");
close(FH);
open(FH, "<tmp.tmp");
assert(<FH> eq "data\n");
assert($FH eq 'fh');

END {
    eval {close(name)};
    eval {unlink "tmp.tmp"};
}

print "$0 - test passed!\n";
