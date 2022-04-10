# issue s47 - Map of a qw generates bad code syntax
use Carp::Assert;

my %args_permitted = map { $_ => 1 } ( qw|
            chmod
            error
            group
            mask
            mode
            owner
            uid
            user
            verbose
        | );

assert($args_permitted{chmod});
assert($args_permitted{error});
assert($args_permitted{group});
assert($args_permitted{mask});
assert($args_permitted{mode});
assert($args_permitted{owner});
assert($args_permitted{uid});
assert($args_permitted{user});
assert($args_permitted{verbose});
assert(scalar(%args_permitted) == 9);

my @ap = qw|
            chmod
            error
            group
            mask
            mode
            owner
            uid
            user
            verbose
        |;
my %ap2 = map { $_ => 1 } ( @ap );

assert($ap2{chmod});
assert($ap2{error});
assert($ap2{group});
assert($ap2{mask});
assert($ap2{mode});
assert($ap2{owner});
assert($ap2{uid});
assert($ap2{user});
assert($ap2{verbose});
assert(scalar(%ap2) == 9);

my %ap3 = map { $_ => 1 } 
            ('chmod',
            'error',
            'group',
            'mask',
            'mode',
            'owner',
            'uid',
            'user',
            'verbose');

assert($ap3{chmod});
assert($ap3{error});
assert($ap3{group});
assert($ap3{mask});
assert($ap3{mode});
assert($ap3{owner});
assert($ap3{uid});
assert($ap3{user});
assert($ap3{verbose});
assert(scalar(%ap3) == 9);

print "$0 - test passed!\n";

