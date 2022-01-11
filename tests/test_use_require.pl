# Test use and require

# Try some version use/require, which should be ignored
use v5.24.1;
use 5.24.1;
use 5.024_001;
require v5.24.1;
require 5.24.1;
require 5.024_001;

# Some built-in ones that we should also ignore
use strict;
use warnings;
use vars qw($var1 @var2 %var3);
use Getopt::Long;
use Time::Local;
use File::Basename;
use Fcntl qw(:flock);
use Exporter qw(import);
use Carp::Assert;

# Now some real ones
use lib dirname($0);

use test qw(is done_testing);

#eval {
#    like('this', 'this');
#};
#assert($@ =~ /^Undefined subroutine/);

#use test qw(:all);

require 'test_basename.pl';

is('this', 'this');

like('this', 'this');

done_testing();
