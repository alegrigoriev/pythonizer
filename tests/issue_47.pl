use Carp::Assert;
@ar = qw/aa bb cc dd/;
%ha = (key1 => 'val1', key2 => 'val2');
assert($" eq ' ');
$s = "ar=@ar,ha=@{[%ha]}";
# See code to generate: https://github.com/softpano/pythonizer/issues/47
assert($s eq 'ar=aa bb cc dd,ha=key1 val1 key2 val2' ||
       $s eq 'ar=aa bb cc dd,ha=key2 val2 key1 val1');

# 12/30/21: Try using both at once:
$s = "ar[0]=$ar[0], ar=@ar, ha{key1}=$ha{key1}";
assert($s eq 'ar[0]=aa, ar=aa bb cc dd, ha{key1}=val1');

assert("snoopyjc@gmail.com" eq 'snoopyjc.com');   # Should give a warning

print "$0 - test passed!\n";
