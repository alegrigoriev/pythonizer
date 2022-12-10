# issue s204 - complex double ? : operation generates bad code
# from CGI.pm
use Carp::Assert;

sub checkit {
    $labeled = shift;
    $novals = shift;
    $attribs = shift;
    $value = shift;
    $label = shift;

    $result = '';
    $result .= $labeled ? $novals ? "<option$attribs label=\"$value\">$label</option>\n"
                                  : "<option$attribs label=\"$value\" value=\"$value\">$label</option>\n"
                        : $novals ? "<option$attribs>$label</option>\n"
                                  : "<option$attribs value=\"$value\">$label</option>\n";
    return $result;
}

assert(checkit(0, 0, 'a', 'b', 'c') eq "<optiona value=\"b\">c</option>\n");
assert(checkit(0, 1, 'a', 'b', 'c') eq "<optiona>c</option>\n");
assert(checkit(1, 0, 'a', 'b', 'c') eq "<optiona label=\"b\" value=\"b\">c</option>\n");
assert(checkit(1, 1, 'a', 'b', 'c') eq "<optiona label=\"b\">c</option>\n");

print "$0 - test passed!\n";
