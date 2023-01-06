# part of issue_s225
package subsubdir::Util;

use Exporter 'import';
require 5.004;

our $VERSION = '4.54';
our @EXPORT = qw/myutil/;

sub myutil {
    return $_[0] + 1;
}
1;
