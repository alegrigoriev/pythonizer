#!./perl

#
# Regression tests for the Math::Complex pacakge
# -- Raphael Manfredi	since Sep 1996
# -- Jarkko Hietaniemi	since Mar 1997
# -- Daniel S. Lewart	since Sep 1997

use strict;
use warnings;

use Math::Complex 1.54;

# they are used later in the test and not exported by Math::Complex
*_stringify_cartesian = \&Math::Complex::_stringify_cartesian;
*_stringify_polar     = \&Math::Complex::_stringify_polar;

#our $vax_float = (pack("d",1) =~ /^[\x80\x10]\x40/);
#our $has_inf   = !$vax_float;

my ($args, $op, $target, $test, $test_set, $try, $val, $zvalue, @set, @val);
my ($bad, $z);

$test = 0;
$| = 1;
#my @script = (
#    'my ($res, $s0,$s1,$s2,$s3,$s4,$s5,$s6,$s7,$s8,$s9,$s10,$z0,$z1,$z2);' .
#	"\n\n"
#);
my $eps = 1e-13;

if ($^O eq 'unicos') { 	# For some reason root() produces very inaccurate
    $eps = 1e-10;	# results in Cray UNICOS, and occasionally also
}			# cos(), sin(), cosh(), sinh().  The division
			# of doubles is the current suspect.

$test++;

open(OUT, '>', 'test_complex.out') or die "Can't open test_complex.out";

my ($res, $s0,$s1,$s2,$s3,$s4,$s5,$s6,$s7,$s8,$s9,$s10,$z0,$z1,$z2);

{ my $t=1; 
    my $a = Math::Complex->new(1);
    my $b = $a;
    $a += 2;
    print OUT "not " unless "$a" eq "3" && "$b" eq "1";
    print OUT "ok $t\n";
}$z0 = cplx(3,4);
$z1 = cplx(3,4);
$z2 = cplx(6,8);
$res = $z0 + $z1; check(2, '$z0 + $z1', $res, $z2, '(3,4)', '(3,4)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za += $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(3, '$z0 += $z1', $za, $z2, '(3,4)', '(3,4)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 4\n";
}
$z0 = cplx(-3,4);
$z1 = cplx(3,-4);
$z2 = cplx(0,0);
$res = $z0 + $z1; check(5, '$z0 + $z1', $res, $z2, '(-3,4)', '(3,-4)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za += $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(6, '$z0 += $z1', $za, $z2, '(-3,4)', '(3,-4)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 7\n";
}
$z0 = cplx(3,4);
$z1 = cplx(-3,0);
$z2 = cplx(0,4);
$res = $z0 + $z1; check(8, '$z0 + $z1', $res, $z2, '(3,4)', '-3');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za += $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(9, '$z0 += $z1', $za, $z2, '(3,4)', '-3');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 10\n";
}
$z0 = cplx(1,0);
$z1 = cplx(4,2);
$z2 = cplx(5,2);
$res = $z0 + $z1; check(11, '$z0 + $z1', $res, $z2, '1', '(4,2)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za += $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(12, '$z0 += $z1', $za, $z2, '1', '(4,2)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 13\n";
}
$z0 = cplxe(2,0);
$z1 = cplxe(2,pi);
$z2 = cplx(0,0);
$res = $z0 + $z1; check(14, '$z0 + $z1', $res, $z2, '[2,0]', '[2,pi]');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za += $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(15, '$z0 += $z1', $za, $z2, '[2,0]', '[2,pi]');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 16\n";
}
$z0 = cplx(2,1);
$z1 = cplx(3,1);
$res = ++ $z0; check(17, '++ $z0', $res, $z1, '(2,1)');
$z0 = cplx(2,3);
$z1 = cplx(-2,-3);
$res = - $z0; check(18, '- $z0', $res, $z1, '(2,3)');
$z0 = cplxe(2,pi/2);
$z1 = cplxe(2,-(pi)/2);
$res = - $z0; check(19, '- $z0', $res, $z1, '[2,pi/2]');
$z0 = cplx(2,0);
$z1 = cplxe(2,0);
$z2 = cplx(0,0);
$res = $z0 - $z1; check(20, '$z0 - $z1', $res, $z2, '2', '[2,0]');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za -= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(21, '$z0 -= $z1', $za, $z2, '2', '[2,0]');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 22\n";
}
$z0 = cplxe(3,0);
$z1 = cplx(2,0);
$z2 = cplx(1,0);
$res = $z0 - $z1; check(23, '$z0 - $z1', $res, $z2, '[3,0]', '2');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za -= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(24, '$z0 -= $z1', $za, $z2, '[3,0]', '2');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 25\n";
}
$z0 = cplx(3,0);
$z1 = cplx(4,5);
$z2 = cplx(-1,-5);
$res = $z0 - $z1; check(26, '$z0 - $z1', $res, $z2, '3', '(4,5)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za -= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(27, '$z0 -= $z1', $za, $z2, '3', '(4,5)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 28\n";
}
$z0 = cplx(4,5);
$z1 = cplx(3,0);
$z2 = cplx(1,5);
$res = $z0 - $z1; check(29, '$z0 - $z1', $res, $z2, '(4,5)', '3');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za -= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(30, '$z0 -= $z1', $za, $z2, '(4,5)', '3');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 31\n";
}
$z0 = cplx(2,1);
$z1 = cplx(3,5);
$z2 = cplx(-1,-4);
$res = $z0 - $z1; check(32, '$z0 - $z1', $res, $z2, '(2,1)', '(3,5)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za -= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(33, '$z0 -= $z1', $za, $z2, '(2,1)', '(3,5)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 34\n";
}
$z0 = cplx(1,2);
$z1 = cplx(0,2);
$res = -- $z0; check(35, '-- $z0', $res, $z1, '(1,2)');
$z0 = cplxe(2,pi);
$z1 = cplxe(3,pi);
$res = -- $z0; check(36, '-- $z0', $res, $z1, '[2,pi]');
$z0 = cplx(0,1);
$z1 = cplx(0,1);
$z2 = cplx(-1,0);
$res = $z0 * $z1; check(37, '$z0 * $z1', $res, $z2, '(0,1)', '(0,1)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za *= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(38, '$z0 *= $z1', $za, $z2, '(0,1)', '(0,1)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 39\n";
}
$z0 = cplx(4,5);
$z1 = cplx(1,0);
$z2 = cplx(4,5);
$res = $z0 * $z1; check(40, '$z0 * $z1', $res, $z2, '(4,5)', '(1,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za *= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(41, '$z0 *= $z1', $za, $z2, '(4,5)', '(1,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 42\n";
}
$z0 = cplxe(2,2*pi/3);
$z1 = cplx(1,0);
$z2 = cplxe(2,2*pi/3);
$res = $z0 * $z1; check(43, '$z0 * $z1', $res, $z2, '[2,2*pi/3]', '(1,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za *= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(44, '$z0 *= $z1', $za, $z2, '[2,2*pi/3]', '(1,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 45\n";
}
$z0 = cplx(2,0);
$z1 = cplx(0,1);
$z2 = cplx(0,2);
$res = $z0 * $z1; check(46, '$z0 * $z1', $res, $z2, '2', '(0,1)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za *= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(47, '$z0 *= $z1', $za, $z2, '2', '(0,1)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 48\n";
}
$z0 = cplx(0,1);
$z1 = cplx(3,0);
$z2 = cplx(0,3);
$res = $z0 * $z1; check(49, '$z0 * $z1', $res, $z2, '(0,1)', '3');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za *= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(50, '$z0 *= $z1', $za, $z2, '(0,1)', '3');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 51\n";
}
$z0 = cplx(0,1);
$z1 = cplx(4,1);
$z2 = cplx(-1,4);
$res = $z0 * $z1; check(52, '$z0 * $z1', $res, $z2, '(0,1)', '(4,1)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za *= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(53, '$z0 *= $z1', $za, $z2, '(0,1)', '(4,1)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 54\n";
}
$z0 = cplx(2,1);
$z1 = cplx(4,-1);
$z2 = cplx(9,2);
$res = $z0 * $z1; check(55, '$z0 * $z1', $res, $z2, '(2,1)', '(4,-1)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za *= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(56, '$z0 *= $z1', $za, $z2, '(2,1)', '(4,-1)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 57\n";
}
$z0 = cplx(3,4);
$z1 = cplx(3,4);
$z2 = cplx(1,0);
$res = $z0 / $z1; check(58, '$z0 / $z1', $res, $z2, '(3,4)', '(3,4)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za /= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(59, '$z0 /= $z1', $za, $z2, '(3,4)', '(3,4)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 60\n";
}
$z0 = cplx(4,-5);
$z1 = cplx(1,0);
$z2 = cplx(4,-5);
$res = $z0 / $z1; check(61, '$z0 / $z1', $res, $z2, '(4,-5)', '1');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za /= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(62, '$z0 /= $z1', $za, $z2, '(4,-5)', '1');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 63\n";
}
$z0 = cplx(1,0);
$z1 = cplx(0,1);
$z2 = cplx(0,-1);
$res = $z0 / $z1; check(64, '$z0 / $z1', $res, $z2, '1', '(0,1)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za /= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(65, '$z0 /= $z1', $za, $z2, '1', '(0,1)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 66\n";
}
$z0 = cplx(0,6);
$z1 = cplx(0,2);
$z2 = cplx(3,0);
$res = $z0 / $z1; check(67, '$z0 / $z1', $res, $z2, '(0,6)', '(0,2)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za /= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(68, '$z0 /= $z1', $za, $z2, '(0,6)', '(0,2)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 69\n";
}
$z0 = cplx(9,2);
$z1 = cplx(4,-1);
$z2 = cplx(2,1);
$res = $z0 / $z1; check(70, '$z0 / $z1', $res, $z2, '(9,2)', '(4,-1)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za /= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(71, '$z0 /= $z1', $za, $z2, '(9,2)', '(4,-1)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 72\n";
}
$z0 = cplxe(4,pi);
$z1 = cplxe(2,pi/2);
$z2 = cplxe(2,pi/2);
$res = $z0 / $z1; check(73, '$z0 / $z1', $res, $z2, '[4,pi]', '[2,pi/2]');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za /= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(74, '$z0 /= $z1', $za, $z2, '[4,pi]', '[2,pi/2]');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 75\n";
}
$z0 = cplxe(2,pi/2);
$z1 = cplxe(4,pi);
$z2 = cplxe(0.5,-(pi)/2);
$res = $z0 / $z1; check(76, '$z0 / $z1', $res, $z2, '[2,pi/2]', '[4,pi]');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za /= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(77, '$z0 /= $z1', $za, $z2, '[2,pi/2]', '[4,pi]');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 78\n";
}
$z0 = cplx(2,0);
$z1 = cplx(3,0);
$z2 = cplx(8,0);
$res = $z0 ** $z1; check(79, '$z0 ** $z1', $res, $z2, '(2,0)', '(3,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(80, '$z0 **= $z1', $za, $z2, '(2,0)', '(3,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 81\n";
}
$z0 = cplx(3,0);
$z1 = cplx(2,0);
$z2 = cplx(9,0);
$res = $z0 ** $z1; check(82, '$z0 ** $z1', $res, $z2, '(3,0)', '(2,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(83, '$z0 **= $z1', $za, $z2, '(3,0)', '(2,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 84\n";
}
$z0 = cplx(2,3);
$z1 = cplx(4,0);
$z2 = cplx(-119,-120);
$res = $z0 ** $z1; check(85, '$z0 ** $z1', $res, $z2, '(2,3)', '(4,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(86, '$z0 **= $z1', $za, $z2, '(2,3)', '(4,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 87\n";
}
$z0 = cplx(0,0);
$z1 = cplx(1,0);
$z2 = cplx(0,0);
$res = $z0 ** $z1; check(88, '$z0 ** $z1', $res, $z2, '(0,0)', '(1,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(89, '$z0 **= $z1', $za, $z2, '(0,0)', '(1,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 90\n";
}
$z0 = cplx(0,0);
$z1 = cplx(2,3);
$z2 = cplx(0,0);
$res = $z0 ** $z1; check(91, '$z0 ** $z1', $res, $z2, '(0,0)', '(2,3)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(92, '$z0 **= $z1', $za, $z2, '(0,0)', '(2,3)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 93\n";
}
$z0 = cplx(1,0);
$z1 = cplx(0,0);
$z2 = cplx(1,0);
$res = $z0 ** $z1; check(94, '$z0 ** $z1', $res, $z2, '(1,0)', '(0,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(95, '$z0 **= $z1', $za, $z2, '(1,0)', '(0,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 96\n";
}
$z0 = cplx(1,0);
$z1 = cplx(1,0);
$z2 = cplx(1,0);
$res = $z0 ** $z1; check(97, '$z0 ** $z1', $res, $z2, '(1,0)', '(1,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(98, '$z0 **= $z1', $za, $z2, '(1,0)', '(1,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 99\n";
}
$z0 = cplx(1,0);
$z1 = cplx(2,3);
$z2 = cplx(1,0);
$res = $z0 ** $z1; check(100, '$z0 ** $z1', $res, $z2, '(1,0)', '(2,3)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(101, '$z0 **= $z1', $za, $z2, '(1,0)', '(2,3)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 102\n";
}
$z0 = cplx(2,3);
$z1 = cplx(0,0);
$z2 = cplx(1,0);
$res = $z0 ** $z1; check(103, '$z0 ** $z1', $res, $z2, '(2,3)', '(0,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(104, '$z0 **= $z1', $za, $z2, '(2,3)', '(0,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 105\n";
}
$z0 = cplx(2,3);
$z1 = cplx(1,0);
$z2 = cplx(2,3);
$res = $z0 ** $z1; check(106, '$z0 ** $z1', $res, $z2, '(2,3)', '(1,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(107, '$z0 **= $z1', $za, $z2, '(2,3)', '(1,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 108\n";
}
$z0 = cplx(0,0);
$z1 = cplx(0,0);
$z2 = cplx(1,0);
$res = $z0 ** $z1; check(109, '$z0 ** $z1', $res, $z2, '(0,0)', '(0,0)');
{
	my $za = cplx(ref $z0 ? @{$z0->_cartesian} : ($z0, 0));

	my ($z1r, $z1i) = ref $z1 ? @{$z1->_cartesian} : ($z1, 0);

	my $zb = cplx($z1r, $z1i);

	$za **= $zb;
	my ($zbr, $zbi) = @{$zb->_cartesian};

	check(110, '$z0 **= $z1', $za, $z2, '(0,0)', '(0,0)');
print OUT "not " unless ($zbr == $z1r and $zbi == $z1i);print OUT "ok 111\n";
}
$z0 = cplx(3,4);
$z1 = cplx(3,0);
$res = Re $z0; check(112, 'Re $z0', $res, $z1, '(3,4)');
$z0 = cplx(-3,4);
$z1 = cplx(-3,0);
$res = Re $z0; check(113, 'Re $z0', $res, $z1, '(-3,4)');
$z0 = cplxe(1,pi/2);
$z1 = cplx(0,0);
$res = Re $z0; check(114, 'Re $z0', $res, $z1, '[1,pi/2]');
$z0 = cplx(3,4);
$z1 = cplx(4,0);
$res = Im $z0; check(115, 'Im $z0', $res, $z1, '(3,4)');
$z0 = cplx(3,-4);
$z1 = cplx(-4,0);
$res = Im $z0; check(116, 'Im $z0', $res, $z1, '(3,-4)');
$z0 = cplxe(1,pi/2);
$z1 = cplx(1,0);
$res = Im $z0; check(117, 'Im $z0', $res, $z1, '[1,pi/2]');
$z0 = cplx(3,4);
$z1 = cplx(5,0);
$res = abs $z0; check(118, 'abs $z0', $res, $z1, '(3,4)');
$z0 = cplx(-3,4);
$z1 = cplx(5,0);
$res = abs $z0; check(119, 'abs $z0', $res, $z1, '(-3,4)');
$z0 = cplxe(2,0);
$z1 = cplx(0,0);
$res = arg $z0; check(120, 'arg $z0', $res, $z1, '[2,0]');
$z0 = cplxe(-2,0);
$z1 = pi;
$res = arg $z0; check(121, 'arg $z0', $res, $z1, '[-2,0]');
$z0 = cplx(4,5);
$z1 = cplx(4,-5);
$res = ~ $z0; check(122, '~ $z0', $res, $z1, '(4,5)');
$z0 = cplx(-3,4);
$z1 = cplx(-3,-4);
$res = ~ $z0; check(123, '~ $z0', $res, $z1, '(-3,4)');
$z0 = cplxe(2,pi/2);
$z1 = cplxe(2,-(pi)/2);
$res = ~ $z0; check(124, '~ $z0', $res, $z1, '[2,pi/2]');
$z0 = cplx(3,4);
$z1 = cplx(1,2);
$z2 = cplx(0,0);
$res = $z0 < $z1; check(125, '$z0 < $z1', $res, $z2, '(3,4)', '(1,2)');
$z0 = cplx(3,4);
$z1 = cplx(3,2);
$z2 = cplx(0,0);
$res = $z0 < $z1; check(126, '$z0 < $z1', $res, $z2, '(3,4)', '(3,2)');
$z0 = cplx(3,4);
$z1 = cplx(3,8);
$z2 = cplx(1,0);
$res = $z0 < $z1; check(127, '$z0 < $z1', $res, $z2, '(3,4)', '(3,8)');
$z0 = cplx(4,4);
$z1 = cplx(5,129);
$z2 = cplx(1,0);
$res = $z0 < $z1; check(128, '$z0 < $z1', $res, $z2, '(4,4)', '(5,129)');
$z0 = cplx(3,4);
$z1 = cplx(4,5);
$z2 = cplx(0,0);
$res = $z0 == $z1; check(129, '$z0 == $z1', $res, $z2, '(3,4)', '(4,5)');
$z0 = cplx(3,4);
$z1 = cplx(3,5);
$z2 = cplx(0,0);
$res = $z0 == $z1; check(130, '$z0 == $z1', $res, $z2, '(3,4)', '(3,5)');
$z0 = cplx(3,4);
$z1 = cplx(2,4);
$z2 = cplx(0,0);
$res = $z0 == $z1; check(131, '$z0 == $z1', $res, $z2, '(3,4)', '(2,4)');
$z0 = cplx(3,4);
$z1 = cplx(3,4);
$z2 = cplx(1,0);
$res = $z0 == $z1; check(132, '$z0 == $z1', $res, $z2, '(3,4)', '(3,4)');
$z0 = cplx(-9,0);
$z1 = cplx(0,3);
$res = sqrt $z0; check(133, 'sqrt $z0', $res, $z1, '-9');
$z0 = cplx(-100,0);
$z1 = cplx(0,10);
$res = sqrt $z0; check(134, 'sqrt $z0', $res, $z1, '(-100,0)');
$z0 = cplx(16,-30);
$z1 = cplx(5,-3);
$res = sqrt $z0; check(135, 'sqrt $z0', $res, $z1, '(16,-30)');
$z0 = cplx(-100,0);
$z1 = "-100";
$res = _stringify_cartesian $z0; check(136, '_stringify_cartesian $z0', $res, $z1, '(-100,0)');
$z0 = cplx(0,1);
$z1 = "i";
$res = _stringify_cartesian $z0; check(137, '_stringify_cartesian $z0', $res, $z1, '(0,1)');
$z0 = cplx(4,-3);
$z1 = "4-3i";
$res = _stringify_cartesian $z0; check(138, '_stringify_cartesian $z0', $res, $z1, '(4,-3)');
$z0 = cplx(4,0);
$z1 = "4";
$res = _stringify_cartesian $z0; check(139, '_stringify_cartesian $z0', $res, $z1, '(4,0)');
$z0 = cplx(-4,0);
$z1 = "-4";
$res = _stringify_cartesian $z0; check(140, '_stringify_cartesian $z0', $res, $z1, '(-4,0)');
$z0 = cplx(-2,4);
$z1 = "-2+4i";
$res = _stringify_cartesian $z0; check(141, '_stringify_cartesian $z0', $res, $z1, '(-2,4)');
$z0 = cplx(-2,-1);
$z1 = "-2-i";
$res = _stringify_cartesian $z0; check(142, '_stringify_cartesian $z0', $res, $z1, '(-2,-1)');
$z0 = cplxe(-1, 0);
$z1 = "[1,pi]";
$res = _stringify_polar $z0; check(143, '_stringify_polar $z0', $res, $z1, '[-1, 0]');
$z0 = cplxe(1, pi/3);
$z1 = "[1,pi/3]";
$res = _stringify_polar $z0; check(144, '_stringify_polar $z0', $res, $z1, '[1, pi/3]');
$z0 = cplxe(6, -2*pi/3);
$z1 = "[6,-2pi/3]";
$res = _stringify_polar $z0; check(145, '_stringify_polar $z0', $res, $z1, '[6, -2*pi/3]');
$z0 = cplxe(0.5, -9*pi/11);
$z1 = "[0.5,-9pi/11]";
$res = _stringify_polar $z0; check(146, '_stringify_polar $z0', $res, $z1, '[0.5, -9*pi/11]');
$z0 = cplxe(1, 0.5);
$z1 = "[1, 0.5]";
$res = _stringify_polar $z0; check(147, '_stringify_polar $z0', $res, $z1, '[1, 0.5]');
$s0 = cplx(4,3);
$s1 = cplxe(3,2);
$s2 = cplx(-3,4);
$s3 = cplx(0,2);
$s4 = cplxe(2,1);
$z0 = $s0 + ~$s0;
$z1 = 2*Re($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(148, 'z + ~z', $res, $z1, ' (4,3)');
$z0 = $s1 + ~$s1;
$z1 = 2*Re($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(149, 'z + ~z', $res, $z1, '[3,2]');
$z0 = $s2 + ~$s2;
$z1 = 2*Re($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(150, 'z + ~z', $res, $z1, '(-3,4)');
$z0 = $s3 + ~$s3;
$z1 = 2*Re($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(151, 'z + ~z', $res, $z1, '(0,2)');
$z0 = $s4 + ~$s4;
$z1 = 2*Re($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(152, 'z + ~z', $res, $z1, '[2,1] ');
$z0 = $s0 - ~$s0;
$z1 = 2*i*Im($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(153, 'z - ~z', $res, $z1, ' (4,3)');
$z0 = $s1 - ~$s1;
$z1 = 2*i*Im($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(154, 'z - ~z', $res, $z1, '[3,2]');
$z0 = $s2 - ~$s2;
$z1 = 2*i*Im($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(155, 'z - ~z', $res, $z1, '(-3,4)');
$z0 = $s3 - ~$s3;
$z1 = 2*i*Im($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(156, 'z - ~z', $res, $z1, '(0,2)');
$z0 = $s4 - ~$s4;
$z1 = 2*i*Im($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(157, 'z - ~z', $res, $z1, '[2,1] ');
$z0 = $s0 * ~$s0;
$z1 = abs($s0) * abs($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(158, 'z * ~z', $res, $z1, ' (4,3)');
$z0 = $s1 * ~$s1;
$z1 = abs($s1) * abs($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(159, 'z * ~z', $res, $z1, '[3,2]');
$z0 = $s2 * ~$s2;
$z1 = abs($s2) * abs($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(160, 'z * ~z', $res, $z1, '(-3,4)');
$z0 = $s3 * ~$s3;
$z1 = abs($s3) * abs($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(161, 'z * ~z', $res, $z1, '(0,2)');
$z0 = $s4 * ~$s4;
$z1 = abs($s4) * abs($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(162, 'z * ~z', $res, $z1, '[2,1] ');
$s0 = cplx(0.5, 0);
$s1 = cplx(-0.5, 0);
$s2 = cplx(2,3);
$s3 = cplxe(3,2);
$s4 = cplx(-3,2);
$s5 = cplx(0,2);
$s6 = cplx(3,0);
$s7 = cplx(1.2,0);
$s8 = cplx(-3, 0);
$s9 = cplx(-2, -1);
$s10 = cplxe(2,1);
$z0 = (root($s0, 4))[1] ** 4;
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(163, '(root(z, 4))[1] ** 4', $res, $z1, ' (0.5, 0)');
$z0 = (root($s1, 4))[1] ** 4;
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(164, '(root(z, 4))[1] ** 4', $res, $z1, '(-0.5, 0)');
$z0 = (root($s2, 4))[1] ** 4;
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(165, '(root(z, 4))[1] ** 4', $res, $z1, '(2,3)');
$z0 = (root($s3, 4))[1] ** 4;
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(166, '(root(z, 4))[1] ** 4', $res, $z1, '[3,2]');
$z0 = (root($s4, 4))[1] ** 4;
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(167, '(root(z, 4))[1] ** 4', $res, $z1, '(-3,2)');
$z0 = (root($s5, 4))[1] ** 4;
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(168, '(root(z, 4))[1] ** 4', $res, $z1, '(0,2)');
$z0 = (root($s6, 4))[1] ** 4;
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(169, '(root(z, 4))[1] ** 4', $res, $z1, '3');
$z0 = (root($s7, 4))[1] ** 4;
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(170, '(root(z, 4))[1] ** 4', $res, $z1, '1.2');
$z0 = (root($s8, 4))[1] ** 4;
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(171, '(root(z, 4))[1] ** 4', $res, $z1, '(-3, 0)');
$z0 = (root($s9, 4))[1] ** 4;
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(172, '(root(z, 4))[1] ** 4', $res, $z1, '(-2, -1)');
$z0 = (root($s10, 4))[1] ** 4;
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(173, '(root(z, 4))[1] ** 4', $res, $z1, '[2,1] ');
$z0 = (root($s0, 5))[3] ** 5;
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(174, '(root(z, 5))[3] ** 5', $res, $z1, ' (0.5, 0)');
$z0 = (root($s1, 5))[3] ** 5;
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(175, '(root(z, 5))[3] ** 5', $res, $z1, '(-0.5, 0)');
$z0 = (root($s2, 5))[3] ** 5;
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(176, '(root(z, 5))[3] ** 5', $res, $z1, '(2,3)');
$z0 = (root($s3, 5))[3] ** 5;
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(177, '(root(z, 5))[3] ** 5', $res, $z1, '[3,2]');
$z0 = (root($s4, 5))[3] ** 5;
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(178, '(root(z, 5))[3] ** 5', $res, $z1, '(-3,2)');
$z0 = (root($s5, 5))[3] ** 5;
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(179, '(root(z, 5))[3] ** 5', $res, $z1, '(0,2)');
$z0 = (root($s6, 5))[3] ** 5;
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(180, '(root(z, 5))[3] ** 5', $res, $z1, '3');
$z0 = (root($s7, 5))[3] ** 5;
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(181, '(root(z, 5))[3] ** 5', $res, $z1, '1.2');
$z0 = (root($s8, 5))[3] ** 5;
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(182, '(root(z, 5))[3] ** 5', $res, $z1, '(-3, 0)');
$z0 = (root($s9, 5))[3] ** 5;
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(183, '(root(z, 5))[3] ** 5', $res, $z1, '(-2, -1)');
$z0 = (root($s10, 5))[3] ** 5;
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(184, '(root(z, 5))[3] ** 5', $res, $z1, '[2,1] ');
$z0 = (root($s0, 8))[7] ** 8;
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(185, '(root(z, 8))[7] ** 8', $res, $z1, ' (0.5, 0)');
$z0 = (root($s1, 8))[7] ** 8;
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(186, '(root(z, 8))[7] ** 8', $res, $z1, '(-0.5, 0)');
$z0 = (root($s2, 8))[7] ** 8;
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(187, '(root(z, 8))[7] ** 8', $res, $z1, '(2,3)');
$z0 = (root($s3, 8))[7] ** 8;
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(188, '(root(z, 8))[7] ** 8', $res, $z1, '[3,2]');
$z0 = (root($s4, 8))[7] ** 8;
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(189, '(root(z, 8))[7] ** 8', $res, $z1, '(-3,2)');
$z0 = (root($s5, 8))[7] ** 8;
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(190, '(root(z, 8))[7] ** 8', $res, $z1, '(0,2)');
$z0 = (root($s6, 8))[7] ** 8;
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(191, '(root(z, 8))[7] ** 8', $res, $z1, '3');
$z0 = (root($s7, 8))[7] ** 8;
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(192, '(root(z, 8))[7] ** 8', $res, $z1, '1.2');
$z0 = (root($s8, 8))[7] ** 8;
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(193, '(root(z, 8))[7] ** 8', $res, $z1, '(-3, 0)');
$z0 = (root($s9, 8))[7] ** 8;
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(194, '(root(z, 8))[7] ** 8', $res, $z1, '(-2, -1)');
$z0 = (root($s10, 8))[7] ** 8;
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(195, '(root(z, 8))[7] ** 8', $res, $z1, '[2,1] ');
$z0 = (root($s0, 8, 0)) ** 8;
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(196, '(root(z, 8, 0)) ** 8', $res, $z1, ' (0.5, 0)');
$z0 = (root($s1, 8, 0)) ** 8;
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(197, '(root(z, 8, 0)) ** 8', $res, $z1, '(-0.5, 0)');
$z0 = (root($s2, 8, 0)) ** 8;
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(198, '(root(z, 8, 0)) ** 8', $res, $z1, '(2,3)');
$z0 = (root($s3, 8, 0)) ** 8;
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(199, '(root(z, 8, 0)) ** 8', $res, $z1, '[3,2]');
$z0 = (root($s4, 8, 0)) ** 8;
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(200, '(root(z, 8, 0)) ** 8', $res, $z1, '(-3,2)');
$z0 = (root($s5, 8, 0)) ** 8;
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(201, '(root(z, 8, 0)) ** 8', $res, $z1, '(0,2)');
$z0 = (root($s6, 8, 0)) ** 8;
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(202, '(root(z, 8, 0)) ** 8', $res, $z1, '3');
$z0 = (root($s7, 8, 0)) ** 8;
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(203, '(root(z, 8, 0)) ** 8', $res, $z1, '1.2');
$z0 = (root($s8, 8, 0)) ** 8;
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(204, '(root(z, 8, 0)) ** 8', $res, $z1, '(-3, 0)');
$z0 = (root($s9, 8, 0)) ** 8;
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(205, '(root(z, 8, 0)) ** 8', $res, $z1, '(-2, -1)');
$z0 = (root($s10, 8, 0)) ** 8;
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(206, '(root(z, 8, 0)) ** 8', $res, $z1, '[2,1] ');
$z0 = (root($s0, 8, 7)) ** 8;
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(207, '(root(z, 8, 7)) ** 8', $res, $z1, ' (0.5, 0)');
$z0 = (root($s1, 8, 7)) ** 8;
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(208, '(root(z, 8, 7)) ** 8', $res, $z1, '(-0.5, 0)');
$z0 = (root($s2, 8, 7)) ** 8;
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(209, '(root(z, 8, 7)) ** 8', $res, $z1, '(2,3)');
$z0 = (root($s3, 8, 7)) ** 8;
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(210, '(root(z, 8, 7)) ** 8', $res, $z1, '[3,2]');
$z0 = (root($s4, 8, 7)) ** 8;
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(211, '(root(z, 8, 7)) ** 8', $res, $z1, '(-3,2)');
$z0 = (root($s5, 8, 7)) ** 8;
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(212, '(root(z, 8, 7)) ** 8', $res, $z1, '(0,2)');
$z0 = (root($s6, 8, 7)) ** 8;
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(213, '(root(z, 8, 7)) ** 8', $res, $z1, '3');
$z0 = (root($s7, 8, 7)) ** 8;
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(214, '(root(z, 8, 7)) ** 8', $res, $z1, '1.2');
$z0 = (root($s8, 8, 7)) ** 8;
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(215, '(root(z, 8, 7)) ** 8', $res, $z1, '(-3, 0)');
$z0 = (root($s9, 8, 7)) ** 8;
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(216, '(root(z, 8, 7)) ** 8', $res, $z1, '(-2, -1)');
$z0 = (root($s10, 8, 7)) ** 8;
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(217, '(root(z, 8, 7)) ** 8', $res, $z1, '[2,1] ');
$z0 = abs($s0);
$z1 = abs($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(218, 'abs(z)', $res, $z1, ' (0.5, 0)');
$z0 = abs($s1);
$z1 = abs($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(219, 'abs(z)', $res, $z1, '(-0.5, 0)');
$z0 = abs($s2);
$z1 = abs($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(220, 'abs(z)', $res, $z1, '(2,3)');
$z0 = abs($s3);
$z1 = abs($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(221, 'abs(z)', $res, $z1, '[3,2]');
$z0 = abs($s4);
$z1 = abs($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(222, 'abs(z)', $res, $z1, '(-3,2)');
$z0 = abs($s5);
$z1 = abs($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(223, 'abs(z)', $res, $z1, '(0,2)');
$z0 = abs($s6);
$z1 = abs($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(224, 'abs(z)', $res, $z1, '3');
$z0 = abs($s7);
$z1 = abs($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(225, 'abs(z)', $res, $z1, '1.2');
$z0 = abs($s8);
$z1 = abs($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(226, 'abs(z)', $res, $z1, '(-3, 0)');
$z0 = abs($s9);
$z1 = abs($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(227, 'abs(z)', $res, $z1, '(-2, -1)');
$z0 = abs($s10);
$z1 = abs($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(228, 'abs(z)', $res, $z1, '[2,1] ');
$z0 = acot($s0);
$z1 = acotan($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(229, 'acot(z)', $res, $z1, ' (0.5, 0)');
$z0 = acot($s1);
$z1 = acotan($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(230, 'acot(z)', $res, $z1, '(-0.5, 0)');
$z0 = acot($s2);
$z1 = acotan($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(231, 'acot(z)', $res, $z1, '(2,3)');
$z0 = acot($s3);
$z1 = acotan($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(232, 'acot(z)', $res, $z1, '[3,2]');
$z0 = acot($s4);
$z1 = acotan($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(233, 'acot(z)', $res, $z1, '(-3,2)');
$z0 = acot($s5);
$z1 = acotan($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(234, 'acot(z)', $res, $z1, '(0,2)');
$z0 = acot($s6);
$z1 = acotan($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(235, 'acot(z)', $res, $z1, '3');
$z0 = acot($s7);
$z1 = acotan($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(236, 'acot(z)', $res, $z1, '1.2');
$z0 = acot($s8);
$z1 = acotan($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(237, 'acot(z)', $res, $z1, '(-3, 0)');
$z0 = acot($s9);
$z1 = acotan($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(238, 'acot(z)', $res, $z1, '(-2, -1)');
$z0 = acot($s10);
$z1 = acotan($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(239, 'acot(z)', $res, $z1, '[2,1] ');
$z0 = acsc($s0);
$z1 = acosec($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(240, 'acsc(z)', $res, $z1, ' (0.5, 0)');
$z0 = acsc($s1);
$z1 = acosec($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(241, 'acsc(z)', $res, $z1, '(-0.5, 0)');
$z0 = acsc($s2);
$z1 = acosec($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(242, 'acsc(z)', $res, $z1, '(2,3)');
$z0 = acsc($s3);
$z1 = acosec($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(243, 'acsc(z)', $res, $z1, '[3,2]');
$z0 = acsc($s4);
$z1 = acosec($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(244, 'acsc(z)', $res, $z1, '(-3,2)');
$z0 = acsc($s5);
$z1 = acosec($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(245, 'acsc(z)', $res, $z1, '(0,2)');
$z0 = acsc($s6);
$z1 = acosec($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(246, 'acsc(z)', $res, $z1, '3');
$z0 = acsc($s7);
$z1 = acosec($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(247, 'acsc(z)', $res, $z1, '1.2');
$z0 = acsc($s8);
$z1 = acosec($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(248, 'acsc(z)', $res, $z1, '(-3, 0)');
$z0 = acsc($s9);
$z1 = acosec($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(249, 'acsc(z)', $res, $z1, '(-2, -1)');
$z0 = acsc($s10);
$z1 = acosec($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(250, 'acsc(z)', $res, $z1, '[2,1] ');
$z0 = acsc($s0);
$z1 = asin(1 / $s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(251, 'acsc(z)', $res, $z1, ' (0.5, 0)');
$z0 = acsc($s1);
$z1 = asin(1 / $s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(252, 'acsc(z)', $res, $z1, '(-0.5, 0)');
$z0 = acsc($s2);
$z1 = asin(1 / $s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(253, 'acsc(z)', $res, $z1, '(2,3)');
$z0 = acsc($s3);
$z1 = asin(1 / $s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(254, 'acsc(z)', $res, $z1, '[3,2]');
$z0 = acsc($s4);
$z1 = asin(1 / $s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(255, 'acsc(z)', $res, $z1, '(-3,2)');
$z0 = acsc($s5);
$z1 = asin(1 / $s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(256, 'acsc(z)', $res, $z1, '(0,2)');
$z0 = acsc($s6);
$z1 = asin(1 / $s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(257, 'acsc(z)', $res, $z1, '3');
$z0 = acsc($s7);
$z1 = asin(1 / $s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(258, 'acsc(z)', $res, $z1, '1.2');
$z0 = acsc($s8);
$z1 = asin(1 / $s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(259, 'acsc(z)', $res, $z1, '(-3, 0)');
$z0 = acsc($s9);
$z1 = asin(1 / $s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(260, 'acsc(z)', $res, $z1, '(-2, -1)');
$z0 = acsc($s10);
$z1 = asin(1 / $s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(261, 'acsc(z)', $res, $z1, '[2,1] ');
$z0 = asec($s0);
$z1 = acos(1 / $s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(262, 'asec(z)', $res, $z1, ' (0.5, 0)');
$z0 = asec($s1);
$z1 = acos(1 / $s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(263, 'asec(z)', $res, $z1, '(-0.5, 0)');
$z0 = asec($s2);
$z1 = acos(1 / $s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(264, 'asec(z)', $res, $z1, '(2,3)');
$z0 = asec($s3);
$z1 = acos(1 / $s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(265, 'asec(z)', $res, $z1, '[3,2]');
$z0 = asec($s4);
$z1 = acos(1 / $s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(266, 'asec(z)', $res, $z1, '(-3,2)');
$z0 = asec($s5);
$z1 = acos(1 / $s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(267, 'asec(z)', $res, $z1, '(0,2)');
$z0 = asec($s6);
$z1 = acos(1 / $s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(268, 'asec(z)', $res, $z1, '3');
$z0 = asec($s7);
$z1 = acos(1 / $s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(269, 'asec(z)', $res, $z1, '1.2');
$z0 = asec($s8);
$z1 = acos(1 / $s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(270, 'asec(z)', $res, $z1, '(-3, 0)');
$z0 = asec($s9);
$z1 = acos(1 / $s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(271, 'asec(z)', $res, $z1, '(-2, -1)');
$z0 = asec($s10);
$z1 = acos(1 / $s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(272, 'asec(z)', $res, $z1, '[2,1] ');
$z0 = cbrt($s0);
$z1 = cbrt(abs($s0)) * exp(i * arg($s0)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(273, 'cbrt(z)', $res, $z1, ' (0.5, 0)');
$z0 = cbrt($s1);
$z1 = cbrt(abs($s1)) * exp(i * arg($s1)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(274, 'cbrt(z)', $res, $z1, '(-0.5, 0)');
$z0 = cbrt($s2);
$z1 = cbrt(abs($s2)) * exp(i * arg($s2)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(275, 'cbrt(z)', $res, $z1, '(2,3)');
$z0 = cbrt($s3);
$z1 = cbrt(abs($s3)) * exp(i * arg($s3)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(276, 'cbrt(z)', $res, $z1, '[3,2]');
$z0 = cbrt($s4);
$z1 = cbrt(abs($s4)) * exp(i * arg($s4)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(277, 'cbrt(z)', $res, $z1, '(-3,2)');
$z0 = cbrt($s5);
$z1 = cbrt(abs($s5)) * exp(i * arg($s5)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(278, 'cbrt(z)', $res, $z1, '(0,2)');
$z0 = cbrt($s6);
$z1 = cbrt(abs($s6)) * exp(i * arg($s6)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(279, 'cbrt(z)', $res, $z1, '3');
$z0 = cbrt($s7);
$z1 = cbrt(abs($s7)) * exp(i * arg($s7)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(280, 'cbrt(z)', $res, $z1, '1.2');
$z0 = cbrt($s8);
$z1 = cbrt(abs($s8)) * exp(i * arg($s8)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(281, 'cbrt(z)', $res, $z1, '(-3, 0)');
$z0 = cbrt($s9);
$z1 = cbrt(abs($s9)) * exp(i * arg($s9)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(282, 'cbrt(z)', $res, $z1, '(-2, -1)');
$z0 = cbrt($s10);
$z1 = cbrt(abs($s10)) * exp(i * arg($s10)/3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(283, 'cbrt(z)', $res, $z1, '[2,1] ');
$z0 = cos(acos($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(284, 'cos(acos(z))', $res, $z1, ' (0.5, 0)');
$z0 = cos(acos($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(285, 'cos(acos(z))', $res, $z1, '(-0.5, 0)');
$z0 = cos(acos($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(286, 'cos(acos(z))', $res, $z1, '(2,3)');
$z0 = cos(acos($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(287, 'cos(acos(z))', $res, $z1, '[3,2]');
$z0 = cos(acos($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(288, 'cos(acos(z))', $res, $z1, '(-3,2)');
$z0 = cos(acos($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(289, 'cos(acos(z))', $res, $z1, '(0,2)');
$z0 = cos(acos($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(290, 'cos(acos(z))', $res, $z1, '3');
$z0 = cos(acos($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(291, 'cos(acos(z))', $res, $z1, '1.2');
$z0 = cos(acos($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(292, 'cos(acos(z))', $res, $z1, '(-3, 0)');
$z0 = cos(acos($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(293, 'cos(acos(z))', $res, $z1, '(-2, -1)');
$z0 = cos(acos($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(294, 'cos(acos(z))', $res, $z1, '[2,1] ');
$z0 = addsq(cos($s0), sin($s0));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(295, 'addsq(cos(z), sin(z))', $res, $z1, ' (0.5, 0)');
$z0 = addsq(cos($s1), sin($s1));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(296, 'addsq(cos(z), sin(z))', $res, $z1, '(-0.5, 0)');
$z0 = addsq(cos($s2), sin($s2));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(297, 'addsq(cos(z), sin(z))', $res, $z1, '(2,3)');
$z0 = addsq(cos($s3), sin($s3));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(298, 'addsq(cos(z), sin(z))', $res, $z1, '[3,2]');
$z0 = addsq(cos($s4), sin($s4));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(299, 'addsq(cos(z), sin(z))', $res, $z1, '(-3,2)');
$z0 = addsq(cos($s5), sin($s5));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(300, 'addsq(cos(z), sin(z))', $res, $z1, '(0,2)');
$z0 = addsq(cos($s6), sin($s6));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(301, 'addsq(cos(z), sin(z))', $res, $z1, '3');
$z0 = addsq(cos($s7), sin($s7));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(302, 'addsq(cos(z), sin(z))', $res, $z1, '1.2');
$z0 = addsq(cos($s8), sin($s8));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(303, 'addsq(cos(z), sin(z))', $res, $z1, '(-3, 0)');
$z0 = addsq(cos($s9), sin($s9));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(304, 'addsq(cos(z), sin(z))', $res, $z1, '(-2, -1)');
$z0 = addsq(cos($s10), sin($s10));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(305, 'addsq(cos(z), sin(z))', $res, $z1, '[2,1] ');
$z0 = cos($s0);
$z1 = cosh(i*$s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(306, 'cos(z)', $res, $z1, ' (0.5, 0)');
$z0 = cos($s1);
$z1 = cosh(i*$s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(307, 'cos(z)', $res, $z1, '(-0.5, 0)');
$z0 = cos($s2);
$z1 = cosh(i*$s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(308, 'cos(z)', $res, $z1, '(2,3)');
$z0 = cos($s3);
$z1 = cosh(i*$s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(309, 'cos(z)', $res, $z1, '[3,2]');
$z0 = cos($s4);
$z1 = cosh(i*$s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(310, 'cos(z)', $res, $z1, '(-3,2)');
$z0 = cos($s5);
$z1 = cosh(i*$s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(311, 'cos(z)', $res, $z1, '(0,2)');
$z0 = cos($s6);
$z1 = cosh(i*$s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(312, 'cos(z)', $res, $z1, '3');
$z0 = cos($s7);
$z1 = cosh(i*$s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(313, 'cos(z)', $res, $z1, '1.2');
$z0 = cos($s8);
$z1 = cosh(i*$s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(314, 'cos(z)', $res, $z1, '(-3, 0)');
$z0 = cos($s9);
$z1 = cosh(i*$s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(315, 'cos(z)', $res, $z1, '(-2, -1)');
$z0 = cos($s10);
$z1 = cosh(i*$s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(316, 'cos(z)', $res, $z1, '[2,1] ');
$z0 = subsq(cosh($s0), sinh($s0));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(317, 'subsq(cosh(z), sinh(z))', $res, $z1, ' (0.5, 0)');
$z0 = subsq(cosh($s1), sinh($s1));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(318, 'subsq(cosh(z), sinh(z))', $res, $z1, '(-0.5, 0)');
$z0 = subsq(cosh($s2), sinh($s2));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(319, 'subsq(cosh(z), sinh(z))', $res, $z1, '(2,3)');
$z0 = subsq(cosh($s3), sinh($s3));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(320, 'subsq(cosh(z), sinh(z))', $res, $z1, '[3,2]');
$z0 = subsq(cosh($s4), sinh($s4));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(321, 'subsq(cosh(z), sinh(z))', $res, $z1, '(-3,2)');
$z0 = subsq(cosh($s5), sinh($s5));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(322, 'subsq(cosh(z), sinh(z))', $res, $z1, '(0,2)');
$z0 = subsq(cosh($s6), sinh($s6));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(323, 'subsq(cosh(z), sinh(z))', $res, $z1, '3');
$z0 = subsq(cosh($s7), sinh($s7));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(324, 'subsq(cosh(z), sinh(z))', $res, $z1, '1.2');
$z0 = subsq(cosh($s8), sinh($s8));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(325, 'subsq(cosh(z), sinh(z))', $res, $z1, '(-3, 0)');
$z0 = subsq(cosh($s9), sinh($s9));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(326, 'subsq(cosh(z), sinh(z))', $res, $z1, '(-2, -1)');
$z0 = subsq(cosh($s10), sinh($s10));
$z1 = cplx(1,0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(327, 'subsq(cosh(z), sinh(z))', $res, $z1, '[2,1] ');
$z0 = cot(acot($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(328, 'cot(acot(z))', $res, $z1, ' (0.5, 0)');
$z0 = cot(acot($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(329, 'cot(acot(z))', $res, $z1, '(-0.5, 0)');
$z0 = cot(acot($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(330, 'cot(acot(z))', $res, $z1, '(2,3)');
$z0 = cot(acot($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(331, 'cot(acot(z))', $res, $z1, '[3,2]');
$z0 = cot(acot($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(332, 'cot(acot(z))', $res, $z1, '(-3,2)');
$z0 = cot(acot($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(333, 'cot(acot(z))', $res, $z1, '(0,2)');
$z0 = cot(acot($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(334, 'cot(acot(z))', $res, $z1, '3');
$z0 = cot(acot($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(335, 'cot(acot(z))', $res, $z1, '1.2');
$z0 = cot(acot($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(336, 'cot(acot(z))', $res, $z1, '(-3, 0)');
$z0 = cot(acot($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(337, 'cot(acot(z))', $res, $z1, '(-2, -1)');
$z0 = cot(acot($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(338, 'cot(acot(z))', $res, $z1, '[2,1] ');
$z0 = cot($s0);
$z1 = 1 / tan($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(339, 'cot(z)', $res, $z1, ' (0.5, 0)');
$z0 = cot($s1);
$z1 = 1 / tan($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(340, 'cot(z)', $res, $z1, '(-0.5, 0)');
$z0 = cot($s2);
$z1 = 1 / tan($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(341, 'cot(z)', $res, $z1, '(2,3)');
$z0 = cot($s3);
$z1 = 1 / tan($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(342, 'cot(z)', $res, $z1, '[3,2]');
$z0 = cot($s4);
$z1 = 1 / tan($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(343, 'cot(z)', $res, $z1, '(-3,2)');
$z0 = cot($s5);
$z1 = 1 / tan($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(344, 'cot(z)', $res, $z1, '(0,2)');
$z0 = cot($s6);
$z1 = 1 / tan($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(345, 'cot(z)', $res, $z1, '3');
$z0 = cot($s7);
$z1 = 1 / tan($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(346, 'cot(z)', $res, $z1, '1.2');
$z0 = cot($s8);
$z1 = 1 / tan($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(347, 'cot(z)', $res, $z1, '(-3, 0)');
$z0 = cot($s9);
$z1 = 1 / tan($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(348, 'cot(z)', $res, $z1, '(-2, -1)');
$z0 = cot($s10);
$z1 = 1 / tan($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(349, 'cot(z)', $res, $z1, '[2,1] ');
$z0 = cot($s0);
$z1 = cotan($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(350, 'cot(z)', $res, $z1, ' (0.5, 0)');
$z0 = cot($s1);
$z1 = cotan($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(351, 'cot(z)', $res, $z1, '(-0.5, 0)');
$z0 = cot($s2);
$z1 = cotan($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(352, 'cot(z)', $res, $z1, '(2,3)');
$z0 = cot($s3);
$z1 = cotan($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(353, 'cot(z)', $res, $z1, '[3,2]');
$z0 = cot($s4);
$z1 = cotan($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(354, 'cot(z)', $res, $z1, '(-3,2)');
$z0 = cot($s5);
$z1 = cotan($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(355, 'cot(z)', $res, $z1, '(0,2)');
$z0 = cot($s6);
$z1 = cotan($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(356, 'cot(z)', $res, $z1, '3');
$z0 = cot($s7);
$z1 = cotan($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(357, 'cot(z)', $res, $z1, '1.2');
$z0 = cot($s8);
$z1 = cotan($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(358, 'cot(z)', $res, $z1, '(-3, 0)');
$z0 = cot($s9);
$z1 = cotan($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(359, 'cot(z)', $res, $z1, '(-2, -1)');
$z0 = cot($s10);
$z1 = cotan($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(360, 'cot(z)', $res, $z1, '[2,1] ');
$z0 = csc(acsc($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(361, 'csc(acsc(z))', $res, $z1, ' (0.5, 0)');
$z0 = csc(acsc($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(362, 'csc(acsc(z))', $res, $z1, '(-0.5, 0)');
$z0 = csc(acsc($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(363, 'csc(acsc(z))', $res, $z1, '(2,3)');
$z0 = csc(acsc($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(364, 'csc(acsc(z))', $res, $z1, '[3,2]');
$z0 = csc(acsc($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(365, 'csc(acsc(z))', $res, $z1, '(-3,2)');
$z0 = csc(acsc($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(366, 'csc(acsc(z))', $res, $z1, '(0,2)');
$z0 = csc(acsc($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(367, 'csc(acsc(z))', $res, $z1, '3');
$z0 = csc(acsc($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(368, 'csc(acsc(z))', $res, $z1, '1.2');
$z0 = csc(acsc($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(369, 'csc(acsc(z))', $res, $z1, '(-3, 0)');
$z0 = csc(acsc($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(370, 'csc(acsc(z))', $res, $z1, '(-2, -1)');
$z0 = csc(acsc($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(371, 'csc(acsc(z))', $res, $z1, '[2,1] ');
$z0 = csc($s0);
$z1 = 1 / sin($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(372, 'csc(z)', $res, $z1, ' (0.5, 0)');
$z0 = csc($s1);
$z1 = 1 / sin($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(373, 'csc(z)', $res, $z1, '(-0.5, 0)');
$z0 = csc($s2);
$z1 = 1 / sin($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(374, 'csc(z)', $res, $z1, '(2,3)');
$z0 = csc($s3);
$z1 = 1 / sin($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(375, 'csc(z)', $res, $z1, '[3,2]');
$z0 = csc($s4);
$z1 = 1 / sin($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(376, 'csc(z)', $res, $z1, '(-3,2)');
$z0 = csc($s5);
$z1 = 1 / sin($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(377, 'csc(z)', $res, $z1, '(0,2)');
$z0 = csc($s6);
$z1 = 1 / sin($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(378, 'csc(z)', $res, $z1, '3');
$z0 = csc($s7);
$z1 = 1 / sin($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(379, 'csc(z)', $res, $z1, '1.2');
$z0 = csc($s8);
$z1 = 1 / sin($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(380, 'csc(z)', $res, $z1, '(-3, 0)');
$z0 = csc($s9);
$z1 = 1 / sin($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(381, 'csc(z)', $res, $z1, '(-2, -1)');
$z0 = csc($s10);
$z1 = 1 / sin($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(382, 'csc(z)', $res, $z1, '[2,1] ');
$z0 = csc($s0);
$z1 = cosec($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(383, 'csc(z)', $res, $z1, ' (0.5, 0)');
$z0 = csc($s1);
$z1 = cosec($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(384, 'csc(z)', $res, $z1, '(-0.5, 0)');
$z0 = csc($s2);
$z1 = cosec($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(385, 'csc(z)', $res, $z1, '(2,3)');
$z0 = csc($s3);
$z1 = cosec($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(386, 'csc(z)', $res, $z1, '[3,2]');
$z0 = csc($s4);
$z1 = cosec($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(387, 'csc(z)', $res, $z1, '(-3,2)');
$z0 = csc($s5);
$z1 = cosec($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(388, 'csc(z)', $res, $z1, '(0,2)');
$z0 = csc($s6);
$z1 = cosec($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(389, 'csc(z)', $res, $z1, '3');
$z0 = csc($s7);
$z1 = cosec($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(390, 'csc(z)', $res, $z1, '1.2');
$z0 = csc($s8);
$z1 = cosec($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(391, 'csc(z)', $res, $z1, '(-3, 0)');
$z0 = csc($s9);
$z1 = cosec($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(392, 'csc(z)', $res, $z1, '(-2, -1)');
$z0 = csc($s10);
$z1 = cosec($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(393, 'csc(z)', $res, $z1, '[2,1] ');
$z0 = exp(log($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(394, 'exp(log(z))', $res, $z1, ' (0.5, 0)');
$z0 = exp(log($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(395, 'exp(log(z))', $res, $z1, '(-0.5, 0)');
$z0 = exp(log($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(396, 'exp(log(z))', $res, $z1, '(2,3)');
$z0 = exp(log($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(397, 'exp(log(z))', $res, $z1, '[3,2]');
$z0 = exp(log($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(398, 'exp(log(z))', $res, $z1, '(-3,2)');
$z0 = exp(log($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(399, 'exp(log(z))', $res, $z1, '(0,2)');
$z0 = exp(log($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(400, 'exp(log(z))', $res, $z1, '3');
$z0 = exp(log($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(401, 'exp(log(z))', $res, $z1, '1.2');
$z0 = exp(log($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(402, 'exp(log(z))', $res, $z1, '(-3, 0)');
$z0 = exp(log($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(403, 'exp(log(z))', $res, $z1, '(-2, -1)');
$z0 = exp(log($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(404, 'exp(log(z))', $res, $z1, '[2,1] ');
$z0 = exp($s0);
$z1 = exp(Re($s0)) * exp(i * Im($s0));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(405, 'exp(z)', $res, $z1, ' (0.5, 0)');
$z0 = exp($s1);
$z1 = exp(Re($s1)) * exp(i * Im($s1));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(406, 'exp(z)', $res, $z1, '(-0.5, 0)');
$z0 = exp($s2);
$z1 = exp(Re($s2)) * exp(i * Im($s2));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(407, 'exp(z)', $res, $z1, '(2,3)');
$z0 = exp($s3);
$z1 = exp(Re($s3)) * exp(i * Im($s3));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(408, 'exp(z)', $res, $z1, '[3,2]');
$z0 = exp($s4);
$z1 = exp(Re($s4)) * exp(i * Im($s4));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(409, 'exp(z)', $res, $z1, '(-3,2)');
$z0 = exp($s5);
$z1 = exp(Re($s5)) * exp(i * Im($s5));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(410, 'exp(z)', $res, $z1, '(0,2)');
$z0 = exp($s6);
$z1 = exp(Re($s6)) * exp(i * Im($s6));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(411, 'exp(z)', $res, $z1, '3');
$z0 = exp($s7);
$z1 = exp(Re($s7)) * exp(i * Im($s7));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(412, 'exp(z)', $res, $z1, '1.2');
$z0 = exp($s8);
$z1 = exp(Re($s8)) * exp(i * Im($s8));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(413, 'exp(z)', $res, $z1, '(-3, 0)');
$z0 = exp($s9);
$z1 = exp(Re($s9)) * exp(i * Im($s9));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(414, 'exp(z)', $res, $z1, '(-2, -1)');
$z0 = exp($s10);
$z1 = exp(Re($s10)) * exp(i * Im($s10));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(415, 'exp(z)', $res, $z1, '[2,1] ');
$z0 = ln($s0);
$z1 = log($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(416, 'ln(z)', $res, $z1, ' (0.5, 0)');
$z0 = ln($s1);
$z1 = log($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(417, 'ln(z)', $res, $z1, '(-0.5, 0)');
$z0 = ln($s2);
$z1 = log($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(418, 'ln(z)', $res, $z1, '(2,3)');
$z0 = ln($s3);
$z1 = log($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(419, 'ln(z)', $res, $z1, '[3,2]');
$z0 = ln($s4);
$z1 = log($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(420, 'ln(z)', $res, $z1, '(-3,2)');
$z0 = ln($s5);
$z1 = log($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(421, 'ln(z)', $res, $z1, '(0,2)');
$z0 = ln($s6);
$z1 = log($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(422, 'ln(z)', $res, $z1, '3');
$z0 = ln($s7);
$z1 = log($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(423, 'ln(z)', $res, $z1, '1.2');
$z0 = ln($s8);
$z1 = log($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(424, 'ln(z)', $res, $z1, '(-3, 0)');
$z0 = ln($s9);
$z1 = log($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(425, 'ln(z)', $res, $z1, '(-2, -1)');
$z0 = ln($s10);
$z1 = log($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(426, 'ln(z)', $res, $z1, '[2,1] ');
$z0 = log(exp($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(427, 'log(exp(z))', $res, $z1, ' (0.5, 0)');
$z0 = log(exp($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(428, 'log(exp(z))', $res, $z1, '(-0.5, 0)');
$z0 = log(exp($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(429, 'log(exp(z))', $res, $z1, '(2,3)');
$z0 = log(exp($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(430, 'log(exp(z))', $res, $z1, '[3,2]');
$z0 = log(exp($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(431, 'log(exp(z))', $res, $z1, '(-3,2)');
$z0 = log(exp($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(432, 'log(exp(z))', $res, $z1, '(0,2)');
$z0 = log(exp($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(433, 'log(exp(z))', $res, $z1, '3');
$z0 = log(exp($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(434, 'log(exp(z))', $res, $z1, '1.2');
$z0 = log(exp($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(435, 'log(exp(z))', $res, $z1, '(-3, 0)');
$z0 = log(exp($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(436, 'log(exp(z))', $res, $z1, '(-2, -1)');
$z0 = log(exp($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(437, 'log(exp(z))', $res, $z1, '[2,1] ');
$z0 = log($s0);
$z1 = log(abs($s0)) + i*arg($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(438, 'log(z)', $res, $z1, ' (0.5, 0)');
$z0 = log($s1);
$z1 = log(abs($s1)) + i*arg($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(439, 'log(z)', $res, $z1, '(-0.5, 0)');
$z0 = log($s2);
$z1 = log(abs($s2)) + i*arg($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(440, 'log(z)', $res, $z1, '(2,3)');
$z0 = log($s3);
$z1 = log(abs($s3)) + i*arg($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(441, 'log(z)', $res, $z1, '[3,2]');
$z0 = log($s4);
$z1 = log(abs($s4)) + i*arg($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(442, 'log(z)', $res, $z1, '(-3,2)');
$z0 = log($s5);
$z1 = log(abs($s5)) + i*arg($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(443, 'log(z)', $res, $z1, '(0,2)');
$z0 = log($s6);
$z1 = log(abs($s6)) + i*arg($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(444, 'log(z)', $res, $z1, '3');
$z0 = log($s7);
$z1 = log(abs($s7)) + i*arg($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(445, 'log(z)', $res, $z1, '1.2');
$z0 = log($s8);
$z1 = log(abs($s8)) + i*arg($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(446, 'log(z)', $res, $z1, '(-3, 0)');
$z0 = log($s9);
$z1 = log(abs($s9)) + i*arg($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(447, 'log(z)', $res, $z1, '(-2, -1)');
$z0 = log($s10);
$z1 = log(abs($s10)) + i*arg($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(448, 'log(z)', $res, $z1, '[2,1] ');
$z0 = log10($s0);
$z1 = log($s0) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(449, 'log10(z)', $res, $z1, ' (0.5, 0)');
$z0 = log10($s1);
$z1 = log($s1) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(450, 'log10(z)', $res, $z1, '(-0.5, 0)');
$z0 = log10($s2);
$z1 = log($s2) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(451, 'log10(z)', $res, $z1, '(2,3)');
$z0 = log10($s3);
$z1 = log($s3) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(452, 'log10(z)', $res, $z1, '[3,2]');
$z0 = log10($s4);
$z1 = log($s4) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(453, 'log10(z)', $res, $z1, '(-3,2)');
$z0 = log10($s5);
$z1 = log($s5) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(454, 'log10(z)', $res, $z1, '(0,2)');
$z0 = log10($s6);
$z1 = log($s6) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(455, 'log10(z)', $res, $z1, '3');
$z0 = log10($s7);
$z1 = log($s7) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(456, 'log10(z)', $res, $z1, '1.2');
$z0 = log10($s8);
$z1 = log($s8) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(457, 'log10(z)', $res, $z1, '(-3, 0)');
$z0 = log10($s9);
$z1 = log($s9) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(458, 'log10(z)', $res, $z1, '(-2, -1)');
$z0 = log10($s10);
$z1 = log($s10) / log(10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(459, 'log10(z)', $res, $z1, '[2,1] ');
$z0 = logn($s0, 2);
$z1 = log($s0) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(460, 'logn(z, 2)', $res, $z1, ' (0.5, 0)');
$z0 = logn($s1, 2);
$z1 = log($s1) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(461, 'logn(z, 2)', $res, $z1, '(-0.5, 0)');
$z0 = logn($s2, 2);
$z1 = log($s2) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(462, 'logn(z, 2)', $res, $z1, '(2,3)');
$z0 = logn($s3, 2);
$z1 = log($s3) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(463, 'logn(z, 2)', $res, $z1, '[3,2]');
$z0 = logn($s4, 2);
$z1 = log($s4) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(464, 'logn(z, 2)', $res, $z1, '(-3,2)');
$z0 = logn($s5, 2);
$z1 = log($s5) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(465, 'logn(z, 2)', $res, $z1, '(0,2)');
$z0 = logn($s6, 2);
$z1 = log($s6) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(466, 'logn(z, 2)', $res, $z1, '3');
$z0 = logn($s7, 2);
$z1 = log($s7) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(467, 'logn(z, 2)', $res, $z1, '1.2');
$z0 = logn($s8, 2);
$z1 = log($s8) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(468, 'logn(z, 2)', $res, $z1, '(-3, 0)');
$z0 = logn($s9, 2);
$z1 = log($s9) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(469, 'logn(z, 2)', $res, $z1, '(-2, -1)');
$z0 = logn($s10, 2);
$z1 = log($s10) / log(2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(470, 'logn(z, 2)', $res, $z1, '[2,1] ');
$z0 = logn($s0, 3);
$z1 = log($s0) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(471, 'logn(z, 3)', $res, $z1, ' (0.5, 0)');
$z0 = logn($s1, 3);
$z1 = log($s1) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(472, 'logn(z, 3)', $res, $z1, '(-0.5, 0)');
$z0 = logn($s2, 3);
$z1 = log($s2) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(473, 'logn(z, 3)', $res, $z1, '(2,3)');
$z0 = logn($s3, 3);
$z1 = log($s3) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(474, 'logn(z, 3)', $res, $z1, '[3,2]');
$z0 = logn($s4, 3);
$z1 = log($s4) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(475, 'logn(z, 3)', $res, $z1, '(-3,2)');
$z0 = logn($s5, 3);
$z1 = log($s5) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(476, 'logn(z, 3)', $res, $z1, '(0,2)');
$z0 = logn($s6, 3);
$z1 = log($s6) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(477, 'logn(z, 3)', $res, $z1, '3');
$z0 = logn($s7, 3);
$z1 = log($s7) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(478, 'logn(z, 3)', $res, $z1, '1.2');
$z0 = logn($s8, 3);
$z1 = log($s8) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(479, 'logn(z, 3)', $res, $z1, '(-3, 0)');
$z0 = logn($s9, 3);
$z1 = log($s9) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(480, 'logn(z, 3)', $res, $z1, '(-2, -1)');
$z0 = logn($s10, 3);
$z1 = log($s10) / log(3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(481, 'logn(z, 3)', $res, $z1, '[2,1] ');
$z0 = sec(asec($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(482, 'sec(asec(z))', $res, $z1, ' (0.5, 0)');
$z0 = sec(asec($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(483, 'sec(asec(z))', $res, $z1, '(-0.5, 0)');
$z0 = sec(asec($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(484, 'sec(asec(z))', $res, $z1, '(2,3)');
$z0 = sec(asec($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(485, 'sec(asec(z))', $res, $z1, '[3,2]');
$z0 = sec(asec($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(486, 'sec(asec(z))', $res, $z1, '(-3,2)');
$z0 = sec(asec($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(487, 'sec(asec(z))', $res, $z1, '(0,2)');
$z0 = sec(asec($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(488, 'sec(asec(z))', $res, $z1, '3');
$z0 = sec(asec($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(489, 'sec(asec(z))', $res, $z1, '1.2');
$z0 = sec(asec($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(490, 'sec(asec(z))', $res, $z1, '(-3, 0)');
$z0 = sec(asec($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(491, 'sec(asec(z))', $res, $z1, '(-2, -1)');
$z0 = sec(asec($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(492, 'sec(asec(z))', $res, $z1, '[2,1] ');
$z0 = sec($s0);
$z1 = 1 / cos($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(493, 'sec(z)', $res, $z1, ' (0.5, 0)');
$z0 = sec($s1);
$z1 = 1 / cos($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(494, 'sec(z)', $res, $z1, '(-0.5, 0)');
$z0 = sec($s2);
$z1 = 1 / cos($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(495, 'sec(z)', $res, $z1, '(2,3)');
$z0 = sec($s3);
$z1 = 1 / cos($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(496, 'sec(z)', $res, $z1, '[3,2]');
$z0 = sec($s4);
$z1 = 1 / cos($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(497, 'sec(z)', $res, $z1, '(-3,2)');
$z0 = sec($s5);
$z1 = 1 / cos($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(498, 'sec(z)', $res, $z1, '(0,2)');
$z0 = sec($s6);
$z1 = 1 / cos($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(499, 'sec(z)', $res, $z1, '3');
$z0 = sec($s7);
$z1 = 1 / cos($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(500, 'sec(z)', $res, $z1, '1.2');
$z0 = sec($s8);
$z1 = 1 / cos($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(501, 'sec(z)', $res, $z1, '(-3, 0)');
$z0 = sec($s9);
$z1 = 1 / cos($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(502, 'sec(z)', $res, $z1, '(-2, -1)');
$z0 = sec($s10);
$z1 = 1 / cos($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(503, 'sec(z)', $res, $z1, '[2,1] ');
$z0 = sin(asin($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(504, 'sin(asin(z))', $res, $z1, ' (0.5, 0)');
$z0 = sin(asin($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(505, 'sin(asin(z))', $res, $z1, '(-0.5, 0)');
$z0 = sin(asin($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(506, 'sin(asin(z))', $res, $z1, '(2,3)');
$z0 = sin(asin($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(507, 'sin(asin(z))', $res, $z1, '[3,2]');
$z0 = sin(asin($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(508, 'sin(asin(z))', $res, $z1, '(-3,2)');
$z0 = sin(asin($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(509, 'sin(asin(z))', $res, $z1, '(0,2)');
$z0 = sin(asin($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(510, 'sin(asin(z))', $res, $z1, '3');
$z0 = sin(asin($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(511, 'sin(asin(z))', $res, $z1, '1.2');
$z0 = sin(asin($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(512, 'sin(asin(z))', $res, $z1, '(-3, 0)');
$z0 = sin(asin($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(513, 'sin(asin(z))', $res, $z1, '(-2, -1)');
$z0 = sin(asin($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(514, 'sin(asin(z))', $res, $z1, '[2,1] ');
$z0 = sin(i * $s0);
$z1 = i * sinh($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(515, 'sin(i * z)', $res, $z1, ' (0.5, 0)');
$z0 = sin(i * $s1);
$z1 = i * sinh($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(516, 'sin(i * z)', $res, $z1, '(-0.5, 0)');
$z0 = sin(i * $s2);
$z1 = i * sinh($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(517, 'sin(i * z)', $res, $z1, '(2,3)');
$z0 = sin(i * $s3);
$z1 = i * sinh($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(518, 'sin(i * z)', $res, $z1, '[3,2]');
$z0 = sin(i * $s4);
$z1 = i * sinh($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(519, 'sin(i * z)', $res, $z1, '(-3,2)');
$z0 = sin(i * $s5);
$z1 = i * sinh($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(520, 'sin(i * z)', $res, $z1, '(0,2)');
$z0 = sin(i * $s6);
$z1 = i * sinh($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(521, 'sin(i * z)', $res, $z1, '3');
$z0 = sin(i * $s7);
$z1 = i * sinh($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(522, 'sin(i * z)', $res, $z1, '1.2');
$z0 = sin(i * $s8);
$z1 = i * sinh($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(523, 'sin(i * z)', $res, $z1, '(-3, 0)');
$z0 = sin(i * $s9);
$z1 = i * sinh($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(524, 'sin(i * z)', $res, $z1, '(-2, -1)');
$z0 = sin(i * $s10);
$z1 = i * sinh($s10);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(525, 'sin(i * z)', $res, $z1, '[2,1] ');
$z0 = sqrt($s0) * sqrt($s0);
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(526, 'sqrt(z) * sqrt(z)', $res, $z1, ' (0.5, 0)');
$z0 = sqrt($s1) * sqrt($s1);
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(527, 'sqrt(z) * sqrt(z)', $res, $z1, '(-0.5, 0)');
$z0 = sqrt($s2) * sqrt($s2);
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(528, 'sqrt(z) * sqrt(z)', $res, $z1, '(2,3)');
$z0 = sqrt($s3) * sqrt($s3);
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(529, 'sqrt(z) * sqrt(z)', $res, $z1, '[3,2]');
$z0 = sqrt($s4) * sqrt($s4);
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(530, 'sqrt(z) * sqrt(z)', $res, $z1, '(-3,2)');
$z0 = sqrt($s5) * sqrt($s5);
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(531, 'sqrt(z) * sqrt(z)', $res, $z1, '(0,2)');
$z0 = sqrt($s6) * sqrt($s6);
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(532, 'sqrt(z) * sqrt(z)', $res, $z1, '3');
$z0 = sqrt($s7) * sqrt($s7);
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(533, 'sqrt(z) * sqrt(z)', $res, $z1, '1.2');
$z0 = sqrt($s8) * sqrt($s8);
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(534, 'sqrt(z) * sqrt(z)', $res, $z1, '(-3, 0)');
$z0 = sqrt($s9) * sqrt($s9);
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(535, 'sqrt(z) * sqrt(z)', $res, $z1, '(-2, -1)');
$z0 = sqrt($s10) * sqrt($s10);
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(536, 'sqrt(z) * sqrt(z)', $res, $z1, '[2,1] ');
$z0 = sqrt($s0);
$z1 = sqrt(abs($s0)) * exp(i * arg($s0)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(537, 'sqrt(z)', $res, $z1, ' (0.5, 0)');
$z0 = sqrt($s1);
$z1 = sqrt(abs($s1)) * exp(i * arg($s1)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(538, 'sqrt(z)', $res, $z1, '(-0.5, 0)');
$z0 = sqrt($s2);
$z1 = sqrt(abs($s2)) * exp(i * arg($s2)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(539, 'sqrt(z)', $res, $z1, '(2,3)');
$z0 = sqrt($s3);
$z1 = sqrt(abs($s3)) * exp(i * arg($s3)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(540, 'sqrt(z)', $res, $z1, '[3,2]');
$z0 = sqrt($s4);
$z1 = sqrt(abs($s4)) * exp(i * arg($s4)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(541, 'sqrt(z)', $res, $z1, '(-3,2)');
$z0 = sqrt($s5);
$z1 = sqrt(abs($s5)) * exp(i * arg($s5)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(542, 'sqrt(z)', $res, $z1, '(0,2)');
$z0 = sqrt($s6);
$z1 = sqrt(abs($s6)) * exp(i * arg($s6)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(543, 'sqrt(z)', $res, $z1, '3');
$z0 = sqrt($s7);
$z1 = sqrt(abs($s7)) * exp(i * arg($s7)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(544, 'sqrt(z)', $res, $z1, '1.2');
$z0 = sqrt($s8);
$z1 = sqrt(abs($s8)) * exp(i * arg($s8)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(545, 'sqrt(z)', $res, $z1, '(-3, 0)');
$z0 = sqrt($s9);
$z1 = sqrt(abs($s9)) * exp(i * arg($s9)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(546, 'sqrt(z)', $res, $z1, '(-2, -1)');
$z0 = sqrt($s10);
$z1 = sqrt(abs($s10)) * exp(i * arg($s10)/2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(547, 'sqrt(z)', $res, $z1, '[2,1] ');
$z0 = tan(atan($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(548, 'tan(atan(z))', $res, $z1, ' (0.5, 0)');
$z0 = tan(atan($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(549, 'tan(atan(z))', $res, $z1, '(-0.5, 0)');
$z0 = tan(atan($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(550, 'tan(atan(z))', $res, $z1, '(2,3)');
$z0 = tan(atan($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(551, 'tan(atan(z))', $res, $z1, '[3,2]');
$z0 = tan(atan($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(552, 'tan(atan(z))', $res, $z1, '(-3,2)');
$z0 = tan(atan($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(553, 'tan(atan(z))', $res, $z1, '(0,2)');
$z0 = tan(atan($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(554, 'tan(atan(z))', $res, $z1, '3');
$z0 = tan(atan($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(555, 'tan(atan(z))', $res, $z1, '1.2');
$z0 = tan(atan($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(556, 'tan(atan(z))', $res, $z1, '(-3, 0)');
$z0 = tan(atan($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(557, 'tan(atan(z))', $res, $z1, '(-2, -1)');
$z0 = tan(atan($s10));
$z1 = $s10;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(558, 'tan(atan(z))', $res, $z1, '[2,1] ');
$z0 = $s0**$s0;
$z1 = exp($s0 * log($s0));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(559, 'z**z', $res, $z1, ' (0.5, 0)');
$z0 = $s1**$s1;
$z1 = exp($s1 * log($s1));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(560, 'z**z', $res, $z1, '(-0.5, 0)');
$z0 = $s2**$s2;
$z1 = exp($s2 * log($s2));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(561, 'z**z', $res, $z1, '(2,3)');
$z0 = $s3**$s3;
$z1 = exp($s3 * log($s3));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(562, 'z**z', $res, $z1, '[3,2]');
$z0 = $s4**$s4;
$z1 = exp($s4 * log($s4));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(563, 'z**z', $res, $z1, '(-3,2)');
$z0 = $s5**$s5;
$z1 = exp($s5 * log($s5));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(564, 'z**z', $res, $z1, '(0,2)');
$z0 = $s6**$s6;
$z1 = exp($s6 * log($s6));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(565, 'z**z', $res, $z1, '3');
$z0 = $s7**$s7;
$z1 = exp($s7 * log($s7));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(566, 'z**z', $res, $z1, '1.2');
$z0 = $s8**$s8;
$z1 = exp($s8 * log($s8));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(567, 'z**z', $res, $z1, '(-3, 0)');
$z0 = $s9**$s9;
$z1 = exp($s9 * log($s9));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(568, 'z**z', $res, $z1, '(-2, -1)');
$z0 = $s10**$s10;
$z1 = exp($s10 * log($s10));
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(569, 'z**z', $res, $z1, '[2,1] ');
$s0 = cplx(1,1);
$s1 = cplxe(1,0.5);
$s2 = cplx(-2, -1);
$s3 = cplx(2,0);
$s4 = cplx(-3,0);
$s5 = cplx(-1,0.5);
$s6 = cplx(0,0.5);
$s7 = cplx(0.5,0);
$s8 = cplx(2, 0);
$s9 = cplx(-1, -2);
$z0 = cosh(acosh($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(570, 'cosh(acosh(z))', $res, $z1, ' (1,1)');
$z0 = cosh(acosh($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(571, 'cosh(acosh(z))', $res, $z1, '[1,0.5]');
$z0 = cosh(acosh($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(572, 'cosh(acosh(z))', $res, $z1, '(-2, -1)');
$z0 = cosh(acosh($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(573, 'cosh(acosh(z))', $res, $z1, '2');
$z0 = cosh(acosh($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(574, 'cosh(acosh(z))', $res, $z1, '-3');
$z0 = cosh(acosh($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(575, 'cosh(acosh(z))', $res, $z1, '(-1,0.5)');
$z0 = cosh(acosh($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(576, 'cosh(acosh(z))', $res, $z1, '(0,0.5)');
$z0 = cosh(acosh($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(577, 'cosh(acosh(z))', $res, $z1, '0.5');
$z0 = cosh(acosh($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(578, 'cosh(acosh(z))', $res, $z1, '(2, 0)');
$z0 = cosh(acosh($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(579, 'cosh(acosh(z))', $res, $z1, '(-1, -2) ');
$z0 = coth(acoth($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(580, 'coth(acoth(z))', $res, $z1, ' (1,1)');
$z0 = coth(acoth($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(581, 'coth(acoth(z))', $res, $z1, '[1,0.5]');
$z0 = coth(acoth($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(582, 'coth(acoth(z))', $res, $z1, '(-2, -1)');
$z0 = coth(acoth($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(583, 'coth(acoth(z))', $res, $z1, '2');
$z0 = coth(acoth($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(584, 'coth(acoth(z))', $res, $z1, '-3');
$z0 = coth(acoth($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(585, 'coth(acoth(z))', $res, $z1, '(-1,0.5)');
$z0 = coth(acoth($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(586, 'coth(acoth(z))', $res, $z1, '(0,0.5)');
$z0 = coth(acoth($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(587, 'coth(acoth(z))', $res, $z1, '0.5');
$z0 = coth(acoth($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(588, 'coth(acoth(z))', $res, $z1, '(2, 0)');
$z0 = coth(acoth($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(589, 'coth(acoth(z))', $res, $z1, '(-1, -2) ');
$z0 = coth($s0);
$z1 = 1 / tanh($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(590, 'coth(z)', $res, $z1, ' (1,1)');
$z0 = coth($s1);
$z1 = 1 / tanh($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(591, 'coth(z)', $res, $z1, '[1,0.5]');
$z0 = coth($s2);
$z1 = 1 / tanh($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(592, 'coth(z)', $res, $z1, '(-2, -1)');
$z0 = coth($s3);
$z1 = 1 / tanh($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(593, 'coth(z)', $res, $z1, '2');
$z0 = coth($s4);
$z1 = 1 / tanh($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(594, 'coth(z)', $res, $z1, '-3');
$z0 = coth($s5);
$z1 = 1 / tanh($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(595, 'coth(z)', $res, $z1, '(-1,0.5)');
$z0 = coth($s6);
$z1 = 1 / tanh($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(596, 'coth(z)', $res, $z1, '(0,0.5)');
$z0 = coth($s7);
$z1 = 1 / tanh($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(597, 'coth(z)', $res, $z1, '0.5');
$z0 = coth($s8);
$z1 = 1 / tanh($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(598, 'coth(z)', $res, $z1, '(2, 0)');
$z0 = coth($s9);
$z1 = 1 / tanh($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(599, 'coth(z)', $res, $z1, '(-1, -2) ');
$z0 = coth($s0);
$z1 = cotanh($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(600, 'coth(z)', $res, $z1, ' (1,1)');
$z0 = coth($s1);
$z1 = cotanh($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(601, 'coth(z)', $res, $z1, '[1,0.5]');
$z0 = coth($s2);
$z1 = cotanh($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(602, 'coth(z)', $res, $z1, '(-2, -1)');
$z0 = coth($s3);
$z1 = cotanh($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(603, 'coth(z)', $res, $z1, '2');
$z0 = coth($s4);
$z1 = cotanh($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(604, 'coth(z)', $res, $z1, '-3');
$z0 = coth($s5);
$z1 = cotanh($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(605, 'coth(z)', $res, $z1, '(-1,0.5)');
$z0 = coth($s6);
$z1 = cotanh($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(606, 'coth(z)', $res, $z1, '(0,0.5)');
$z0 = coth($s7);
$z1 = cotanh($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(607, 'coth(z)', $res, $z1, '0.5');
$z0 = coth($s8);
$z1 = cotanh($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(608, 'coth(z)', $res, $z1, '(2, 0)');
$z0 = coth($s9);
$z1 = cotanh($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(609, 'coth(z)', $res, $z1, '(-1, -2) ');
$z0 = csch(acsch($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(610, 'csch(acsch(z))', $res, $z1, ' (1,1)');
$z0 = csch(acsch($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(611, 'csch(acsch(z))', $res, $z1, '[1,0.5]');
$z0 = csch(acsch($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(612, 'csch(acsch(z))', $res, $z1, '(-2, -1)');
$z0 = csch(acsch($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(613, 'csch(acsch(z))', $res, $z1, '2');
$z0 = csch(acsch($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(614, 'csch(acsch(z))', $res, $z1, '-3');
$z0 = csch(acsch($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(615, 'csch(acsch(z))', $res, $z1, '(-1,0.5)');
$z0 = csch(acsch($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(616, 'csch(acsch(z))', $res, $z1, '(0,0.5)');
$z0 = csch(acsch($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(617, 'csch(acsch(z))', $res, $z1, '0.5');
$z0 = csch(acsch($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(618, 'csch(acsch(z))', $res, $z1, '(2, 0)');
$z0 = csch(acsch($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(619, 'csch(acsch(z))', $res, $z1, '(-1, -2) ');
$z0 = csch($s0);
$z1 = 1 / sinh($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(620, 'csch(z)', $res, $z1, ' (1,1)');
$z0 = csch($s1);
$z1 = 1 / sinh($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(621, 'csch(z)', $res, $z1, '[1,0.5]');
$z0 = csch($s2);
$z1 = 1 / sinh($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(622, 'csch(z)', $res, $z1, '(-2, -1)');
$z0 = csch($s3);
$z1 = 1 / sinh($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(623, 'csch(z)', $res, $z1, '2');
$z0 = csch($s4);
$z1 = 1 / sinh($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(624, 'csch(z)', $res, $z1, '-3');
$z0 = csch($s5);
$z1 = 1 / sinh($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(625, 'csch(z)', $res, $z1, '(-1,0.5)');
$z0 = csch($s6);
$z1 = 1 / sinh($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(626, 'csch(z)', $res, $z1, '(0,0.5)');
$z0 = csch($s7);
$z1 = 1 / sinh($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(627, 'csch(z)', $res, $z1, '0.5');
$z0 = csch($s8);
$z1 = 1 / sinh($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(628, 'csch(z)', $res, $z1, '(2, 0)');
$z0 = csch($s9);
$z1 = 1 / sinh($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(629, 'csch(z)', $res, $z1, '(-1, -2) ');
$z0 = csch($s0);
$z1 = cosech($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(630, 'csch(z)', $res, $z1, ' (1,1)');
$z0 = csch($s1);
$z1 = cosech($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(631, 'csch(z)', $res, $z1, '[1,0.5]');
$z0 = csch($s2);
$z1 = cosech($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(632, 'csch(z)', $res, $z1, '(-2, -1)');
$z0 = csch($s3);
$z1 = cosech($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(633, 'csch(z)', $res, $z1, '2');
$z0 = csch($s4);
$z1 = cosech($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(634, 'csch(z)', $res, $z1, '-3');
$z0 = csch($s5);
$z1 = cosech($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(635, 'csch(z)', $res, $z1, '(-1,0.5)');
$z0 = csch($s6);
$z1 = cosech($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(636, 'csch(z)', $res, $z1, '(0,0.5)');
$z0 = csch($s7);
$z1 = cosech($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(637, 'csch(z)', $res, $z1, '0.5');
$z0 = csch($s8);
$z1 = cosech($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(638, 'csch(z)', $res, $z1, '(2, 0)');
$z0 = csch($s9);
$z1 = cosech($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(639, 'csch(z)', $res, $z1, '(-1, -2) ');
$z0 = sech(asech($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(640, 'sech(asech(z))', $res, $z1, ' (1,1)');
$z0 = sech(asech($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(641, 'sech(asech(z))', $res, $z1, '[1,0.5]');
$z0 = sech(asech($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(642, 'sech(asech(z))', $res, $z1, '(-2, -1)');
$z0 = sech(asech($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(643, 'sech(asech(z))', $res, $z1, '2');
$z0 = sech(asech($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(644, 'sech(asech(z))', $res, $z1, '-3');
$z0 = sech(asech($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(645, 'sech(asech(z))', $res, $z1, '(-1,0.5)');
$z0 = sech(asech($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(646, 'sech(asech(z))', $res, $z1, '(0,0.5)');
$z0 = sech(asech($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(647, 'sech(asech(z))', $res, $z1, '0.5');
$z0 = sech(asech($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(648, 'sech(asech(z))', $res, $z1, '(2, 0)');
$z0 = sech(asech($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(649, 'sech(asech(z))', $res, $z1, '(-1, -2) ');
$z0 = sech($s0);
$z1 = 1 / cosh($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(650, 'sech(z)', $res, $z1, ' (1,1)');
$z0 = sech($s1);
$z1 = 1 / cosh($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(651, 'sech(z)', $res, $z1, '[1,0.5]');
$z0 = sech($s2);
$z1 = 1 / cosh($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(652, 'sech(z)', $res, $z1, '(-2, -1)');
$z0 = sech($s3);
$z1 = 1 / cosh($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(653, 'sech(z)', $res, $z1, '2');
$z0 = sech($s4);
$z1 = 1 / cosh($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(654, 'sech(z)', $res, $z1, '-3');
$z0 = sech($s5);
$z1 = 1 / cosh($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(655, 'sech(z)', $res, $z1, '(-1,0.5)');
$z0 = sech($s6);
$z1 = 1 / cosh($s6);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(656, 'sech(z)', $res, $z1, '(0,0.5)');
$z0 = sech($s7);
$z1 = 1 / cosh($s7);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(657, 'sech(z)', $res, $z1, '0.5');
$z0 = sech($s8);
$z1 = 1 / cosh($s8);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(658, 'sech(z)', $res, $z1, '(2, 0)');
$z0 = sech($s9);
$z1 = 1 / cosh($s9);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(659, 'sech(z)', $res, $z1, '(-1, -2) ');
$z0 = sinh(asinh($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(660, 'sinh(asinh(z))', $res, $z1, ' (1,1)');
$z0 = sinh(asinh($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(661, 'sinh(asinh(z))', $res, $z1, '[1,0.5]');
$z0 = sinh(asinh($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(662, 'sinh(asinh(z))', $res, $z1, '(-2, -1)');
$z0 = sinh(asinh($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(663, 'sinh(asinh(z))', $res, $z1, '2');
$z0 = sinh(asinh($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(664, 'sinh(asinh(z))', $res, $z1, '-3');
$z0 = sinh(asinh($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(665, 'sinh(asinh(z))', $res, $z1, '(-1,0.5)');
$z0 = sinh(asinh($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(666, 'sinh(asinh(z))', $res, $z1, '(0,0.5)');
$z0 = sinh(asinh($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(667, 'sinh(asinh(z))', $res, $z1, '0.5');
$z0 = sinh(asinh($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(668, 'sinh(asinh(z))', $res, $z1, '(2, 0)');
$z0 = sinh(asinh($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(669, 'sinh(asinh(z))', $res, $z1, '(-1, -2) ');
$z0 = tanh(atanh($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(670, 'tanh(atanh(z))', $res, $z1, ' (1,1)');
$z0 = tanh(atanh($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(671, 'tanh(atanh(z))', $res, $z1, '[1,0.5]');
$z0 = tanh(atanh($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(672, 'tanh(atanh(z))', $res, $z1, '(-2, -1)');
$z0 = tanh(atanh($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(673, 'tanh(atanh(z))', $res, $z1, '2');
$z0 = tanh(atanh($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(674, 'tanh(atanh(z))', $res, $z1, '-3');
$z0 = tanh(atanh($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(675, 'tanh(atanh(z))', $res, $z1, '(-1,0.5)');
$z0 = tanh(atanh($s6));
$z1 = $s6;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(676, 'tanh(atanh(z))', $res, $z1, '(0,0.5)');
$z0 = tanh(atanh($s7));
$z1 = $s7;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(677, 'tanh(atanh(z))', $res, $z1, '0.5');
$z0 = tanh(atanh($s8));
$z1 = $s8;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(678, 'tanh(atanh(z))', $res, $z1, '(2, 0)');
$z0 = tanh(atanh($s9));
$z1 = $s9;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(679, 'tanh(atanh(z))', $res, $z1, '(-1, -2) ');
$s0 = cplx(0.2,-0.4);
$s1 = cplxe(1,0.5);
$s2 = cplx(-1.2,0);
$s3 = cplx(-1,0.5);
$s4 = cplx(0.5,0);
$s5 = cplx(1.1, 0);
$z0 = acos(cos($s0)) ** 2;
$z1 = $s0 * $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(680, 'acos(cos(z)) ** 2', $res, $z1, ' (0.2,-0.4)');
$z0 = acos(cos($s1)) ** 2;
$z1 = $s1 * $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(681, 'acos(cos(z)) ** 2', $res, $z1, '[1,0.5]');
$z0 = acos(cos($s2)) ** 2;
$z1 = $s2 * $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(682, 'acos(cos(z)) ** 2', $res, $z1, '-1.2');
$z0 = acos(cos($s3)) ** 2;
$z1 = $s3 * $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(683, 'acos(cos(z)) ** 2', $res, $z1, '(-1,0.5)');
$z0 = acos(cos($s4)) ** 2;
$z1 = $s4 * $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(684, 'acos(cos(z)) ** 2', $res, $z1, '0.5');
$z0 = acos(cos($s5)) ** 2;
$z1 = $s5 * $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(685, 'acos(cos(z)) ** 2', $res, $z1, '(1.1, 0) ');
$z0 = acosh(cosh($s0)) ** 2;
$z1 = $s0 * $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(686, 'acosh(cosh(z)) ** 2', $res, $z1, ' (0.2,-0.4)');
$z0 = acosh(cosh($s1)) ** 2;
$z1 = $s1 * $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(687, 'acosh(cosh(z)) ** 2', $res, $z1, '[1,0.5]');
$z0 = acosh(cosh($s2)) ** 2;
$z1 = $s2 * $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(688, 'acosh(cosh(z)) ** 2', $res, $z1, '-1.2');
$z0 = acosh(cosh($s3)) ** 2;
$z1 = $s3 * $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(689, 'acosh(cosh(z)) ** 2', $res, $z1, '(-1,0.5)');
$z0 = acosh(cosh($s4)) ** 2;
$z1 = $s4 * $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(690, 'acosh(cosh(z)) ** 2', $res, $z1, '0.5');
$z0 = acosh(cosh($s5)) ** 2;
$z1 = $s5 * $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(691, 'acosh(cosh(z)) ** 2', $res, $z1, '(1.1, 0) ');
$z0 = acoth($s0);
$z1 = acotanh($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(692, 'acoth(z)', $res, $z1, ' (0.2,-0.4)');
$z0 = acoth($s1);
$z1 = acotanh($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(693, 'acoth(z)', $res, $z1, '[1,0.5]');
$z0 = acoth($s2);
$z1 = acotanh($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(694, 'acoth(z)', $res, $z1, '-1.2');
$z0 = acoth($s3);
$z1 = acotanh($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(695, 'acoth(z)', $res, $z1, '(-1,0.5)');
$z0 = acoth($s4);
$z1 = acotanh($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(696, 'acoth(z)', $res, $z1, '0.5');
$z0 = acoth($s5);
$z1 = acotanh($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(697, 'acoth(z)', $res, $z1, '(1.1, 0) ');
$z0 = acoth($s0);
$z1 = atanh(1 / $s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(698, 'acoth(z)', $res, $z1, ' (0.2,-0.4)');
$z0 = acoth($s1);
$z1 = atanh(1 / $s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(699, 'acoth(z)', $res, $z1, '[1,0.5]');
$z0 = acoth($s2);
$z1 = atanh(1 / $s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(700, 'acoth(z)', $res, $z1, '-1.2');
$z0 = acoth($s3);
$z1 = atanh(1 / $s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(701, 'acoth(z)', $res, $z1, '(-1,0.5)');
$z0 = acoth($s4);
$z1 = atanh(1 / $s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(702, 'acoth(z)', $res, $z1, '0.5');
$z0 = acoth($s5);
$z1 = atanh(1 / $s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(703, 'acoth(z)', $res, $z1, '(1.1, 0) ');
$z0 = acsch($s0);
$z1 = acosech($s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(704, 'acsch(z)', $res, $z1, ' (0.2,-0.4)');
$z0 = acsch($s1);
$z1 = acosech($s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(705, 'acsch(z)', $res, $z1, '[1,0.5]');
$z0 = acsch($s2);
$z1 = acosech($s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(706, 'acsch(z)', $res, $z1, '-1.2');
$z0 = acsch($s3);
$z1 = acosech($s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(707, 'acsch(z)', $res, $z1, '(-1,0.5)');
$z0 = acsch($s4);
$z1 = acosech($s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(708, 'acsch(z)', $res, $z1, '0.5');
$z0 = acsch($s5);
$z1 = acosech($s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(709, 'acsch(z)', $res, $z1, '(1.1, 0) ');
$z0 = acsch($s0);
$z1 = asinh(1 / $s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(710, 'acsch(z)', $res, $z1, ' (0.2,-0.4)');
$z0 = acsch($s1);
$z1 = asinh(1 / $s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(711, 'acsch(z)', $res, $z1, '[1,0.5]');
$z0 = acsch($s2);
$z1 = asinh(1 / $s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(712, 'acsch(z)', $res, $z1, '-1.2');
$z0 = acsch($s3);
$z1 = asinh(1 / $s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(713, 'acsch(z)', $res, $z1, '(-1,0.5)');
$z0 = acsch($s4);
$z1 = asinh(1 / $s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(714, 'acsch(z)', $res, $z1, '0.5');
$z0 = acsch($s5);
$z1 = asinh(1 / $s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(715, 'acsch(z)', $res, $z1, '(1.1, 0) ');
$z0 = asech($s0);
$z1 = acosh(1 / $s0);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(716, 'asech(z)', $res, $z1, ' (0.2,-0.4)');
$z0 = asech($s1);
$z1 = acosh(1 / $s1);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(717, 'asech(z)', $res, $z1, '[1,0.5]');
$z0 = asech($s2);
$z1 = acosh(1 / $s2);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(718, 'asech(z)', $res, $z1, '-1.2');
$z0 = asech($s3);
$z1 = acosh(1 / $s3);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(719, 'asech(z)', $res, $z1, '(-1,0.5)');
$z0 = asech($s4);
$z1 = acosh(1 / $s4);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(720, 'asech(z)', $res, $z1, '0.5');
$z0 = asech($s5);
$z1 = acosh(1 / $s5);
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(721, 'asech(z)', $res, $z1, '(1.1, 0) ');
$z0 = asin(sin($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(722, 'asin(sin(z))', $res, $z1, ' (0.2,-0.4)');
$z0 = asin(sin($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(723, 'asin(sin(z))', $res, $z1, '[1,0.5]');
$z0 = asin(sin($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(724, 'asin(sin(z))', $res, $z1, '-1.2');
$z0 = asin(sin($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(725, 'asin(sin(z))', $res, $z1, '(-1,0.5)');
$z0 = asin(sin($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(726, 'asin(sin(z))', $res, $z1, '0.5');
$z0 = asin(sin($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(727, 'asin(sin(z))', $res, $z1, '(1.1, 0) ');
$z0 = asinh(sinh($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(728, 'asinh(sinh(z))', $res, $z1, ' (0.2,-0.4)');
$z0 = asinh(sinh($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(729, 'asinh(sinh(z))', $res, $z1, '[1,0.5]');
$z0 = asinh(sinh($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(730, 'asinh(sinh(z))', $res, $z1, '-1.2');
$z0 = asinh(sinh($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(731, 'asinh(sinh(z))', $res, $z1, '(-1,0.5)');
$z0 = asinh(sinh($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(732, 'asinh(sinh(z))', $res, $z1, '0.5');
$z0 = asinh(sinh($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(733, 'asinh(sinh(z))', $res, $z1, '(1.1, 0) ');
$z0 = atan(tan($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(734, 'atan(tan(z))', $res, $z1, ' (0.2,-0.4)');
$z0 = atan(tan($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(735, 'atan(tan(z))', $res, $z1, '[1,0.5]');
$z0 = atan(tan($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(736, 'atan(tan(z))', $res, $z1, '-1.2');
$z0 = atan(tan($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(737, 'atan(tan(z))', $res, $z1, '(-1,0.5)');
$z0 = atan(tan($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(738, 'atan(tan(z))', $res, $z1, '0.5');
$z0 = atan(tan($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(739, 'atan(tan(z))', $res, $z1, '(1.1, 0) ');
$z0 = atanh(tanh($s0));
$z1 = $s0;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(740, 'atanh(tanh(z))', $res, $z1, ' (0.2,-0.4)');
$z0 = atanh(tanh($s1));
$z1 = $s1;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(741, 'atanh(tanh(z))', $res, $z1, '[1,0.5]');
$z0 = atanh(tanh($s2));
$z1 = $s2;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(742, 'atanh(tanh(z))', $res, $z1, '-1.2');
$z0 = atanh(tanh($s3));
$z1 = $s3;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(743, 'atanh(tanh(z))', $res, $z1, '(-1,0.5)');
$z0 = atanh(tanh($s4));
$z1 = $s4;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(744, 'atanh(tanh(z))', $res, $z1, '0.5');
$z0 = atanh(tanh($s5));
$z1 = $s5;
$res = abs($z0 - $z1) <= 1e-13 ? $z1 : $z0; check(745, 'atanh(tanh(z))', $res, $z1, '(1.1, 0) ');
$z0 = cplx(-2.0,0);
$z1 = cplx(   0.69314718055995,  3.14159265358979);
$res = log $z0; check(746, 'log $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   0               ,  3.14159265358979);
$res = log $z0; check(747, 'log $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.69314718055995,  3.14159265358979);
$res = log $z0; check(748, 'log $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(  -0.69314718055995,  0               );
$res = log $z0; check(749, 'log $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0               ,  0               );
$res = log $z0; check(750, 'log $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.69314718055995,  0               );
$res = log $z0; check(751, 'log $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(    1.28247467873077,  0.98279372324733);
$res = log $z0; check(752, 'log $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(    1.28247467873077,  2.15879893034246);
$res = log $z0; check(753, 'log $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(    1.28247467873077, -2.15879893034246);
$res = log $z0; check(754, 'log $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(    1.28247467873077, -0.98279372324733);
$res = log $z0; check(755, 'log $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.90929742682568,  0               );
$res = sin $z0; check(756, 'sin $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.84147098480790,  0               );
$res = sin $z0; check(757, 'sin $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.47942553860420,  0               );
$res = sin $z0; check(758, 'sin $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = sin $z0; check(759, 'sin $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.47942553860420,  0               );
$res = sin $z0; check(760, 'sin $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.84147098480790,  0               );
$res = sin $z0; check(761, 'sin $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.90929742682568,  0               );
$res = sin $z0; check(762, 'sin $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  9.15449914691143, -4.16890695996656);
$res = sin $z0; check(763, 'sin $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -9.15449914691143, -4.16890695996656);
$res = sin $z0; check(764, 'sin $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -9.15449914691143,  4.16890695996656);
$res = sin $z0; check(765, 'sin $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  9.15449914691143,  4.16890695996656);
$res = sin $z0; check(766, 'sin $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.41614683654714,  0               );
$res = cos $z0; check(767, 'cos $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   0.54030230586814,  0               );
$res = cos $z0; check(768, 'cos $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   0.87758256189037,  0               );
$res = cos $z0; check(769, 'cos $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   1               ,  0               );
$res = cos $z0; check(770, 'cos $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.87758256189037,  0               );
$res = cos $z0; check(771, 'cos $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.54030230586814,  0               );
$res = cos $z0; check(772, 'cos $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(  -0.41614683654714,  0               );
$res = cos $z0; check(773, 'cos $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -4.18962569096881, -9.10922789375534);
$res = cos $z0; check(774, 'cos $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -4.18962569096881,  9.10922789375534);
$res = cos $z0; check(775, 'cos $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -4.18962569096881, -9.10922789375534);
$res = cos $z0; check(776, 'cos $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -4.18962569096881,  9.10922789375534);
$res = cos $z0; check(777, 'cos $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   2.18503986326152,  0               );
$res = tan $z0; check(778, 'tan $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -1.55740772465490,  0               );
$res = tan $z0; check(779, 'tan $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.54630248984379,  0               );
$res = tan $z0; check(780, 'tan $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = tan $z0; check(781, 'tan $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.54630248984379,  0               );
$res = tan $z0; check(782, 'tan $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.55740772465490,  0               );
$res = tan $z0; check(783, 'tan $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(  -2.18503986326152,  0               );
$res = tan $z0; check(784, 'tan $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -0.00376402564150,  1.00323862735361);
$res = tan $z0; check(785, 'tan $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  0.00376402564150,  1.00323862735361);
$res = tan $z0; check(786, 'tan $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  0.00376402564150, -1.00323862735361);
$res = tan $z0; check(787, 'tan $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -0.00376402564150, -1.00323862735361);
$res = tan $z0; check(788, 'tan $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -2.40299796172238,  0               );
$res = sec $z0; check(789, 'sec $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   1.85081571768093,  0               );
$res = sec $z0; check(790, 'sec $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   1.13949392732455,  0               );
$res = sec $z0; check(791, 'sec $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   1               ,  0               );
$res = sec $z0; check(792, 'sec $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.13949392732455,  0               );
$res = sec $z0; check(793, 'sec $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.85081571768093,  0               );
$res = sec $z0; check(794, 'sec $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(  -2.40299796172238,  0               );
$res = sec $z0; check(795, 'sec $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -0.04167496441114,  0.09061113719624);
$res = sec $z0; check(796, 'sec $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.04167496441114, -0.09061113719624);
$res = sec $z0; check(797, 'sec $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.04167496441114,  0.09061113719624);
$res = sec $z0; check(798, 'sec $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -0.04167496441114, -0.09061113719624);
$res = sec $z0; check(799, 'sec $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -1.09975017029462,  0               );
$res = csc $z0; check(800, 'csc $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -1.18839510577812,  0               );
$res = csc $z0; check(801, 'csc $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -2.08582964293349,  0               );
$res = csc $z0; check(802, 'csc $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   2.08582964293349,  0               );
$res = csc $z0; check(803, 'csc $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.18839510577812,  0               );
$res = csc $z0; check(804, 'csc $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   1.09975017029462,  0               );
$res = csc $z0; check(805, 'csc $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.09047320975321,  0.04120098628857);
$res = csc $z0; check(806, 'csc $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.09047320975321,  0.04120098628857);
$res = csc $z0; check(807, 'csc $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.09047320975321, -0.04120098628857);
$res = csc $z0; check(808, 'csc $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.09047320975321, -0.04120098628857);
$res = csc $z0; check(809, 'csc $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   0.45765755436029,  0               );
$res = cot $z0; check(810, 'cot $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.64209261593433,  0               );
$res = cot $z0; check(811, 'cot $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -1.83048772171245,  0               );
$res = cot $z0; check(812, 'cot $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.83048772171245,  0               );
$res = cot $z0; check(813, 'cot $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.64209261593433,  0               );
$res = cot $z0; check(814, 'cot $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(  -0.45765755436029,  0               );
$res = cot $z0; check(815, 'cot $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -0.00373971037634, -0.99675779656936);
$res = cot $z0; check(816, 'cot $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  0.00373971037634, -0.99675779656936);
$res = cot $z0; check(817, 'cot $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  0.00373971037634,  0.99675779656936);
$res = cot $z0; check(818, 'cot $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -0.00373971037634,  0.99675779656936);
$res = cot $z0; check(819, 'cot $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -1.57079632679490,  1.31695789692482);
$res = asin $z0; check(820, 'asin $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -1.57079632679490,  0               );
$res = asin $z0; check(821, 'asin $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.52359877559830,  0               );
$res = asin $z0; check(822, 'asin $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = asin $z0; check(823, 'asin $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.52359877559830,  0               );
$res = asin $z0; check(824, 'asin $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.57079632679490,  0               );
$res = asin $z0; check(825, 'asin $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   1.57079632679490, -1.31695789692482);
$res = asin $z0; check(826, 'asin $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.57065278432110,  1.98338702991654);
$res = asin $z0; check(827, 'asin $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.57065278432110,  1.98338702991654);
$res = asin $z0; check(828, 'asin $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.57065278432110, -1.98338702991654);
$res = asin $z0; check(829, 'asin $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.57065278432110, -1.98338702991654);
$res = asin $z0; check(830, 'asin $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   3.14159265358979, -1.31695789692482);
$res = acos $z0; check(831, 'acos $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   3.14159265358979,  0               );
$res = acos $z0; check(832, 'acos $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   2.09439510239320,  0               );
$res = acos $z0; check(833, 'acos $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   1.57079632679490,  0               );
$res = acos $z0; check(834, 'acos $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.04719755119660,  0               );
$res = acos $z0; check(835, 'acos $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0               ,  0               );
$res = acos $z0; check(836, 'acos $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0               ,  1.31695789692482);
$res = acos $z0; check(837, 'acos $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  1.00014354247380, -1.98338702991654);
$res = acos $z0; check(838, 'acos $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  2.14144911111600, -1.98338702991654);
$res = acos $z0; check(839, 'acos $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  2.14144911111600,  1.98338702991654);
$res = acos $z0; check(840, 'acos $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  1.00014354247380,  1.98338702991654);
$res = acos $z0; check(841, 'acos $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -1.10714871779409,  0               );
$res = atan $z0; check(842, 'atan $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.78539816339745,  0               );
$res = atan $z0; check(843, 'atan $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.46364760900081,  0               );
$res = atan $z0; check(844, 'atan $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = atan $z0; check(845, 'atan $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.46364760900081,  0               );
$res = atan $z0; check(846, 'atan $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.78539816339745,  0               );
$res = atan $z0; check(847, 'atan $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   1.10714871779409,  0               );
$res = atan $z0; check(848, 'atan $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  1.40992104959658,  0.22907268296854);
$res = atan $z0; check(849, 'atan $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -1.40992104959658,  0.22907268296854);
$res = atan $z0; check(850, 'atan $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -1.40992104959658, -0.22907268296854);
$res = atan $z0; check(851, 'atan $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  1.40992104959658, -0.22907268296854);
$res = atan $z0; check(852, 'atan $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   2.09439510239320,  0               );
$res = asec $z0; check(853, 'asec $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   3.14159265358979,  0               );
$res = asec $z0; check(854, 'asec $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   3.14159265358979, -1.31695789692482);
$res = asec $z0; check(855, 'asec $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0               ,  1.31695789692482);
$res = asec $z0; check(856, 'asec $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0               ,  0               );
$res = asec $z0; check(857, 'asec $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   1.04719755119660,  0               );
$res = asec $z0; check(858, 'asec $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  1.42041072246703,  0.23133469857397);
$res = asec $z0; check(859, 'asec $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  1.72118193112276,  0.23133469857397);
$res = asec $z0; check(860, 'asec $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  1.72118193112276, -0.23133469857397);
$res = asec $z0; check(861, 'asec $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  1.42041072246703, -0.23133469857397);
$res = asec $z0; check(862, 'asec $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.52359877559830,  0               );
$res = acsc $z0; check(863, 'acsc $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -1.57079632679490,  0               );
$res = acsc $z0; check(864, 'acsc $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -1.57079632679490,  1.31695789692482);
$res = acsc $z0; check(865, 'acsc $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.57079632679490, -1.31695789692482);
$res = acsc $z0; check(866, 'acsc $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.57079632679490,  0               );
$res = acsc $z0; check(867, 'acsc $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.52359877559830,  0               );
$res = acsc $z0; check(868, 'acsc $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.15038560432786, -0.23133469857397);
$res = acsc $z0; check(869, 'acsc $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.15038560432786, -0.23133469857397);
$res = acsc $z0; check(870, 'acsc $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.15038560432786,  0.23133469857397);
$res = acsc $z0; check(871, 'acsc $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.15038560432786,  0.23133469857397);
$res = acsc $z0; check(872, 'acsc $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.46364760900081,  0               );
$res = acot $z0; check(873, 'acot $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.78539816339745,  0               );
$res = acot $z0; check(874, 'acot $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -1.10714871779409,  0               );
$res = acot $z0; check(875, 'acot $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.10714871779409,  0               );
$res = acot $z0; check(876, 'acot $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.78539816339745,  0               );
$res = acot $z0; check(877, 'acot $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.46364760900081,  0               );
$res = acot $z0; check(878, 'acot $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.16087527719832, -0.22907268296854);
$res = acot $z0; check(879, 'acot $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.16087527719832, -0.22907268296854);
$res = acot $z0; check(880, 'acot $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.16087527719832,  0.22907268296854);
$res = acot $z0; check(881, 'acot $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.16087527719832,  0.22907268296854);
$res = acot $z0; check(882, 'acot $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -3.62686040784702,  0               );
$res = sinh $z0; check(883, 'sinh $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -1.17520119364380,  0               );
$res = sinh $z0; check(884, 'sinh $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.52109530549375,  0               );
$res = sinh $z0; check(885, 'sinh $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = sinh $z0; check(886, 'sinh $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.52109530549375,  0               );
$res = sinh $z0; check(887, 'sinh $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.17520119364380,  0               );
$res = sinh $z0; check(888, 'sinh $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   3.62686040784702,  0               );
$res = sinh $z0; check(889, 'sinh $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -3.59056458998578,  0.53092108624852);
$res = sinh $z0; check(890, 'sinh $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  3.59056458998578,  0.53092108624852);
$res = sinh $z0; check(891, 'sinh $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  3.59056458998578, -0.53092108624852);
$res = sinh $z0; check(892, 'sinh $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -3.59056458998578, -0.53092108624852);
$res = sinh $z0; check(893, 'sinh $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   3.76219569108363,  0               );
$res = cosh $z0; check(894, 'cosh $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   1.54308063481524,  0               );
$res = cosh $z0; check(895, 'cosh $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   1.12762596520638,  0               );
$res = cosh $z0; check(896, 'cosh $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   1               ,  0               );
$res = cosh $z0; check(897, 'cosh $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.12762596520638,  0               );
$res = cosh $z0; check(898, 'cosh $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.54308063481524,  0               );
$res = cosh $z0; check(899, 'cosh $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   3.76219569108363,  0               );
$res = cosh $z0; check(900, 'cosh $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -3.72454550491532,  0.51182256998738);
$res = cosh $z0; check(901, 'cosh $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -3.72454550491532, -0.51182256998738);
$res = cosh $z0; check(902, 'cosh $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -3.72454550491532,  0.51182256998738);
$res = cosh $z0; check(903, 'cosh $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -3.72454550491532, -0.51182256998738);
$res = cosh $z0; check(904, 'cosh $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.96402758007582,  0               );
$res = tanh $z0; check(905, 'tanh $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.76159415595576,  0               );
$res = tanh $z0; check(906, 'tanh $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.46211715726001,  0               );
$res = tanh $z0; check(907, 'tanh $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = tanh $z0; check(908, 'tanh $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.46211715726001,  0               );
$res = tanh $z0; check(909, 'tanh $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.76159415595576,  0               );
$res = tanh $z0; check(910, 'tanh $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.96402758007582,  0               );
$res = tanh $z0; check(911, 'tanh $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.96538587902213, -0.00988437503832);
$res = tanh $z0; check(912, 'tanh $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.96538587902213, -0.00988437503832);
$res = tanh $z0; check(913, 'tanh $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.96538587902213,  0.00988437503832);
$res = tanh $z0; check(914, 'tanh $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.96538587902213,  0.00988437503832);
$res = tanh $z0; check(915, 'tanh $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   0.26580222883408,  0               );
$res = sech $z0; check(916, 'sech $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   0.64805427366389,  0               );
$res = sech $z0; check(917, 'sech $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   0.88681888397007,  0               );
$res = sech $z0; check(918, 'sech $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   1               ,  0               );
$res = sech $z0; check(919, 'sech $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.88681888397007,  0               );
$res = sech $z0; check(920, 'sech $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.64805427366389,  0               );
$res = sech $z0; check(921, 'sech $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.26580222883408,  0               );
$res = sech $z0; check(922, 'sech $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -0.26351297515839, -0.03621163655877);
$res = sech $z0; check(923, 'sech $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.26351297515839,  0.03621163655877);
$res = sech $z0; check(924, 'sech $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.26351297515839, -0.03621163655877);
$res = sech $z0; check(925, 'sech $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -0.26351297515839,  0.03621163655877);
$res = sech $z0; check(926, 'sech $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.27572056477178,  0               );
$res = csch $z0; check(927, 'csch $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.85091812823932,  0               );
$res = csch $z0; check(928, 'csch $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -1.91903475133494,  0               );
$res = csch $z0; check(929, 'csch $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.91903475133494,  0               );
$res = csch $z0; check(930, 'csch $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.85091812823932,  0               );
$res = csch $z0; check(931, 'csch $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.27572056477178,  0               );
$res = csch $z0; check(932, 'csch $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx( -0.27254866146294, -0.04030057885689);
$res = csch $z0; check(933, 'csch $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  0.27254866146294, -0.04030057885689);
$res = csch $z0; check(934, 'csch $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  0.27254866146294,  0.04030057885689);
$res = csch $z0; check(935, 'csch $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx( -0.27254866146294,  0.04030057885689);
$res = csch $z0; check(936, 'csch $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -1.03731472072755,  0               );
$res = coth $z0; check(937, 'coth $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -1.31303528549933,  0               );
$res = coth $z0; check(938, 'coth $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -2.16395341373865,  0               );
$res = coth $z0; check(939, 'coth $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   2.16395341373865,  0               );
$res = coth $z0; check(940, 'coth $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   1.31303528549933,  0               );
$res = coth $z0; check(941, 'coth $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   1.03731472072755,  0               );
$res = coth $z0; check(942, 'coth $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  1.03574663776500,  0.01060478347034);
$res = coth $z0; check(943, 'coth $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -1.03574663776500,  0.01060478347034);
$res = coth $z0; check(944, 'coth $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -1.03574663776500, -0.01060478347034);
$res = coth $z0; check(945, 'coth $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  1.03574663776500, -0.01060478347034);
$res = coth $z0; check(946, 'coth $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -1.44363547517881,  0               );
$res = asinh $z0; check(947, 'asinh $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.88137358701954,  0               );
$res = asinh $z0; check(948, 'asinh $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.48121182505960,  0               );
$res = asinh $z0; check(949, 'asinh $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = asinh $z0; check(950, 'asinh $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.48121182505960,  0               );
$res = asinh $z0; check(951, 'asinh $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.88137358701954,  0               );
$res = asinh $z0; check(952, 'asinh $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   1.44363547517881,  0               );
$res = asinh $z0; check(953, 'asinh $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  1.96863792579310,  0.96465850440760);
$res = asinh $z0; check(954, 'asinh $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -1.96863792579310,  0.96465850440761);
$res = asinh $z0; check(955, 'asinh $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -1.96863792579310, -0.96465850440761);
$res = asinh $z0; check(956, 'asinh $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  1.96863792579310, -0.96465850440760);
$res = asinh $z0; check(957, 'asinh $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   1.31695789692482,  3.14159265358979);
$res = acosh $z0; check(958, 'acosh $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   0,                 3.14159265358979);
$res = acosh $z0; check(959, 'acosh $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   0,                 2.09439510239320);
$res = acosh $z0; check(960, 'acosh $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0,                 1.57079632679490);
$res = acosh $z0; check(961, 'acosh $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0,                 1.04719755119660);
$res = acosh $z0; check(962, 'acosh $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0               ,  0               );
$res = acosh $z0; check(963, 'acosh $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   1.31695789692482,  0               );
$res = acosh $z0; check(964, 'acosh $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  1.98338702991654,  1.00014354247380);
$res = acosh $z0; check(965, 'acosh $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  1.98338702991653,  2.14144911111600);
$res = acosh $z0; check(966, 'acosh $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  1.98338702991653, -2.14144911111600);
$res = acosh $z0; check(967, 'acosh $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  1.98338702991654, -1.00014354247380);
$res = acosh $z0; check(968, 'acosh $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.54930614433405,  1.57079632679490);
$res = atanh $z0; check(969, 'atanh $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.54930614433405,  0               );
$res = atanh $z0; check(970, 'atanh $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.0,0);
$z1 = cplx(   0               ,  0               );
$res = atanh $z0; check(971, 'atanh $z0', $res, $z1, '( 0.0,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.54930614433405,  0               );
$res = atanh $z0; check(972, 'atanh $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.54930614433405,  1.57079632679490);
$res = atanh $z0; check(973, 'atanh $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.14694666622553,  1.33897252229449);
$res = atanh $z0; check(974, 'atanh $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.14694666622553,  1.33897252229449);
$res = atanh $z0; check(975, 'atanh $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.14694666622553, -1.33897252229449);
$res = atanh $z0; check(976, 'atanh $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.14694666622553, -1.33897252229449);
$res = atanh $z0; check(977, 'atanh $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(   0               , 2.09439510239320);
$res = asech $z0; check(978, 'asech $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(   0               , 3.14159265358979);
$res = asech $z0; check(979, 'asech $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(   1.31695789692482, 3.14159265358979);
$res = asech $z0; check(980, 'asech $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.31695789692482, 0               );
$res = asech $z0; check(981, 'asech $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0               , 0               );
$res = asech $z0; check(982, 'asech $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0               , 1.04719755119660);
$res = asech $z0; check(983, 'asech $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.23133469857397, -1.42041072246703);
$res = asech $z0; check(984, 'asech $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx(  0.23133469857397, -1.72118193112276);
$res = asech $z0; check(985, 'asech $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx(  0.23133469857397,  1.72118193112276);
$res = asech $z0; check(986, 'asech $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.23133469857397,  1.42041072246703);
$res = asech $z0; check(987, 'asech $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.48121182505960, 0               );
$res = acsch $z0; check(988, 'acsch $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-1.0,0);
$z1 = cplx(  -0.88137358701954, 0               );
$res = acsch $z0; check(989, 'acsch $z0', $res, $z1, '(-1.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -1.44363547517881, 0               );
$res = acsch $z0; check(990, 'acsch $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   1.44363547517881, 0               );
$res = acsch $z0; check(991, 'acsch $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 1.0,0);
$z1 = cplx(   0.88137358701954, 0               );
$res = acsch $z0; check(992, 'acsch $z0', $res, $z1, '( 1.0,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.48121182505960, 0               );
$res = acsch $z0; check(993, 'acsch $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.15735549884499, -0.22996290237721);
$res = acsch $z0; check(994, 'acsch $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.15735549884499, -0.22996290237721);
$res = acsch $z0; check(995, 'acsch $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.15735549884499,  0.22996290237721);
$res = acsch $z0; check(996, 'acsch $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.15735549884499,  0.22996290237721);
$res = acsch $z0; check(997, 'acsch $z0', $res, $z1, '( 2,-3)');
$z0 = cplx(-2.0,0);
$z1 = cplx(  -0.54930614433405, 0               );
$res = acoth $z0; check(998, 'acoth $z0', $res, $z1, '(-2.0,0)');
$z0 = cplx(-0.5,0);
$z1 = cplx(  -0.54930614433405, 1.57079632679490);
$res = acoth $z0; check(999, 'acoth $z0', $res, $z1, '(-0.5,0)');
$z0 = cplx( 0.5,0);
$z1 = cplx(   0.54930614433405, 1.57079632679490);
$res = acoth $z0; check(1000, 'acoth $z0', $res, $z1, '( 0.5,0)');
$z0 = cplx( 2.0,0);
$z1 = cplx(   0.54930614433405, 0               );
$res = acoth $z0; check(1001, 'acoth $z0', $res, $z1, '( 2.0,0)');
$z0 = cplx( 2, 3);
$z1 = cplx(  0.14694666622553, -0.23182380450040);
$res = acoth $z0; check(1002, 'acoth $z0', $res, $z1, '( 2, 3)');
$z0 = cplx(-2, 3);
$z1 = cplx( -0.14694666622553, -0.23182380450040);
$res = acoth $z0; check(1003, 'acoth $z0', $res, $z1, '(-2, 3)');
$z0 = cplx(-2,-3);
$z1 = cplx( -0.14694666622553,  0.23182380450040);
$res = acoth $z0; check(1004, 'acoth $z0', $res, $z1, '(-2,-3)');
$z0 = cplx( 2,-3);
$z1 = cplx(  0.14694666622553,  0.23182380450040);
$res = acoth $z0; check(1005, 'acoth $z0', $res, $z1, '( 2,-3)');
{
    my $z = cplx(  1,  1);
    $z->Re(2);
    $z->Im(3);
    print OUT "# $test Re(z) = ",$z->Re(), " Im(z) = ", $z->Im(), " z = $z\n";
    print OUT 'not ' unless Re($z) == 2 and Im($z) == 3;
print OUT "ok 1006\n"}
{
    my $z = cplx(  1,  1);
    $z->abs(3 * sqrt(2));
    print OUT "# $test Re(z) = ",$z->Re(), " Im(z) = ", $z->Im(), " z = $z\n";
    print OUT 'not ' unless (abs($z) - 3 * sqrt(2)) < $eps and
                        (arg($z) - pi / 4     ) < $eps and
                        (Re($z) - 3           ) < $eps and
                        (Im($z) - 3           ) < $eps;
print OUT "ok 1007\n"}
{
    my $z = cplx(  1,  1);
    $z->arg(-3 / 4 * pi);
    print OUT "# $test Re(z) = ",$z->Re(), " Im(z) = ", $z->Im(), " z = $z\n";
    print OUT 'not ' unless (arg($z) + 3 / 4 * pi) < $eps and
                        (abs($z) - sqrt(2)   ) < $eps and
                        (Re($z) + 1          ) < $eps and
                        (Im($z) + 1          ) < $eps;
print OUT "ok 1008\n"}

my $i    = cplx(0,  1);
my $pi   = cplx(pi, 0);
my $pii  = cplx(0, pi);
my $pip2 = cplx(pi/2, 0);
my $pip4 = cplx(pi/4, 0);
my $zero = cplx(0, 0);
my $inf  = 9**9**9;
	eval 'i/0';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1009 op = i/0 divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1009\n";
	eval 'acot(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1010 op = acot(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1010\n";
	eval 'acot(+$i)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1011 op = acot(+$i) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1011\n";
	eval 'acoth(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1012 op = acoth(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1012\n";
	eval 'acoth(+1)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1013 op = acoth(+1) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1013\n";
	eval 'acsc(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1014 op = acsc(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1014\n";
	eval 'acsch(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1015 op = acsch(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1015\n";
	eval 'asec(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1016 op = asec(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1016\n";
	eval 'asech(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1017 op = asech(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1017\n";
	eval 'atan($i)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1018 op = atan($i) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1018\n";
	eval 'atanh(+1)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1019 op = atanh(+1) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1019\n";
	eval 'cot(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1020 op = cot(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1020\n";
	eval 'coth(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1021 op = coth(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1021\n";
	eval 'csc(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1022 op = csc(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1022\n";
	eval 'csch(0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1023 op = csch(0) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1023\n";
	eval 'atan(cplx(0, 1), cplx(1, 0))';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1024 op = atan(cplx(0, 1), cplx(1, 0)) divbyzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Division by zero/);
print OUT "ok 1024\n";
	eval 'log($zero)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1025 op = log($zero) logofzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Logarithm of zero/);
print OUT "ok 1025\n";
	eval 'atan(-$i)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1026 op = atan(-$i) logofzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Logarithm of zero/);
print OUT "ok 1026\n";
	eval 'acot(-$i)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1027 op = acot(-$i) logofzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Logarithm of zero/);
print OUT "ok 1027\n";
	eval 'atanh(-1)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1028 op = atanh(-1) logofzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Logarithm of zero/);
print OUT "ok 1028\n";
	eval 'acoth(-1)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1029 op = acoth(-1) logofzero? $bad...
";
	print OUT 'not ' unless ($@ =~ /Logarithm of zero/);
print OUT "ok 1029\n";
	eval 'root(2, -3)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1030 op = -3 badroot? $bad...
";
	print OUT 'not ' unless ($@ =~ /root rank must be/);
print OUT "ok 1030\n";
	eval 'root(2, -2.1)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1031 op = -2.1 badroot? $bad...
";
	print OUT 'not ' unless ($@ =~ /root rank must be/);
print OUT "ok 1031\n";
	eval 'root(2, 0)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1032 op = 0 badroot? $bad...
";
	print OUT 'not ' unless ($@ =~ /root rank must be/);
print OUT "ok 1032\n";
	eval 'root(2, 0.99)';
	($bad) = ($@ =~ /(.+)/);
	print OUT "# 1033 op = 0.99 badroot? $bad...
";
	print OUT 'not ' unless ($@ =~ /root rank must be/);
print OUT "ok 1033\n";
    print OUT "# package display_format cartesian?
";
    print OUT "not " unless Math::Complex->display_format eq 'cartesian';
    print OUT "ok 1034
";
    my $j = (root(1,3))[1];

    $j->display_format('polar');
    print OUT "# j display_format polar?
";
    print OUT "not " unless $j->display_format eq 'polar';
    print OUT "ok 1035
";
    print OUT "# j = $j
";
    print OUT "not " unless "$j" eq "[1,2pi/3]" or "$j" eq "[1.0,2pi/3]";	# SNOOPYJC
    print OUT "ok 1036
";

    my %display_format;

    %display_format = $j->display_format;
    print OUT "# display_format{style} polar?
";
    print OUT "not " unless $display_format{style} eq 'polar';
    print OUT "ok 1037
";
    print OUT "# keys %display_format == 2?
";
    print OUT "not " unless keys %display_format == 2;
    print OUT "ok 1038
";

    $j->display_format('style' => 'cartesian', 'format' => '%.5f');
    print OUT "# j = $j
";
    print OUT "not " unless "$j" eq "-0.50000+0.86603i";
    print OUT "ok 1039
";

    %display_format = $j->display_format;
    print OUT "# display_format{format} %.5f?
";
    print OUT "not " unless $display_format{format} eq '%.5f';
    print OUT "ok 1040
";
    print OUT "# keys %display_format == 3?
";
    print OUT "not " unless keys %display_format == 3;
    print OUT "ok 1041
";

    $j->display_format('format' => undef);
    print OUT "# j = $j
";
    print OUT "not " unless "$j" =~ /^-0(?:\.5(?:0000\d+)?|\.49999\d+)\+0.86602540\d+i$/;
    print OUT "ok 1042
";

    $j->display_format('style' => 'polar', 'polar_pretty_print' => 0);
    print OUT "# j = $j
";
    print OUT "not " unless "$j" =~ /^\[1,2\.09439510\d+\]$/ or "$j" =~ /^\[1\.0,2\.09439510\d+\]$/;  # SNOOPYJC
    print OUT "ok 1043
";

    $j->display_format('style' => 'polar', 'format' => "%.4g");
    print OUT "# j = $j
";
    print OUT "not " unless "$j" =~ /^\[1,2\.094\]$/;
    print OUT "ok 1044
";

    $j->display_format('style' => 'cartesian', 'format' => '(%.5g)');
    print OUT "# j = $j
";
    print OUT "not " unless "$j" eq "(-0.5)+(0.86603)i";
    print OUT "ok 1045
";
    print OUT "# j display_format cartesian?
";
    print OUT "not " unless $j->display_format eq 'cartesian';
    print OUT "ok 1046
";
    print OUT "# remake 2+3i
";
    $z = cplx('2+3i');
    print OUT "not " unless $z == Math::Complex->make(2,3);
    print OUT "ok 1047
";
    print OUT "# make 3i
";
    $z = Math::Complex->make('3i');
    print OUT "not " unless $z == cplx(0,3);
    print OUT "ok 1048
";
    print OUT "# emake [2,3]
";
    $z = Math::Complex->emake('[2,3]');
    print OUT "not " unless $z == cplxe(2,3);
    print OUT "ok 1049
";
    print OUT "# make (2,3)
";
    $z = Math::Complex->make('(2,3)');
    print OUT "not " unless $z == cplx(2,3);
    print OUT "ok 1050
";
    print OUT "# emake [2,3pi/8]
";
    $z = Math::Complex->emake('[2,3pi/8]');
# SNOOPYJC: Bug in the test!    print OUT "not " unless $z == cplxe(2,3*$pi/8);
    print OUT "not " unless $z == cplxe(2,3*pi/8);	# SNOOPYJC
    print OUT "ok 1051
";
    print OUT "# emake [2]
";
    $z = Math::Complex->emake('[2]');
    print OUT "not " unless $z == cplxe(2);
    print OUT "ok 1052
";
{
    print OUT "# cplx, cplxe, make, emake without arguments\n";
    my $z0 = cplx();
    print OUT (($z0->Re()  == 0) ? "ok 1053
" : "not ok 1053
");
    print OUT (($z0->Im()  == 0) ? "ok 1054
" : "not ok 1054
");
    my $z1 = cplxe();
    print OUT (($z1->rho()   == 0) ? "ok 1055
" : "not ok 1055
");
    print OUT (($z1->theta() == 0) ? "ok 1056
" : "not ok 1056
");
    my $z2 = Math::Complex->make();
    print OUT (($z2->Re()  == 0) ? "ok 1057
" : "not ok 1057
");
    print OUT (($z2->Im()  == 0) ? "ok 1058
" : "not ok 1058
");
    my $z3 = Math::Complex->emake();
    print OUT (($z3->rho()   == 0) ? "ok 1059
" : "not ok 1059
");
    print OUT (($z3->theta() == 0) ? "ok 1060
" : "not ok 1060
");
}
print OUT "# atan2() with some real arguments\n";
print OUT ((Math::Complex::atan2(-1, -1) == CORE::atan2(-1, -1)) ? "ok 1061
" : "not ok 1061
");
print OUT ((Math::Complex::atan2(0, -1) == CORE::atan2(0, -1)) ? "ok 1062
" : "not ok 1062
");
print OUT ((Math::Complex::atan2(1, -1) == CORE::atan2(1, -1)) ? "ok 1063
" : "not ok 1063
");
print OUT ((Math::Complex::atan2(-1, 0) == CORE::atan2(-1, 0)) ? "ok 1064
" : "not ok 1064
");
print OUT ((Math::Complex::atan2(1, 0) == CORE::atan2(1, 0)) ? "ok 1065
" : "not ok 1065
");
print OUT ((Math::Complex::atan2(-1, 1) == CORE::atan2(-1, 1)) ? "ok 1066
" : "not ok 1066
");
print OUT ((Math::Complex::atan2(0, 1) == CORE::atan2(0, 1)) ? "ok 1067
" : "not ok 1067
");
print OUT ((Math::Complex::atan2(1, 1) == CORE::atan2(1, 1)) ? "ok 1068
" : "not ok 1068
");
    print OUT "# atan2() with some complex arguments\n";
    print OUT (abs(atan2(0, cplx(0, 1))) < 1e-13 ? "ok 1069
" : "not ok 1069
");
    print OUT (abs(atan2(cplx(0, 1), 0) - $pip2) < 1e-13 ? "ok 1070
" : "not ok 1070
");
    print OUT (abs(atan2(cplx(0, 1), cplx(0, 1)) - $pip4) < 1e-13 ? "ok 1071
" : "not ok 1071
");
    print OUT (abs(atan2(cplx(0, 1), cplx(1, 1)) - cplx(0.553574358897045, 0.402359478108525)) < 1e-13 ? "ok 1072
" : "not ok 1072
");

close(OUT);
open(OUT, '<', 'test_complex.out') or die "Can't read test_complex.out";
my @lines = <OUT>;
my $passed = 1;
for my $line (@lines) {
	#chomp $line;
	if($line =~ /^not ok/) {
		print $line;
		$passed = 0;
	}
}
close(OUT);
if($passed) {
	print "$0 - test passed!\n";
	unlink "test_complex.out";
} else {
	print "$0 - test failed! - see test_complex.out vs test_complex.expected\n";
	exit 1;
}

sub value {
	local ($_) = @_;
	if (/^\s*\((.*),(.*)\)/) {
		return "cplx($1,$2)";
	}
	elsif (/^\s*([\-\+]?(?:\d+(\.\d+)?|\.\d+)(?:[e[\-\+]\d+])?)/) {
		return "cplx($1,0)";
	}
	elsif (/^\s*\[(.*),(.*)\]/) {
		return "cplxe($1,$2)";
	}
	elsif (/^\s*'(.*)'/) {
		my $ex = $1;
		$ex =~ s/\bz\b/$target/g;
		$ex =~ s/\br\b/abs($target)/g;
		$ex =~ s/\bt\b/arg($target)/g;
		$ex =~ s/\ba\b/Re($target)/g;
		$ex =~ s/\bb\b/Im($target)/g;
		return $ex;
	}
	elsif (/^\s*"(.*)"/) {
		return "\"$1\"";
	}
	return $_;
}

sub check {
	my ($test, $try, $got, $expected, @z) = @_;

	print OUT "# @_\n";

	if ("$got" eq "$expected"
	    ||
	    ($expected =~ /^-?\d/ && $got == $expected)
	    ||
	    (abs(Math::Complex->make($got) - Math::Complex->make($expected)) < $eps)
	    ||
	    (abs($got - $expected) < $eps)
	    ) {
		print OUT "ok $test\n";
	} else {
		print OUT "not ok $test\n";
		my $args = (@z == 1) ? "z = $z[0]" : "z0 = $z[0], z1 = $z[1]";
		print OUT "# '$try' expected: '$expected' got: '$got' for $args\n";
	}
}

sub addsq {
    my ($z1, $z2) = @_;
    return ($z1 + i*$z2) * ($z1 - i*$z2);
}

sub subsq {
    my ($z1, $z2) = @_;
    return ($z1 + $z2) * ($z1 - $z2);
}
