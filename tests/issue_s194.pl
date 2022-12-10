# issue s194 - map with a ? : conditional array generates bad code
# code from CGI.pm
use Carp::Assert;

my $tag = '<tag>';
my $untag = '</tag>';

my @arr = map { "$tag$_$untag" } "abc";
assert(@arr == 1);
assert($arr[0] eq '<tag>abc</tag>');

sub map_it {
    $arg = $_;
    return "$tag$arg$untag";
}

@arr = map(map_it, (1==1) ? "abc" : "nope");
assert(@arr == 1);
assert($arr[0] eq '<tag>abc</tag>');

my %hash;

@brr = map(map_it, exists($hash{key}) ? "nope" : "abc");
assert(@brr == 1);
assert($brr[0] eq '<tag>abc</tag>');

sub zero { 0 }

@crr = map(map_it, zero() ? "nope" : "abc");
assert(@crr == 1);
assert($crr[0] eq '<tag>abc</tag>');

sub one { 1 }

@drr = map(map_it, one() ? "abc" : "nope");
assert(@drr == 1);
assert($drr[0] eq '<tag>abc</tag>');

my @grp = grep { $_ eq 'a' } "abc";
assert(@grp == 0);

@grp = grep(/^a$/, "abc");
assert(@grp == 0);

my @rest = (['a', 'b']);
sub gen_tags {
    my @result = map { "$tag$_$untag" } 
                          (ref($rest[0]) eq 'ARRAY') ? @{$rest[0]} : "@rest";
    return @result;
}
@tags = gen_tags();
assert(join(' ', @tags) eq '<tag>a</tag> <tag>b</tag>');
@rest = ('a', 'b');
@tags = gen_tags();
assert(@tags == 1);
assert($tags[0] eq '<tag>a b</tag>');

print "$0 - test passed\n";
