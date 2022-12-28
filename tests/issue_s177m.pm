package issue_s177m;
# part of issue_s177
#use Data::Dumper;

our $VERSION = '1.0';

@import_args = ();
sub import {
    @import_args = @_;

    my $pkg = shift;

    #print Dumper(\$pkg);
    my $callpkg = caller(0);

    do { *{"$callpkg\::$_"} = \&{"$pkg::$_"} if $_ !~ /^-/ } foreach @_;
}

sub a1 { 1 }
1;
