# issue s62 - DB::single=1; shouldn't cause a pdb breakpoint if debugger is not active

$DB::single = 1;
print "$0 - test passed!\n";
