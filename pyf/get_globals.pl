#!/usr/bin/perl
use lib '..';
use Pyconfig;

sub quote
{
    my $val = shift;

    return q(') . $val . q(') if(index($val, '"') >= 0);
    return q(") . $val . q(");
}

while(($var, $val) = each(%GLOBALS)) {
    push @glob, '"' . $var . '": ' . quote($val);
}
print '{' . join(",\n", @glob) . "}\n";
