# this is part of issue_bootstrapping - refer to variables in the main package
package RefsMain;
use lib '.';

require Exporting;
our @ISA = qw/Exporting/;
our @EXPORT = qw/set_main/;

sub set_main
{
	$::main_var_set = shift;
	$::in = 42;	# Try one where we have to escape the name
}
1;
