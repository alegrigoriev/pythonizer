package issue_s177m;
# part of issue_s177

our $VERSION = '1.0';

@import_args = ();
sub import {
    @import_args = @_;

    my $pkg = shift;
    my $callpkg = caller(0);

    do { *{"$callpkg\::$_"} = \&{"$pkg::$_"} if $_ !~ /^-/ } foreach @_;
}

sub a1 { 1 }
1;
