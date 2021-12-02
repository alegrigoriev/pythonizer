# issue 78 - bad code to translate all words to upper case
use strict;
use warnings "all";
use Carp::Assert;

my @lines = ('these lines are going to be',
          'converted to uppercase words',
          "let's see if it works");
my @ulines = ('These Lines Are Going To Be',
          'Converted To Uppercase Words',
          "Let'S See If It Works");

my $fn = 'test_tmp.tmp';
open(my $outf, ">", $fn);
for my $line (@lines) {
    say $outf $line;
}
close $outf;

open(my $fh, "<", "$fn") or die;
my @upper = ();
while (<$fh>)
{
    chomp;
    # With the global modifier, s///g will search and replace all occurrences of the regex in the string (else it only does 1)
    # The evaluation modifier s///e wraps an eval{...} around the replacement string and the evaluated result is substituted for the matched substring.
    s,\b(\D),uc $1,ge;
    #print;
    push @upper, $_;
}
close $fh;

assert(scalar(@upper) == scalar(@ulines));
for(my $i = 0; $i < scalar(@ulines); $i++) {
    assert($upper[$i] eq $ulines[$i]);
}

print "$0 - test passed!\n";
