# Pythonizer was scrambling comments - test that isn't the case anymore

use Carp::Assert;

#BLOCK 1: 1
#BLOCK 1: 2
#BLOCK 1: 3
#BLOCK 1: 4

sub test
#BLOCK 2: 1
#BLOCK 2: 2
#BLOCK 2: 3
#BLOCK 2: 4
{
    $i = 1;             #LINE 1
    #BLOCK 3: 1
    #BLOCK 3: 2
    #BLOCK 3: 3
    #BLOCK 3: 4
    $j = 2;             #LINE 2
    $i + $j;
}

#BLOCK 4: 1
#BLOCK 4: 2
#BLOCK 4: 3
#BLOCK 4: 4
sub test4{ 1 };         #LINE 3

assert(test() == 3);
assert(test4() == 1);   #LINE 4
open(SRC, "<$0");
%blocks = ();
$lines = '';
while(<SRC>) {
    if(/#BLOCK (\d): (\d)/) {
        if(!exists $blocks{$1}) {
            $blocks{$1} = $2;
        } else {
            $blocks{$1} .= $2;
        }
    } elsif(/#LINE (\d)/) {
        $lines .= $1;
    }
}
for(my $i=1; $i<=4; $i++) {
    assert($blocks{$i} eq '1234');
}
assert($lines eq '1234');

print "$0 - test passed!\n";

