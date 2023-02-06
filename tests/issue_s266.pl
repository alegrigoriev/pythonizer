# issue s266 - Bless with => instead of , generates bad code
package Encode::UTF_EBCDIC;

sub new {
    my $obj = bless { Name => "UTF_EBCDIC" } => "Encode::UTF_EBCDIC";
    return $obj;
}

sub make {
    my %obj = (key=>{});
    $_ = 'key';
    bless $obj{$_} => __PACKAGE__;
}

package main;
use Carp::Assert;

my $obj = new Encode::UTF_EBCDIC;
assert(UNIVERSAL::isa($obj, 'Encode::UTF_EBCDIC'));
my $obj2 = Encode::UTF_EBCDIC::make();
assert(UNIVERSAL::isa($obj2, 'Encode::UTF_EBCDIC'));

assert($obj->{Name} eq 'UTF_EBCDIC');
print "$0 - test passed!\n";
