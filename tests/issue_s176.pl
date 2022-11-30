# issue s176 - References to variables with variable names including a package name are not properly translated
package s176;
use Carp::Assert;
no strict 'refs';

sub mysub { 0 }
sub mysub1 { 1 }

$pck = 's176';
$sym = 'mysub';
$sym1 = 'mysub1';

assert(&s176::mysub() == 0);
assert(&s176::mysub1() == 1);

$field = 1;
assert(${'field'} == 1);
my $f = 'field';
assert(${$f} == 1);
${$f} = 2;
assert($field == 2);

$first = 'a';
${"opt_$first"} = 1;

assert($opt_a == 1);


$callpack = $pck;
$def = $pck;
if(defined(&{"$pck\:\:$sym"})) {
    *{"${callpack}::$sym"} = \&{"$def::$sym1"};
} else {
    assert(0);
}

${$pck . '::' . $f} = 3;
assert($field == 3);

assert(&s176::mysub() == 1);
assert(&s176::mysub1() == 1);

sub exportHeavy
{
    my $type = shift;
    my $pkg = shift;
    my $sym = shift;
    my $sym1 = shift;

    my $callpkg = $pkg;
       *{"${callpkg}::$sym"} =
            $type eq '&' ? \&{"${pkg}::$sym1"} :
            $type eq '$' ? \${"${pkg}::$sym1"} :
            $type eq '@' ? \@{"${pkg}::$sym1"} :
            $type eq '%' ? \%{"${pkg}::$sym1"} :
            $type eq '*' ?  *{"${pkg}::$sym1"} :
            do { require Carp; Carp::croak("Can't export symbol: $type$sym1") };
}

$in = 1;
$jn = 2;
exportHeavy('$', 's176', 'in', 'jn');
assert($in == 2);
assert($jn == 2);

@a1 = (1,2);
@a2 = (3,4);
exportHeavy('@', 's176', 'a1', 'a2');
assert($a1[0] == 3);
assert($a1[1] == 4);

%h1 = (k1=>'v1');
%h2 = (k2=>'v2');
exportHeavy('%', 's176', 'h1', 'h2');
assert($h1{k2} eq 'v2');
assert(!exists $h1{k1});

# Check symbol table references
my $namespace = 'main';
assert(\%{"${namespace}::"} == \%::);
assert(\%{"${namespace}::"} == \%main::);
assert(\%main:: == \%main::);
assert(\%main:: == \%::);
assert(\%:: == \%::);

$namespace = '';
assert(\%{"${namespace}::"} == \%::);

$namespace = 's176';
assert(\%{"${namespace}::"} != \%::);
assert(\%{"${namespace}::"} == \%s176::);
use Math::Complex ();
assert(\%s176:: != \%Math::Complex::);

assert(exists $s176::{exportHeavy});
assert(!exists $::{exportHeavy});
assert(exists $Math::Complex::{cos});

print "$0 - test passed!\n";


