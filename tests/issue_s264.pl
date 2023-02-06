# issue s264: incorrect int conversion of hashref in array subscript
use Carp::Assert;
no warnings 'experimental';
my @decls = ('a', '$', 'b', '$');
my %ndx_map;
for(my $i = 0; $i < scalar(@decls); $i+=2) {
    $ndx_map{$decls[$i]} = ($i >> 1);
}
$package = 'main';
%{"$package\::_ndx_map"} = %ndx_map;
sub test { 
    #my $class = (scalar(@_) ? shift : $package);
    #my $self = bless [], $class;
    my $self = [];
    my %args = @_;
    for (keys %args) {
        $self->[${"$package\::_ndx_map"}{$_}] = $args{$_}
    }
    return $self;
}

my $result = test(a=>1, b=>2);

assert($result ~~ [1,2]);
print "$0 - test passed!\n";
