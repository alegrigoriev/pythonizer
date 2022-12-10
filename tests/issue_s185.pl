# issue s185 - Implement subs with scalar reference out parameters
use Carp::Assert;
use lib '.';
use issue_s185m;
use issue_s185n qw(set_to_one);

sub no_outs { $_[0] }

sub one_out {
    ${$_[0]} = 1;
    assert(${$_[0]} == 1);
    return 11;
}

sub one_in_out {
    ${$_[0]}++;
    return 11;
}

sub two_out {
    my ($i, $j) = @_;
    $$i = 1;
    assert($$i == 1);
    $$j = 2;
    assert($$j == 2);
    return 11;
}

sub two_in_out {
    my $i = shift;
    my $j = shift;
    $$i++;
    $$j--;
    return 11;
}

sub out_in_out {
    my ($i, $j, $k) = (shift, shift, shift);
    $$i++;
    $$k--;
    return $$j;
}

sub second_out_with_shift {
    my $first = shift;
    my $i = $_[0];
    ${$i} += $$first;
    assert($$i == ${$i});
    return 11;
}

sub check_open {
    my ($fh, $mode, $file) = @_;
    open($$fh, $mode, $file);
}

sub check_read {
    my ($fh, $buf) = @_;
    read($fh, $$buf, 100);
}

sub check_read2 {       # Same but w/o the implicit return
    my ($fh, $buf) = @_;
    read($fh, $$buf, 100);
    return 100;
}

assert(one_out(\$i) == 11);
assert($i == 1);

assert(one_in_out(\$i) == 11);
assert($i == 2);

assert(two_out(\$i, \$j) == 11);
assert($i == 1);
assert($j == 2);

assert(two_in_out(\$i, \$j) == 11);
assert($i == 2);
assert($j == 1);

assert(out_in_out(\$i, \$j, \$k) == 1);
assert($i == 3);
assert($j == 1);
assert($k == -1);

my ($ii, $jj) = (3, 4);
assert(second_out_with_shift(\$ii, \$jj) == 11);
assert($ii == 3);
assert($jj == 7);

assert(check_open(\$fh, '<', $0));
assert(check_read($fh, \$buf));
assert(substr($buf,0,1) eq '#');
seek($fh, 0, 0);
assert(check_read2($fh, \$buf2) == 100);
assert(substr($buf2,0,1) eq '#');
close($fh);

# Try some more complex arguments

assert(one_out(\$hash{key}) == 11);
assert($hash{key} == 1);

assert(one_out(\$arr[0]) == 11);
assert($arr[0] == 1);

# Try out some method calls

my $p = new issue_s185m;
assert($p->no_outs == 11);
assert($p->one_out(\$i) == 11);
assert($i == 1);
assert($p->double_shift(1, \$i) == 11);
assert($i == 2);
assert($p->two_in_outs(\$i, \$j) == 11);
assert($i == 3);
assert($j == 0);
assert($p->one_multiple_out(\$i) == 11);
assert($i == 2);
# NOT SUPPORTED assert($p->var_args(\$i) == 11);
# NOT SUPPORTED assert($i == 1);
# NOT SUPPORTED assert($p->var_args_pre(\$i) == 2);
# NOT SUPPORTED assert($i == 2);
assert($p->prop_it(\$i) == 12);
assert($i == 1);
$i = 0;
# NOT SUPPORTED assert($p->prop_it_var(\$i) == 13);
# NOT SUPPORTED assert($i == 1);

assert($p->open_it(\$fh1, '<', $0));
$p->binmode(\$fh1);
assert($p->read_it($fh1, \$data));
assert(substr($data,0,1) == '#');
close($fh1);

my $s = "ss\n";
$p->chomp_it(\$s);
assert($s eq 'ss');
$p->chop_it(\$s);
assert($s eq 's');

&issue_s185m::chop_it(0, \$s);    # Try a non-OO call
assert($s eq '');

sub chomp_arr {
    chomp @{$_[0]};
}

my @va = ("v1\n", "v2", "v3\n");
chomp_arr(\@va);
assert($va[0] eq 'v1');
assert($va[1] eq 'v2');
assert($va[2] eq 'v3');

# Error tests

eval {
    one_out(\4);
};
assert($@ =~ /read-only/);

eval {
    assert(one_out(\'str') == 11);
};
assert($@ =~ /read-only/);

# Looks like an out parameter, but just set to self - should not error

sub set_self {
    my $i = $_[0];
    $$i = $$i;
}
set_self(\(2+2));

# Try setting the arg multiple times - make sure it doesn't fetch multiple times

sub one_multiple_out {
    my ($i) = @_;
    $$i = 1;
    $$i = 2 if($$i == 1);
    return 11;
}
$i = 0;
assert(one_multiple_out(\$i) == 11);
assert($i == 2);

# Try a conditional one that's false - make sure the value is not trashed
sub fake_out {
    my ($i) = @_;
    $$i = 7 if(1 == 0);
    return 11;
}
assert(fake_out(\$i) == 11);
assert($i == 2);

sub try_and {
    ${$_[0]} &= 1;
}
my $i = 5;
assert(try_and(\$i) == 1);
assert($i == 1);

# Try a substitute operation

sub try_ez_sub {        # Don't use the sub result (count)
    ${$_[0]} =~ s/abc/def/;
    return 11;
}
my $str = 'abc';
assert(try_ez_sub(\$str) == 11);
assert($str eq 'def');

sub try_sub {           # Uses the sub result (count)
    my ($str) = @_;
    $$str =~ s/abc/def/;
}
my $str = 'abc';
assert(try_sub(\$str) == 1);
assert($str eq 'def');

sub try_sub_var {
    my $pos = 0;
    ${$_[$pos]} =~ s/abc/def/;
}
# NOT SUPPORTED my $str = 'abc';
# NOT SUPPORTED assert(try_sub_var(\$str) == 1);
# NOT SUPPORTED assert($str eq 'def');

# Try using tr
sub try_ez_tr {     # Doesn't use the tr result
    ${$_[0]} =~ tr/a/z/;
    return 11;
}
$str = 'aac';
assert(try_ez_tr(\$str) == 11);
assert($str eq 'zzc');

sub try_tr {
    ${$_[0]} =~ tr/a/z/;
}
$str = 'aac';
assert(try_tr(\$str) == 2);
assert($str eq 'zzc');

sub try_tr_var {
    my $pos = 0;
    ${$_[$pos]} =~ tr/a/z/;
}
$str = 'aac';
# NOT SUPPORTED assert(try_tr_var(\$str) == 2);
# NOT SUPPORTED assert($str eq 'zzc');

# Make sure out parameters propagate
sub out_props {
    return one_out($_[0])+1;
}
$i = 0;
assert(out_props(\$i) == 12);
assert($i == 1);

sub method_props {
    return $_[0]->double_shift(1, $_[1])+2;
}
$i = 0;
assert(method_props($p, \$i)==13);
assert($i == 2);

# Try a variable out parameter (NOT SUPPORTED!)
#sub var_out {
#    ${$_[$_[0]]} = 78;
#    ${$_[$_[0]-1]}++;
#    --${$_[$_[0]+1]};
#}
#$i = $j = $k = 0;
#assert(var_out(2, \$i, \$j, \$k) == -1);
#assert($i == 1);
#assert($j == 78);
#assert($k == -1);
#

# Try passing a reference to a regular out parameter
sub regular_out {
    $_[0] = 1;
}
$i = 0;
regular_out(\$i);
#In perl, this doesn't change $i, but in python it does (oh well)
#print "$i\n";

# Now try using the non-OO module, issue_s185n

$i = 0;
assert(set_to_one(\$i) == 11);
assert($i == 1);

# Uses variable out parameters (NOT SUPPORTED)
#my $i = $j = $k = $l = $m = 9;
#issue_s185n::set_evens(\$i, \$j, \$k, \$l, \$m);
#assert($i == 0);
#assert($j == 9);
#assert($k == 2);
#assert($l == 9);
#assert($m == 4);

print "$0 - test passed!\n";
