#! /usr/bin/perl

use Getopt::Long;
use Carp::Assert;
%options = ();
@ARGV=qw/-d D --maxage 2.5 --cttage 42.2 --debug --inc --inc --num --three 1 2 3 --var 5 6 --arr 0 --arr 1 --arr 2/;
GetOptions(\%options,"dir|d:s","maxage:f","cttage=f","debug!","inc+","num:42",'three=i@{3}','var:i@{,}',"arr:i@");
#print %options;
assert($options{dir} eq 'D');
assert($options{maxage} == 2.5);
assert($options{cttage} == 42.2);
assert($options{debug});
assert($options{inc} == 2);
assert($options{num} == 42);
@three = @{$options{three}};
assert(scalar(@three) == 3 && $three[0] == 1 && $three[1] == 2 && $three[2] == 3);
@var = @{$options{var}};
assert(scalar(@var) == 2 && $var[0] == 5 && $var[1] == 6);
@arr = @{$options{arr}};
assert(scalar(@arr) == 3 && $arr[0] == 0 && $arr[1] == 1 && $arr[2] == 2);
my $Test=0;
my $Dev=0;
my $table='';
my $dscHostFromCmdLine='';
my $DEBUG=0;
my $num=0;
my $inc=0;
@ARGV=qw/--test --table TABLE --nodebug --inc --inc --num/;
GetOptions('test' => \$Test, 'dev' => \$Dev, 'table=s' => \$table, 'dschost:s' => \$dscHostFromCmdLine, 'debug!' => \$DEBUG, 'inc+' => \$inc,
	'num:42' => \$num);
#print "$Test, $Dev, $table, $dscHostFromCmdLine, $DEBUG, $inc, $num, @two\n";
assert($Test);
assert($Dev == 0);
assert($table eq 'TABLE');
assert($dscHostFromCmdLine eq '');
assert(!$DEBUG);
assert($inc == 2);
assert($num == 42);
print "$0 - test passed!\n";
