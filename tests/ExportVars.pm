package ExportVars;

use Exporter 'import';
our @EXPORT = qw($xvar @xarr get_xvar get_xhash get_xarr $TABSTOP @TABSTOP $in);
our @EXPORT_OK = qw( %xhash get_xhash );
our %EXPORT_TAGS = ('vars'=>[qw($xvar @xarr $TABSTOP @TABSTOP $in %xhash)]);

our $TABSTOP = 4;
our @TABSTOP = (4);
our $in = 'in';

$xvar = 'xvar';
@xarr = ('x', 'a', 'r', 'r');
%xhash = (x=>'h', a=>'s', 'h'=>'x');

sub get_xvar { $xvar }
sub get_xhash { return %xhash }
sub get_xarr { return @xarr }

1;
