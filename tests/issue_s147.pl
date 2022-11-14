# issue s147 - multiple do{...} until(...) with nested trailing 'if' does not translate properly
# code from netdb/fathom/components/src/waitFathom.pl
use Carp::Assert;

# Start by trying some normal cases
do {
    assert(0);
} if 0;

do {
    $done = 1;
} if 1;

assert($done == 1);

# Now a simplified case
do {
    $done = 2;
} until($done == 2);

$done = 3 if 0;

assert($done == 2);

do {
    $done = 3;
} while($done != 3);
assert($done == 3);

sub debug_print {}

my @my_proc_file_list = ('f1', 'f2');
my $max_number_retries = 2;
my $number_retries = 0;
my $tot = 0;
my $FILE_CHECK = 1;
my $my_cmd_cycles = 0;
my $CMD_CYCLES = 2;
my $end_process_cmd = 'oops';

# Now for the real issue

do {
    my $elem = pop @my_proc_file_list;
    assert($elem =~ /^f[12]$/);
    for(my $i = 0; $i <= 2; $i++) {
        $my_check = 0;
        until ($my_check == $FILE_CHECK) {
            $my_check++;
        }
    }
    $tot++;
    sleep $sleep_time;
}until ($#my_proc_file_list == -1 || $number_retries==$max_number_retries);

debug_print "MAIN";

if ($how_many_files_we_got==$total_files) {
    debug_print "MAIN";


    $my_cmd_cycles=0;

    ###### lets do final cmd line

    do
     {
        # NOTE: Somehow this next line is messing up the prior do block!
        sleep $CMD_WAIT_SECONDS if ($my_cmd_cycles>0);

        $my_cmd_cycles++;

        debug_print "PROC -- process";
        debug_print "PROC -- sleep";

        #$ret_code=system($end_process_cmd);
        #$ret_code=~$?>>8;
        $ret_code = 1;

     }
        until (!$ret_code || $my_cmd_cycles == $CMD_CYCLES);

        assert($my_cmd_cycles == $CMD_CYCLES);
        debug_print "PROC -- process";
}


assert($tot == 2);

print "$0 - test passed\n";

