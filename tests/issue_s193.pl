# issue s193 - Bad code is generated for shift()
# Code from CGI.pm
use Carp::Assert;

sub SERVER_PUSH { 'multipart/x-mixed-replace;boundary="' . shift() . '"'; }
sub SERVER_PUSH2 { 'multipart/x-mixed-replace;boundary="' . shift . '"'; }

assert(SERVER_PUSH('hi') eq 'multipart/x-mixed-replace;boundary="hi"');
assert(SERVER_PUSH2('hi') eq 'multipart/x-mixed-replace;boundary="hi"');

print "$0 - test passed!\n";
