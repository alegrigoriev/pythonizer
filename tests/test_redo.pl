# Test using 'redo' via an example from stackoverflow
use Carp::Assert;
sub APPLES { 100 };
sub EPS { 1E-6 };

my @sent = ();

sub sendit
{
    my @basket = @_;

    #print "Sending basket with weight " . weight(@basket) . "\n";
    push @sent, "" . scalar(@basket) . "," . weight(@basket);
}

sub weight
{
    my $sum = 0;
    foreach my $item (@_) {
        $sum += $item;
    }
    #print("weight(@_) = $sum\n");
    return $sum;

}

my @tree = ();

for(my $i = 0; $i<APPLES; $i++) {
    push @tree, ((rand) + 0.5)
}
my $apple_count = scalar(@tree);
assert($apple_count == APPLES);
my $total_weight = 0;
foreach my $apple_weight (@tree) {
    $total_weight += $apple_weight;
}

my @basket = ();

while ($apple = shift(@tree)) {
  $wt = weight($apple);
  if ($wt + weight(@basket) > 10) {
    sendit(@basket);
    @basket = ();
    redo;
  } else {
    push(@basket, $apple);
  }
}

sendit(@basket) if(weight(@basket));

#print "For $apple_count apples, with total weight $total_weight, sent = @sent\n";
my $count_sent = 0;
my $weight_sent = 0;
foreach my $s (@sent) {
    my ($c, $w) = split /,/, $s;
    $count_sent += $c;
    $weight_sent += $w;
}
#print "count_sent=$count_sent, weight_sent=$weight_sent\n";
assert($count_sent == APPLES);
assert(abs($weight_sent - $total_weight) < EPS);

print "$0 - test passed!";
