# issue s230 - simple pattern match that generates .find() gives bad code, also .find can't be directly used if the pattern contains an anchor, and escape characters like '\.' need to be removed from find patterns
use Carp::Assert;

my $dl_dlext = 'dlext';
for ('abc', 'abc.dlext') {
    push(@names,"$_.$dl_dlext")    unless m/\.$dl_dlext$/o; # can't use .find anyhow!!
    push(@names2,"$_.$dl_dlext")    unless m/\.dlext/o; # can use .find!
    my $v = $_;
    push(@names3,"$_.$dl_dlext")    unless $v =~ m/\.dlext/o; # can use .find!
}
assert(@names == 1);
assert($names[0] eq 'abc.dlext');
assert(@names2 == 1);
assert($names2[0] eq 'abc.dlext');
assert(@names3 == 1);
assert($names3[0] eq 'abc.dlext');

print "$0 - test passed!\n"
