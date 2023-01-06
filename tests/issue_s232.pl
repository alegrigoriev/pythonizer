# issue s232 - Hash slice assignment to list of vars generates bad code
use Carp::Assert;
use Config;

($dl_dlext, $dl_so, $dlsrc) = @Config::Config{qw(dlext so dlsrc)};

assert("$dl_dlext, $dl_so, $dlsrc" eq 'dll, dll, dl_dlopen.xs');

print "$0 - test passed!\n";
