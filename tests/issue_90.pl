# issue 90 - Regex inside subscript generates bad code
use Carp::Assert;

$key = 'kkey';
for(my $i = 0; $i < 25; $i++) {
    push @line, "line $i";
}
$dir = 'myagnip';
$interfaces{$key}{vrf} = $line[($dir =~ /agnip$/) ? 21:24];
assert($interfaces{$key}{vrf} eq 'line 21');
$dir = 'm';
$interfaces{$key}{vrf} = $line[($dir =~ /agnip$/) ? 21:24];
assert($interfaces{$key}{vrf} eq 'line 24');

print "$0 - test passed!\n";
