package Pscan;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/cur_package/;

sub cur_package
{
    my $result = $Pack::Packages[-1];
    $Pack::Packages{$result} = 1;
    return $result;
}
1;
