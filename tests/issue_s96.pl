# issue s96 - missing type conversion in complex ? : expression
# Issue from cbbtm.pl
use Carp::Assert;

sub postprocess {
  my $measuredsum = 0;
  my $flowload = '2';
  for my $snmpload ('-1', '0', '1') {
      $measuredsum += ($snmpload>=0) ? $snmpload:$flowload;
  }
  assert($measuredsum == 3);
}

postprocess();
print "$0 - test passed!\n";
