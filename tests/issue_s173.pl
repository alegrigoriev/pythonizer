# issue s173 - File::Path functions need an empty array passed for the error => $err parameter
# pragma pythonizer verbose
use File::Path qw/make_path remove_tree/;
use Carp::Assert;

my $path1 = '/foo/bar';
my $path2 = '/bar/rat';
if($^O eq 'MSWin32') {
    $path1 = 'Z:\\foo\\bar';
    $path2 = 'Z:\\bar\\rat';
}
# From the documentation (sort-of):
make_path( $path1, $path2, {error => \my $err} );
my $tot;
if ($err && @$err) {
    for my $diag (@$err) {
        my ($file, $message) = %{$diag};
        if ($file eq '') {
            #print "general error: $message\n";
            assert(0);
        }
        else {
            #print "problem creating $file: $message\n";
            assert($file =~ /foo/ || $file =~ /bar/);
            assert($message =~ /Permission/ || $message =~ /No such/ || $message =~ /cannot find/);
            $tot++;
        }
    }
}
else {
    #print "No error encountered\n";
    assert(0);
}
assert($tot == 2 || $tot == 4);

# Let's try the result parameter, first create some dirs
make_path('foo/bar', 'bar/rat', {error => \my $err});
assert(!@$err);
assert(-d 'foo/bar' && -d 'bar/rat');

remove_tree('foo/bar', 'bar/rat', {result => \my $res});
assert(@$res);
assert($res->[0] eq 'foo/bar');
assert($res->[1] eq 'bar/rat');
assert(! -d 'foo/bar' && ! -d 'bar/rat');

print "$0 - test passed!\n";

END {
    eval {rmdir 'foo/bar'};
    eval {rmdir 'foo'};
    eval {rmdir 'bar/rat'};
    eval {rmdir 'bar'};
}
