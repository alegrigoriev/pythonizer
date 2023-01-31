# issue s252a - If a for(each) loop modifies the loop counter, that modification needs to update the array being iterated
# This version checks the loop counter being aliased to items in a list
use Carp::Assert;

# Set the line break
my $CRLF = "\r\n";

# Initialize the variables
my $type = "Content-Type: text/html".$CRLF." ";
my $status = "200 OK".$CRLF." ";
my $original_status = $status;
my @cookie = ("Set-Cookie: SESSIONID=38afes7a8; Path=/".$CRLF." ", "Set-Cookie: ID=a3fWa; Expires=Wed, 21 Oct 2021 07:28:00 GMT;".$CRLF." ");
my $target = "Location: http://www.example.com/start.html".$CRLF." ";
my $expires = "Expires: Tue, 15 Jan 2021 21:47:38 GMT".$CRLF." ";
my $nph = "HTTP/1.0".$CRLF." ";
my $charset = "Content-Type: text/html; charset=iso-8859-1".$CRLF." ";
my $attachment = "Content-Disposition: attachment; filename=fname.ext".$CRLF." ";
my $p3p = "P3P: CP='ALL DSP COR PSAa PSDa OUR NOR ONL UNI COM NAV'".$CRLF." ";
my @other = ("X-Powered-By: PHP/5.4.0".$CRLF." ", "X-My-Header: some value".$CRLF." ");
my @original_other = @other;

# Loop through the variables
for my $header ($type,$status,@cookie,$target,$expires,
                $nph,$charset,$attachment,$p3p,@other) 
{
    if (defined $header) {
        # Skip the substitute on $status
        next if $header eq $status;

        my $ctr = 0;
        for(my $i = 0; $i < 10; $i++) {
            next if($i > 1);                # Make sure next and last work
            $ctr++;
        }
        for(my $i = 0; $i < 10; $i++) {
            last if($i > 1);                # Make sure next and last work
            $ctr++;
        }
        assert($ctr == 4);

        # From RFC 822:
        # Unfolding  is  accomplished  by regarding   CRLF   immediately
        # followed  by  a  LWSP-char  as equivalent to the LWSP-char.
        $header =~ s/$CRLF(\s)/$1/g;

        # Skip the substitute on @other
        # We can't handle 'last' because we would raise an exception, which would cause the value not to be updated!
        #last if $header eq $p3p;

        # All other uses of newlines are invalid input.
        if ($header =~ m/$CRLF|\015|\012/) {
            # shorten very long values in the diagnostic
            $header = substr($header,0,72).'...' if (length $header > 72);
            die "Invalid header value contains a newline not followed by whitespace: $header";
        }
    }
}

# Assert that the variables in the loop are modified as expected
assert($type !~ m/$CRLF/);
assert($type eq 'Content-Type: text/html ');
assert($status eq $original_status);
assert($cookie[0] !~ m/$CRLF/);
assert($cookie[1] !~ m/$CRLF/);
assert($cookie[1] eq 'Set-Cookie: ID=a3fWa; Expires=Wed, 21 Oct 2021 07:28:00 GMT; ');
assert($target !~ m/$CRLF/);
assert($expires !~ m/$CRLF/);
assert($nph !~ m/$CRLF/);
assert($nph eq 'HTTP/1.0 ');
assert($charset !~ m/$CRLF/);
assert($attachment !~ m/$CRLF/);
assert($p3p !~ m/$CRLF/);
#assert($other[0] eq $original_other[0]);
#assert($other[1] eq $original_other[1]);
assert($other[0] !~ m/$CRLF/);
assert($other[1] !~ m/$CRLF/);
assert($other[1] eq "X-My-Header: some value ");

# Try one in a stmt modifier
my $var1 = 'var1';
my @arr = ('arr0', 'arr1');
my $var2 = 'var2';
s/r/z/ for $var1, @arr, $var2;

assert($var1 eq 'vaz1');
assert($arr[0] eq 'azr0');
assert($arr[1] eq 'azr1');
assert($var2 eq 'vaz2');

# Try one in a sub
sub try_for {
    my $v1 = 'abc';
    @ar = ('ar0', 'zr1');
    for ($v1, @ar) {
        s/a/b/;
    }
    assert($v1 eq 'bbc');
    assert($ar[0] eq 'br0');
    assert($ar[1] eq 'zr1');
}
try_for();

# Try one in a sub with a stmt modifier
# FIXME: Why doesn't this one work?
#sub try_for_stmt_mod {
#    my $v1 = 'abc';
#    @ar = ('ar0', 'zr1');
#    s/a/b/ for $v1, @ar;
#    assert($v1 eq 'bbc');
#    assert($ar[0] eq 'br0');
#    assert($ar[1] eq 'zr1');
#}
#try_for_stmt_mod();

# Try more complex list items
$hash{key} = [1, 2];
$array[0] = [3, 4];
$array[1] = 5;

for (@{$hash{key}}, @{$array[0]}, $array[1]) {
    $_++;
}
assert($hash{key}->[0] == 2);
assert($hash{key}->[1] == 3);
assert($array[0]->[0] == 4);
assert($array[0]->[1] == 5);
assert($array[1] == 6);

# Same test with a non-my loop counter
$hash{key} = [1, 2];
$array[0] = [3, 4];
$array[1] = 5;

for $non_my (@{$hash{key}}, @{$array[0]}, $array[1]) {
    $non_my++;
    $iterations++;
}
assert($hash{key}->[0] == 2);
assert($hash{key}->[1] == 3);
assert($array[0]->[0] == 4);
assert($array[0]->[1] == 5);
assert($array[1] == 6);
assert($iterations == 5);

# Same test yet again as this time $non_my is known
$non_my = 'non_my';
$hash{key} = [1, 2];
$array[0] = [3, 4];
$array[1] = 5;

for $non_my (@{$hash{key}}, @{$array[0]}, $array[1]) {
    $non_my++;
    $iterations++;
}
assert($hash{key}->[0] == 2);
assert($hash{key}->[1] == 3);
assert($array[0]->[0] == 4);
assert($array[0]->[1] == 5);
assert($array[1] == 6);
assert($iterations == 10);
assert($non_my eq 'non_my');

print "$0 - test passed\n";
