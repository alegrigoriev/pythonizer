# issue s247 - exec { $0 } @args; generates bad code
# causes loop?
use Carp::Assert;
my $script = $0; 

# Array of arguments passed to the script
my @args = @ARGV;

# The command to be executed
my $command = "/usr/bin/command";

# Execute the command
exec { $command } $script, @args;
assert ( not ($@));
print "$0 - test passed!\n";
