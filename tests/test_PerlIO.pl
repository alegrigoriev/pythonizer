# Test for PerlIO
use Carp::Assert;
use PerlIO;

@layers = ();
sub compare_lists {
    my ($list1, $list2) = @_;
    @layers = @$list1;
    return 0 unless @$list1 == @$list2;
    for (my $i = 0; $i < @$list1; $i++) {
        return 0 unless $list1->[$i] eq $list2->[$i];
    }
    return 1;
}

my $py = ($0 =~ /\.py/);

# Test that perlio::get_layers returns an empty list for a plain file handle
my $fh = IO::File->new('tmp.tmp', 'w') or die $!;
if($^O eq 'msys' || $^O eq 'MSWin32' || !$py) {
    assert(compare_lists([PerlIO::get_layers($fh)], ['unix', 'perlio']), "plain file handle with [@layers]");
} else {
    assert(compare_lists([PerlIO::get_layers($fh)], [qw/unix perlio encoding(utf-8-strict) utf8/]), "plain file handle on unix with [@layers]");
}
$fh->close();

# Test that perlio::get_layers returns the expected list of layers for a file handle
# opened with the ":encoding(UTF-8)" layer
my $fh2 = IO::File->new('tmp.tmp', 'w') or die $!;
binmode $fh2, ":encoding(UTF-8)";
assert(compare_lists([PerlIO::get_layers($fh2)], [qw/unix perlio encoding(utf-8-strict) utf8/]), "expected list for file handle with :encoding(UTF-8) layer with [@layers]");
$fh2->close();

# Test that perlio::get_layers returns the expected list of layers for a file handle
# opened with the ":encoding(UTF-8)", ":crlf" and ":gzip" layers
#my $fh3 = IO::File->new('tmp.tmp', 'w') or die $!;
#binmode $fh3, ":encoding(UTF-8):crlf:gzip";
#assert(compare_lists([PerlIO::get_layers($fh3)], [":encoding(UTF-8)", ":crlf", ":gzip"]), "expected list for file handle with :encoding(UTF-8), :crlf and :gzip layers with [@layers]");
#$fh3->close();

END {
    unlink "tmp.tmp";
}

print "$0 - test passed!\n";
