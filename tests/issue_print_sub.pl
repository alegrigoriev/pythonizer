# issue print a sub generates wrong code

sub passed { "$0 - test passed!\n"; }

sub print_passed { print &passed }

print_passed;
