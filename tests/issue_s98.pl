# issue s98 - missing type conversion for hash values
# code from get_bravo_demands.pl
use Carp::Assert;

%raw_gravity = ('s0,d0,p0'=>10, 's1,d1,p1'=>20, 's2,d2,p2'=>30);
%gravity = ('s0,d0'=>5, 's1,d1'=>10);
%estimated_pdmd = ('s0,d0'=>360, 's1,d1'=>-720);
$true = 1;
if($true) {
    $estimated_fpdmd{'s0,d0'} = 1080;
}
$seconds = 0;
foreach $sdp (sort keys %raw_gravity) {

    ($s0,$d0,$p0) = split /\,/, $sdp;
    next unless (exists $estimated_pdmd{"$s0,$d0"} &&
		 ($estimated_pdmd{"$s0,$d0"} > 0 ||
		  $estimated_fpdmd{"$s0,$d0"} >0 ||
                  $estimated_bdmd{"$s0,$d0"} >0 ));

    if ($pdmdfile =~ /\.daily\./) {
	$seconds = 3600*24;
    } else {
	$seconds = 3600;
    }

    $D = $estimated_pdmd{"$s0,$d0"}*1e3*8/$seconds;
    $D *= ($raw_gravity{$sdp} / $gravity{"$s0,$d0"});
    $P = $estimated_fpdmd{"$s0,$d0"}*1e3*8/$seconds;
    $B = $estimated_bdmd{"$s0,$d0"}*1e3*8/$seconds;
    push @answer, ($D,$P,$B);
}
assert(@answer == 3);
assert($answer[0] == 1600);
assert($answer[1] == 2400);
assert($answer[2] == 0);
print "$0 - test passed!\n";
