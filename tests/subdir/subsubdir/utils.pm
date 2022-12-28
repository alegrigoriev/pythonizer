# part of issue_s211 - check a subsubdir
package subdir::subsubdir::utils;

use Exporter 'import';

our @EXPORT_OK = qw/myutil/;

sub myutil {
    return $_[0] + 1;
}
1;
