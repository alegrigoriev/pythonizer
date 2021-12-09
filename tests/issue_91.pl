# issue 91 - bad code for exists on hash of hashes
use Carp::Assert;

# Simple cases

%hash = (key=>'value');
assert(exists $hash{key});
$k = key;
assert(exists $hash{$k});

# These were failing

%bundles = ();
$bundles{cttm} = 'v';
%cttmembers = (k=>'cttm');
$key = 'k';
if(not exists $bundles{$cttmembers{$key}}) {
    assert(0);
}

%bidsinterface = (node=> {name=>'Joe'});
$node = node;
$name = name;

if(exists $bidsinterface{$node}{$name}) {
    ;
} else {
    assert(0);
}
assert(exists ($bidsinterface{$node}{$name}));  # try paren
assert(exists $bundles{$cttmembers{$key}} && exists $bidsinterface{$node}{$name});      # try in expression

print "$0 - test passed!\n";
