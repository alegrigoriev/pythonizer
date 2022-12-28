# part of issue_s211

package otherdir::othermod;
use Exporter 'import';
our @EXPORT_OK = qw/otherfunc/;
sub otherfunc {
    $_[0] - 1;
}
1;
