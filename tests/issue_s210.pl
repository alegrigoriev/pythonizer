# issue s210 - Calling a sub stored in a hash generates incorrect code
# from CGI.pm
package CGI;
use Carp::Assert;
sub new {
    bless {}, shift;
}
my $self = new CGI;
$self->{'.upload_data'} = 'upload data';
my $data = 'data';
my $param = 'param';
$self->{'.upload_hook'} = sub {
    my ($p, $d, $t, $u, $passed) = @_;
    assert($p eq 'param');
    assert($d eq 'data');
    assert($t == 4);
    assert($u eq 'upload data');
    print "$0 - test passed!\n" if $passed;
};

my $subref = $self->{'.upload_hook'};


if ( defined $self->{'.upload_hook'} ) {
    $totalbytes += length($data);
    &$subref( $param, $data, $totalbytes, $self->{'.upload_data'}, 0 );
    &{$subref}( $param, $data, $totalbytes, $self->{'.upload_data'}, 0 );
    &{ $subref }( $param, $data, $totalbytes, $self->{'.upload_data'}, 0 );
    &{ $self->{'.upload_hook'} }( $param, $data, $totalbytes,
        $self->{'.upload_data'}, 0 );
    &{$self->{'.upload_hook'}}($param ,$data, $totalbytes, $self->{'.upload_data'}, 1);
}
