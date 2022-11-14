# issue s149 - multi-line q string with blank lines doesn't translate properly
use Carp::Assert;
my $prefix = q~
    declare variable $cfg external;

    declare function local:path-to-node ( $nodes as node()* )  as xs:string* {
        for $node in $nodes
        return concat("/", string-join(for $node in $node/ancestor-or-self::* return name($node), '/'))
    };

    declare function local:recursive-print-child ( $children as node()* )  as node()* {
        for $c in $children
        let $name := fn:name($c)
        let $path := local:path-to-node($c)
~;

assert($prefix =~ /declare/);
assert($prefix =~ /;\n\n    declare function/ms);
assert($prefix =~ m'\$cfg');
assert($prefix =~ m'::\*');
assert($prefix =~ /function/);
print "$0 - test passed!\n";
