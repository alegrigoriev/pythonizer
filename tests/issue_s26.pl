# issue s26 - multiple anonymous subroutines on the same line all get the same name
use Carp::Assert;

$force = "MSWin32";
*_FORCE_WRITABLE1 = (
    grep { $force eq $_ } qw(amigaos dos epoc MSWin32 MacOS os2)
  ) ? sub () { 1 } : sub () { 0 };

assert(_FORCE_WRITABLE1() == 1);

$force = "unix";
*_FORCE_WRITABLE0 = (
    grep { $force eq $_ } qw(amigaos dos epoc MSWin32 MacOS os2)
  ) ? sub () { 1 } : sub () { 0 };

assert(_FORCE_WRITABLE0() == 0);

for(my $i = 0; $i < 3; $i++) {
    *TRINARY = ($i == 0 ? sub {0} : ($i == 1 ? sub {1} : sub {2}));

    assert(TRINARY() == $i);
}

print "$0 - test passed!\n";
