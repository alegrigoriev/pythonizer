# issue 96: bad indent for empty block
use Carp::Assert;

my $i = 1;

if($i == 1) {;}
if($i == 1) {}

if($i == 0){
}

if($i == 1) {
} elsif($i == 2) {      # comment on elsif line
} else {
    # comment in else block only
}

for($j = 0; $j<3; $j++) {}
assert($j == 3 || $j == 2);
while(0){}
do {;} until(1);
do {} until(1);

print "$0 - test passed!\n";
