# issue 20 - unless expression loses the required parenthesis for proper code generation

use Carp::Assert;

$ct1 = 0;
$ct2 = 0;
for($area_hidden = 0; $area_hidden <= 1; $area_hidden++) {
    for($area_rtr_hidden = 0; $area_rtr_hidden <= 1; $area_rtr_hidden++) {
        for($intf_hidden = 0; $intf_hidden <= 1; $intf_hidden++) {
            for($link_hidden = 0; $link_hidden <= 1; $link_hidden++) {

                unless (($area_hidden) || ($area_rtr_hidden) ||
				($intf_hidden) || ($link_hidden)) {
                    $ct1++;
                    assert(!$area_hidden);
                    assert(!$area_rtr_hidden);
                    assert(!$intf_hidden);
                    assert(!$link_hidden);

                } else {
                    $ct2++;
                    assert($area_hidden or $area_rtr_hidden or $intf_hidden or $link_hidden);
                }
            }
        }
    }
}

assert($ct1 == 1);
assert($ct2 == 15);
print "$0 - test passed!\n";
