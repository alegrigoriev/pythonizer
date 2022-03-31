package Pscan;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/cur_package set_breakpoint_lno/;

$globalvar = 0;

sub cur_package
{
    my $result = $Pack::Packages[-1];
    $Pack::Packages{$result} = 1;
    return $result;
}

sub set_breakpoint_lno
{
	$::breakpoint = $_[0];
}

@PythonCode = ('*');

1;
