# Part of test_global_fh

use Carp::Assert;

print FH "test global data\n";

$pr = eval {
    $print_result = (print LCL "oops");
    return $print_result;
};
assert(!$pr || $@);     # In python, we'll get an undefined variable error

1;
