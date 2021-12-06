# issue 82: hashref constant on multiple lines fails
use Carp::Assert;

$h = { k => "v" };
assert(scalar(%$h) == 1 && $h->{k} eq "v");

$i = {
    key1 => "val1",
    key2 => "val2"
};
assert(scalar(%$i) == 2 && $i->{key1} eq "val1" && $i->{key2} eq "val2");
$j =
{
    key2 => "val2",
    key3 => "val3"
};
assert(scalar(%$j) == 2 && $j->{key2} eq "val2" && $j->{key3} eq "val3");
$k =                    # comment 1
{ kk => "vv",           # comment 2
# comment 3
};                      # comment 4
assert(scalar(%$k) == 1 && $k->{kk} eq "vv");
print "$0 - test passed!\n";
