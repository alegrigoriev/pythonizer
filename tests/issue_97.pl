# issue 97 - Complex hash RHS values produces syntax error in the generated code

use Carp::Assert;

@circuitRow=qw/ID mileage type/;
%colNames=(ID=>0, mileage=>1, type=>2);
$AClli = 'a';
$ZClli = 'z';

my %hop = ( 	"AClli" => $AClli,
		"ZClli" => $ZClli,
		"ID" => $circuitRow[$colNames{"ID"}],
		"mileage" => $circuitRow[$colNames{"mileage"}],
		"type" => $circuitRow[$colNames{"type"}]
	);

assert($hop{AClli} eq 'a');
assert($hop{ZClli} eq 'z');
assert($hop{ID} eq 'ID');
assert($hop{mileage} eq 'mileage');
assert($hop{type} eq 'type');

print "$0 - test passed!\n";
