package Exporting;

use Exporter 'import';
our @EXPORT_OK = qw(munge frobnicate);

sub munge
{
    my $arg = shift;

    return $arg . 'm';
}

sub frobnicate
{
    my $arg = shift;

    return 'f' . $arg;
}
