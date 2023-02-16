# issue_s280m - part of issue_s280
package issue_s280m;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(mysub);

sub mysub {
    return 42;
}

sub import {
    my $pkg = shift;
    $Exporter::ExportLevel = 1;
    &Exporter::import($pkg, 'mysub');
}

1;
