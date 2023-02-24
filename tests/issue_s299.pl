# issue s299 - foreach as statement modifier with a , expression generates bad code
use Carp::Assert;

# Create a sample package with exports
package MyPackage;
#use Exporter qw(import);
our @EXPORT = qw(func1 func2);
our @EXPORT_OK = qw(func3 func4);

package main;
# Test case 1: verify that all exports are in the cache
my $export_cache = {};
my $exports = \@MyPackage::EXPORT;
my $pkg = 'MyPackage';
if(not %$export_cache) {
    s/^&//, $export_cache->{$_} = 1 foreach (@$exports, @{"$pkg\::EXPORT_OK"});
}
assert(keys %$export_cache == 4, "Test case 1 failed: unexpected number of exports in cache");
assert($export_cache->{'func1'}, "Test case 1 failed: func1 not found in cache");
assert($export_cache->{'func2'}, "Test case 1 failed: func2 not found in cache");
assert($export_cache->{'func3'}, "Test case 1 failed: func3 not found in cache");
assert($export_cache->{'func4'}, "Test case 1 failed: func4 not found in cache");

# Test case 2: verify that ampersands are stripped from exports
$export_cache = {};
$exports = ['&func1', '&func2'];
@MyPackage::EXPORT_OK = ();
if(not %$export_cache) {
    s/^&//, $export_cache->{$_} = 1 foreach (@$exports, @{"$pkg\::EXPORT_OK"});
}
assert(keys %$export_cache == 2, "Test case 2 failed: unexpected number of exports in cache");
assert($export_cache->{'func1'}, "Test case 2 failed: func1 not found in cache");
assert($export_cache->{'func2'}, "Test case 2 failed: func2 not found in cache");

# Test case 3: verify that an empty exports list results in an empty cache
$export_cache = {};
$exports = [];
if(not %$export_cache) {
    s/^&//, $export_cache->{$_} = 1 foreach (@$exports, @{"$pkg\::EXPORT_OK"});
}
assert(keys %$export_cache == 0, "Test case 3 failed: non-empty cache for empty exports list");

# Test case 4: try a multi-element array slice
$export_cache = {};
$exports = ['&func1', '&func2', '&func3', '&func4'];
s/^&//, $export_cache->{$_} = 1 foreach (@$exports[0,2]);
assert(keys %$export_cache == 2, "Test case 4 failed: unexpected number of exports in cache");
assert($export_cache->{'func1'}, "Test case 4 failed: func1 not found in cache");
assert($export_cache->{'func3'}, "Test case 4 failed: func3 not found in cache");

# Test case 5: Use a loop var not declared as 'my' on the loop
@MyPackage::EXPORT_OK = qw(func3 func4);
my $export_cache = {};
my $exports = \@MyPackage::EXPORT;
my $loop_var = 'loop_var';
foreach $loop_var (@$exports, @{"$pkg\::EXPORT_OK"}) {
    $loop_var =~ s/^&//, $export_cache->{$loop_var} = 1;
}
assert(keys %$export_cache == 4, "Test case 5 failed: unexpected number of exports in cache");
assert($export_cache->{'func1'}, "Test case 5 failed: func1 not found in cache");
assert($export_cache->{'func2'}, "Test case 5 failed: func2 not found in cache");
assert($export_cache->{'func3'}, "Test case 5 failed: func3 not found in cache");
assert($export_cache->{'func4'}, "Test case 5 failed: func4 not found in cache");
assert($loop_var eq 'loop_var', "Test case 5 failed: loop_var $loop_var is not 'loop_var' after loop");

# Test case 6: Use a loop var declared as 'my' on the loop
my $export_cache = {};
foreach my $loop_var (@$exports, @{"$pkg\::EXPORT_OK"}) {
    $loop_var =~ s/^&//, $export_cache->{$loop_var} = 1;
}
assert(keys %$export_cache == 4, "Test case 6 failed: unexpected number of exports in cache");
assert($export_cache->{'func1'}, "Test case 6 failed: func1 not found in cache");
assert($export_cache->{'func2'}, "Test case 6 failed: func2 not found in cache");
assert($export_cache->{'func3'}, "Test case 6 failed: func3 not found in cache");
assert($export_cache->{'func4'}, "Test case 6 failed: func4 not found in cache");
assert($loop_var eq 'loop_var', "Test case 6 failed: loop_var $loop_var is not 'loop_var' after loop");

# Test case 7: Use a global loop var
my $export_cache = {};
$global_loop_var = 'glv';
if(not %$export_cache) {
    foreach $global_loop_var (@$exports, @{"$pkg\::EXPORT_OK"}) {
        $global_loop_var =~ s/^&//, $export_cache->{$global_loop_var} = 1;
    }
}
assert(keys %$export_cache == 4, "Test case 7 failed: unexpected number of exports in cache");
assert($export_cache->{'func1'}, "Test case 7 failed: func1 not found in cache");
assert($export_cache->{'func2'}, "Test case 7 failed: func2 not found in cache");
assert($export_cache->{'func3'}, "Test case 7 failed: func3 not found in cache");
assert($export_cache->{'func4'}, "Test case 7 failed: func4 not found in cache");
assert($global_loop_var eq 'glv', "Test case 7 failed: global_loop_var $global_loop_var is not 'glv' after loop");

# Test from netdb:

sub cfg {
    my $arg = shift;
    return $arg . ',' . $arg . '|' . $arg;
}
$key = 'key';
%descr = ();
$descr{$key}     = cfg( "Description" );
$descr{$key} =~ s/\,//g; $descr{$key} =~ s/\|//g;

assert($descr{$key} eq 'DescriptionDescriptionDescription', "descr test failed with $descr{$key}");

print "$0 - test passed!\n";
