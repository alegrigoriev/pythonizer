# Test issue with @failmsg (from cmt)

sub do_hour {
	push @failmsg,"$0 - test passed!\n" if 1;
}

do_hour();

print "@failmsg" if (@failmsg);
