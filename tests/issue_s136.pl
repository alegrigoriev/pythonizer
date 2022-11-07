# issue s136: for loop with ++ctr at the end generates bad code
use Carp::Assert;

$BACKUP_LOOKBACK_DAYS=3;
for ( my $nday = 1; $nday <= $BACKUP_LOOKBACK_DAYS; ++$nday ){
    $tot++;
}
assert($tot == 3);

for ( my $nday = $BACKUP_LOOKBACK_DAYS; $nday; --$nday ){
    $tot--;
}
assert($tot == 0);

for ( my $nday = 1; $nday <= $BACKUP_LOOKBACK_DAYS; ++$nday ){
    $tot++;
    if($nday == 2) {$nday = 12}       # conditionally modify the loop counter
}
assert($tot == 2);

print "$0 - test passed\n";

