# Test require

# Try some version require, which should be ignored
require v5.24.1;
require 5.24.1;
require 5.024_001;

# Now some real ones
use File::Basename;
use lib dirname($0);

require q(./test_basename.pl);
is('this', 'this');
require "./" . "test_basename" . ".pl";
is('this', 'this');
my $test_basename = "test_basename";
require "../tests/$test_basename.pl";
is('this', 'this');
my $tb = "test_basename.pl";
require $tb;
is('this', 'this');
$_ = $tb;
require;
is('this', 'this');
require 'test_basename.pl';
is('this', 'this');

$cwd = `pwd`;
chomp $cwd;
require "$cwd/test_basename.pl";

is('this', 'this');

like('this', 'this');

eval {
    require notfound;
};
#print "\$@ = $@\n";
assert($@ =~ /^Can't locate notfound/ || $@ =~ /^No module named 'notfound'/);
assert($@ =~ /at test_require/);
assert($@ =~ / line /);

eval {
    require "subdir/file_not_found.pl";
};
assert($@ =~ m(^Can't locate subdir/file_not_found.p));
assert($@ =~ /at test_require/);
assert($@ =~ / line /);

done_testing();
