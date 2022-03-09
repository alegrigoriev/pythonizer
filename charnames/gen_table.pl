# Generate a table of the chars that are missing

use charnames qw/:full/;

print "_extra_table = {";
for(my $i = 0; $i < 32; $i++) {
	$charname = charnames::viacode($i);
	print "$i: '$charname', ";
}
for(my $i = 127; $i < 160; $i++) {
	$charname = charnames::viacode($i);
	next if !$charname;
	print "$i: '$charname', ";
}
print "}\n";
