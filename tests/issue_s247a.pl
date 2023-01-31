#!/usr/bin/perl
# issue s247a - exec { $0 } @args; generates bad code

if(scalar(@ARGV)) {        # We are being exec'd
    print "$0 - test passed!\n";
} else {
    my $program = "./$0";
    my @args = ($0, '-e');
    #print "exec { $program } @args\n";
    if(substr($program, 0, 4) eq '././') {
        print "test failed - exec recursive loop!\n";
        exit 1;
    }
    exec { $program } @args;
    print "exec failed!! $!\n";
}
