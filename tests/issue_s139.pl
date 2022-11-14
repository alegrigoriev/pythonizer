# issue s139: Multiple '}' on the same line not being recognized as block close
# from nv_rename.pl
use Switch;
use Carp::Assert;

sub isEMT {
    return 1 if($my_model eq 'CN3930');
    return 0;
}
my $rfile;
my $my_device_function;
my @Values = ('CN3930|mt3', 'CN3931|nt4', 'CN3940|mx1', 'other|unknown');
for (@Values) {
    ($my_model, $result) = split '\|';
    switch ($my_model) {

    case "CN3930"       { if (isEMT($rfile) == 1) {$my_device_function="mt3"} else {$my_device_function="nt3"} }
    case "CN3931"       { if (isEMT($rfile) == 1) {$my_device_function="mt4"} else {$my_device_function="nt4"} }
    case "CN3940"       { $my_device_function="mx1" }

    else { $my_device_function="unknown" }

    }
    assert($my_device_function eq $result);
}

print "$0 - test passed!\n";

