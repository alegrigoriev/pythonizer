# issue s246 - Mod (%) operator mistaken as a hash name

use Carp::Assert;

my %scalar = (key=>'value');
sub mysub { 4 }

@cluster_names = ('cluster1', 'cluster2', 'cluster3');
$cluster_number = 0;

# This time it's a mod operator:
$remote_cluster = $cluster_names[($cluster_number + 1) % scalar(@cluster_names)];
assert($remote_cluster eq 'cluster2');

$cluster_number++;

# Another mod operator:
$remote_cluster = $cluster_names[($cluster_number + 1) % scalar @cluster_names];
assert($remote_cluster eq 'cluster3');

$cluster_number++;

# Yet another mod operator:
$remote_cluster = $cluster_names[($cluster_number + 1) % @cluster_names];
assert($remote_cluster eq 'cluster1');

# mod again:
$remote_cluster = $cluster_names[$cluster_number%@cluster_names];
assert($remote_cluster eq 'cluster3');

# All operators here:
my $i = 25 % @cluster_names;
assert($i == 1);
$i %= @cluster_names;
assert($i == 1);
$i = 7;
$i &= @cluster_names;
assert($i == 3);
$i = 7;
$i = $i & @cluster_names;
$i = 1;
$i |= @cluster_names;
assert($i == 3);
$i = 1;
$i = $i | @cluster_names;
assert($i == 3);
assert(@cluster_names % 4 == 3);

# This time it's a hash (with an extra space before the varname):
my $val = \ % scalar;
assert($val->{key} eq 'value');

# Now we have a mod and a hash cast!
assert(5 %% $val == 0);

# This time it's a binary and operator:
my $i = 5 & mysub;
assert($i == 4);

# This time it's a sub sigil
*ms = \ & mysub;
assert(ms() == 4);

print "$0 - test passed!\n";
