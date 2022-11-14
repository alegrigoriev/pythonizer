# issue s157 - Multi-array assignment generates bad code
use Carp::Assert;

@selected_lines = @sorted_lines = '';

assert(scalar(@selected_lines) == 1);
assert($selected_lines[0] eq '');
assert(scalar(@sorted_lines) == 1);
assert($sorted_lines[0] eq '');

my @mismatch_counts = (1,2);

@discord_counts_cisco = @discord_counts_alu = @mismatch_counts;
assert(@discord_counts_cisco == 2);
assert(@discord_counts_alu == 2);
assert(@mismatch_counts == 2);
assert($mismatch_counts[0] == 1);
assert($mismatch_counts[1] == 2);
assert($discord_counts_cisco[0] == 1);
assert($discord_counts_cisco[1] == 2);
assert($discord_counts_alu[0] == 1);
assert($discord_counts_alu[1] == 2);


print "$0 - test passed!\n";
