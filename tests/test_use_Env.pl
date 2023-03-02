#!/usr/bin/perl
use Carp::Assert;
use Env;

$save_PATH = $ENV{PATH};
$save_HOME;
$save_HOME = $ENV{HOME} if exists $ENV{HOME};

# Check if the PATH environment variable is set and access value
assert($PATH, "Nothing in \$PATH");
assert($PATH eq $ENV{PATH}, "Path is not correct: is $PATH, not $ENV{PATH}");


# Split Value Into Array of Directories
my @path = split(/:/, $PATH);
# print ("$PATH\n");
assert (@path);

#Modify value using push
use Env qw(@PATH);
push @PATH, '/new/path';
my $new_path = join(":", @PATH);
assert ($new_path =~ /\/new\/path$/);

#Modify value using .=
use Env qw(PATH);
$PATH .= ":/any/path";
assert ($PATH =~ /\/any\/path$/);

# Remove a value tied to Env by assigning it undef
if (exists $ENV{HOME}) {
    assert ($HOME eq $ENV{HOME}, "bad home: $HOME ne $ENV{HOME}");
    $HOME = undef;
    assert (!defined $HOME);
    assert(!defined $ENV{HOME});
    $ENV{HOME} = $save_HOME;
    untie $HOME;
    $HOME = 'my home sweet home';
    assert($ENV{HOME} ne $HOME, "Untieing $HOME by setting it to undef didn't work");
}

$PATH = undef;
assert (!defined $ENV{PATH}, "Undefining $PATH didn't clear \$ENV{PATH}");

END {
    $ENV{PATH} = $save_PATH;
    $ENV{HOME} = $save_HOME if defined $save_HOME;
}

print "$0 - test passed!\n";
