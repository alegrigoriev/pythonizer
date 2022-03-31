# issue - substr with ++ or -- generates bad code
# pragma pythonizer no implicit my
use Carp::Assert;

my $f_type = 'a:I';
my $t_pos = 1;
my $t = substr($f_type, --$t_pos, 1);
assert($t eq 'a');
assert($t_pos == 0);

$t = substr($f_type, ++$t_pos, 1);
assert($t eq ':');
assert($t_pos == 1);

$t = substr($f_type, $t_pos--, 1);
assert($t eq ':');
assert($t_pos == 0);

$t = substr($f_type, $t_pos++, 1);
assert($t eq 'a');
assert($t_pos == 1);

# Let's try something else!

$global = 1;

sub modGlobal {
    return $global++;
}

$t = substr($f_type, modGlobal(), 1);
assert($t eq ':');
assert($global == 2);

$t = substr($f_type, ($global = 1), 1);
assert($t eq ':');
assert($global == 1);

$t = substr($f_type, $global++, 1);
assert($t eq ':');
assert($global == 2);

@arr = ();
$t = substr($f_type, ++$arr[0], 1);
assert($t eq ':');
assert($arr[0] == 1);

$t = substr($f_type, $arr[0]++, 1);
assert($t eq ':');
assert($arr[0] == 2);



print "$0 - test passed!\n";
