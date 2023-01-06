package issue_s226m;
use parent 'Exporter';

our @EXPORT_OK = qw/uw/;

sub uw {
    $::global = wantarray;

    if(defined wantarray) {
        return wantarray ? ('1') : 1;
    }
    return;
}
1;
