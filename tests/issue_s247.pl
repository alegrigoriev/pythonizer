# issue s247 - exec { $0 } @args; generates bad code

my @args = ('echo', $0, "- test passed");

exec { $args[0] } @args;
