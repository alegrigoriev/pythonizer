# issue s252 - If a for(each) loop modifies the loop counter, that modification needs to update the array being iterated
use Carp::Assert;
no warnings 'experimental';
use feature 'switch';

# Test using a loop counter variable
my @array = (1, 2, 3);
my $copy_array = [@array];

my $ctr = 0;
foreach my $element (@array) {
    $element++;
    assert( $element == $array[$ctr], "Change to loop counter variable didn't update array" );
    assert( $element != $copy_array->[$ctr++], "Loop counter variable is not modifying the array being iterated on" );
}
assert(@array ~~ [2,3,4], "First array has not been modified as expected");
assert($copy_array ~~ [1,2,3], "First array copy has been modified!");

# Test using the default variable as loop counter
@array = (4, 5, 6);
$copy_array = [@array];

$ctr = 0;
my $not_used = 0;
foreach (@array) 
{
    # Try having multiple statements on the line that mods the loop counter: check the generated code
    $_++; $not_used++; assert( $_ == $array[$ctr], "Change to default loop counter variable didn't update array" ); $not_used--;
    assert( $_ != $copy_array->[$ctr++], "Default loop counter variable is not modifying the array being iterated on" );
}
assert($copy_array ~~ [4,5,6], "Array copy has been modified!");

# Verify that the array has been modified
assert( join( ',', @array ) eq '5,6,7', "Array has not been modified as expected" );

# test with multiple modifications to the loop counter, some conditional!!
for my $a (@array) {
    given($a) {
        $a++ when 5;
        $a-- when 7;
    }
    $a++;
}
assert(join(',', @array) eq '7,7,7', "Array has not been modified to all sevens");

# Try some weird ways to modify the loop counter: scalar out parameter
sub add_one {
    $_[0]++;
}
for (@array) {
    add_one($_);
}
assert(join(',', @array) eq '8,8,8', "Array has not been modified to all eights");

# Try some weird ways to modify the loop counter: scalar reference out parameter
sub add_one_ref {
    my $arg = $_[0];

    $$arg++;
}
for (@array) {
    add_one_ref(\$_);
}
assert(join(',', @array) eq '9,9,9', "Array has not been modified to all nines");

# Try some weird ways to modify the loop counter: read
open(FH, '>tmp.tmp') or die "Cannot create tmp.tmp";
END { unlink "tmp.tmp" }
print FH '678';
close(FH);
open(IN, '<tmp.tmp') or die "Cannot open tmp.tmp";

$ctr = 0;
$copy_array = [@array];
for my $e (@array) {
    read IN, $e, 1;
    assert($e == $array[$ctr++], "Read into loop counter variable didn't update array");
}
close(IN);
assert( join(',', @array) eq '6,7,8', "Array has not been modified by read as expected");

# Another wierd way to modify the loop counter: substitute
@array = ('aa', 'ba', 'ca');
for my $subme (@array) {
    $subme =~ s/a/z/g;
}
assert(join(',', @array) eq 'zz,bz,cz');

# Substitute on the default variable
@array = ('aa', 'ba', 'ca');
s/a/z/g for (@array);
assert(join(',', @array) eq 'zz,bz,cz');

# Chomp on the default variable
@array = ("aa\n", "bb\n", "cc\n");
for (@array) {
    chomp;
}
assert(@array ~~ ['aa', 'bb', 'cc'], "Array has not be chomped");

# Chop on the default variable
for (@array) {
    chop;
}
assert(@array ~~ ['a', 'b', 'c'], "Array has not be chopped");

use Scalar::Util qw/openhandle/;

# Change the array to an array of file handles via open
@array = (undef, undef, undef);
for my $fh (@array) {
    open($fh, '<tmp.tmp');
}
for(my $i = 0; $i < scalar(@array); $i++) {
    assert(openhandle($array[$i]), "Array [$i] doesn't contain an open handle");
    close($array[$i]);
}

# Change the array to an array of file handles via open, this version uses the familiar "or die" idiom
# and starts with the array containing 3 closed file handles
for my $fh (@array) {
    open($fh, '<tmp.tmp') or die "Cannot open tmp.tmp";
}
for(my $i = 0; $i < scalar(@array); $i++) {
    assert(openhandle($array[$i]), "Array [$i] doesn't contain an open handle");
    close($array[$i]);
}

# A non-'my' loop counter
@array = ('a', 'b', 'c');
$val = 'before';
for $val (@array) {
    $val = chr((ord $val)+1);
}
assert($val eq 'before');
assert(join('', @array) eq 'bcd', "non-'my' loop counter test failed");

# A non-'my' loop counter, changed by a sub call
sub noop { }
sub new_val {
    return $val if length($val) != 1;
    $val = chr((ord $val)+1);
}
    
@array = ('a', 'b', 'c');
for $val (@array) {
    noop();         # Should not set @array
    new_val();      # Should set @array
}
assert($val eq 'before');
assert(join('', @array) eq 'bcd', "change loop counter in sub test failed");

# Same test but with 'my' - should not be modifying the loop counter
for my $val (@array) {
    new_val();              # Should not set @array
}
assert(join('', @array) eq 'bcd', "sub changed 'my' loop counter incorrectly");

# Same test but with 'my' with a conditional change in the loop ctr - should not be modifying the loop counter
for my $val (@array) {
    new_val();              # Should not set @array
    $val = 'a' if $val eq 'b';
}
assert(join('', @array) eq 'acd', "sub changed 'my' loop counter incorrectly with conditional");

# Pythonizer doesn't make $_ (_d) global, so let's skip this test
## Default loop counter, modified by sub
#sub modify_default {
#    $_ = "modified";
#}
#
#@array = ("original", "original", "original");
#
#foreach (@array) {
#    modify_default();       # should set @array
#    noop();                 # should not set @array
#}
#
#for(my $i = 0; $i < @array; $i++) {
#    assert( $array[$i] eq "modified", "Array element $i should be modified inside subroutine" );
#}

# Fully qualified loop counter
@array = ('b', 'c', 'd');
$main::c = 'b4';
for $main::c (@array) {
    $main::c = chr((ord $main::c)-1);
}
assert($main::c eq 'b4');
assert(join('', @array) eq 'abc', "Fully qualified loop counter didn't update array");

# Fully qualified loop counter - same but with the change now being in a sub
@array = ('b', 'c', 'd');
sub change_c {
    $main::c = chr((ord $main::c)-1);
}
for $main::c (@array) {
    change_c;       # Should modify @array
    noop();         # Should not modify @array
}
assert($main::c eq 'b4');
assert(join('', @array) eq 'abc', "Fully qualifies loop counter didn't update array from sub");

# Try a nested case
my $arr = [[1,2], [3,4]];
foreach my $outer (@$arr) {
    foreach my $inner (@$outer) {
        $inner++; 
        if(@$outer ~~ [4,5]) {
            $outer = [5,6];     # Modify the outer counter in the inner loop
        }
    }
}
assert(join(',', @{$arr->[0]}, @{$arr->[1]}) eq '2,3,5,6', "Nested arrayref update didn't work properly");

# Try using a complex array expression that we can modify
$hashref = {key=>[1,2,3]};
for (@{$hashref->{key}}) 
{
    $_--;
}
assert($hashref->{key} ~~ [0,1,2]);

# Now try a complex array expression that we can't modify
my $str = 'a,b,c';
foreach (split(/,/, $str)) {
    $_ = chr(1 + ord);      # Should NOT update $str
}
assert($str eq 'a,b,c');

my $found = '';
my ($i, $j, $k) = ('a', 'b', 'c');
for ($i, $j, $k) {
    $found .= $_;
    $_ = 'z';
}
assert($found eq 'abc');
#assert("$i$j$k" eq 'zzz' || "$i$j$k" eq 'abc');     # Pythonizer doesn't handle this case - let it slide
assert("$i$j$k" eq 'zzz');

#use Data::Dumper;
#print Dumper($arr);

# Now for the actual test case from CGI.pm:

my @other = ('location="http://www.example.com"');
for (@other) {
        # Don't use \s because of perl bug 21951
        next unless my($header,$value) = /([^ \r\n\t=]+)=\"?(.+?)\"?$/s;
        ($_ = $header) =~ s/^(\w)(.*)/"\u$1\L$2" . ': '.unescapeHTML($value)/e;
}
assert($other[0] eq 'Location: http://www.example.com');
sub unescapeHTML {
    return shift;
}

# Here is another case from CGI.pm using a list of items:

$CRLF = "\015\012";
my ($type, $status, $target, $expires, $nph, $charset, $attachment, $p3p);
my @cookie = ();
$target = "$CRLF target";
for my $header ($type,$status,@cookie,$target,$expires,$nph,$charset,$attachment,$p3p,@other) {
    if (defined $header) {
        # From RFC 822:
        # Unfolding  is  accomplished  by regarding   CRLF   immediately
        # followed  by  a  LWSP-char  as equivalent to the LWSP-char.
        $header =~ s/$CRLF(\s)/$1/g;
    }
}
#assert($target eq " target" || $target eq "$CRLF target");
assert($target eq " target");

print "$0 - test passed!\n";
