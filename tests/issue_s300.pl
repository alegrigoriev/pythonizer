# issue s300 - Subs that start with an '_' and the name is the same as a perllib function causes bad code to be generated
use Carp::Assert;

warn "$0 - " . _warn() . "\n";

sub _warn { 'test passed' }
