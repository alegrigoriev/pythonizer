# Test various forms of for and foreach loops
use Carp::Assert;
my %hash = (k1=>'v1', k3=>'v3', k2=>'v2');
my @khash = keys %hash;
my @files = ('file1', 'file3', 'file2');
my @arr = ();
my %tickets = (t1=>'v1', t3=>'v3', t2=>'v2');
my @tkts = %tickets;
my %tk = @tkts;
aeq_unordered(\@tkts, ['t1', 't2', 't3', 'v1', 'v2', 'v3']);
assert(scalar(%tk) == 3 && $tk{t1} eq 'v1' && $tk{t2} eq 'v2' && $tk{t3} eq 'v3');

foreach $p (keys %hash) {
	 push @arr, $p;
}
aeq_unordered(\@arr, \@khash);

@arr = ();
for $file ( @files ) {
	push @arr, $file;
}
aeq(\@files, \@arr);

@arr = ();
for ( @files ) {
	push @arr, $_;
}
aeq(\@files, \@arr);

@arr = ();
for my $file ( @files ) {
	push @arr, $file;
}
aeq(\@files, \@arr);

@arr = ();
foreach $file ( @files ) {
	push @arr, $file;
}
aeq(\@files, \@arr);

@arr = ();
for ( my $i = 5; $i >= 0; $i-- ) {
	push @arr, $i;
}
aeqi(\@arr, [5,4,3,2,1,0]);

@arr = ();
for ( my $i = 5; $i > 0; $i-- ) {
	push @arr, $i;
}
aeqi(\@arr, [5,4,3,2,1]);

@arr = ();
for ( my $i = 0; $i < 5; $i++ ) {
	push @arr, $i;
}
aeqi(\@arr, [0,1,2,3,4]);

@arr = ();
for ( my $i = 0; $i <= 5; $i++ ) {
	push @arr, $i;
}
aeqi(\@arr, [0,1,2,3,4,5]);

@arr = ();
foreach $j ( 0 .. 4 ) {
	push @arr, $j;
}
aeqi(\@arr, [0,1,2,3,4]);

@arr = ();
for ( 0 .. 4 ) {
	push @arr, $_;
}
aeqi(\@arr, [0,1,2,3,4]);

@arr = ();
foreach $i ( 2, 4, 16, 64 ) {
	push @arr, $i;
}
aeqi(\@arr, [2,4,16,64]);

@arr = ();
for my $j ( 2, 4, 16 ) {
	push @arr, $j;
}
aeqi(\@arr, [2,4,16]);

@arr = ();
for ( 3, 6, 9 ) {
	push @arr, $_;
}
aeqi(\@arr, [3,6,9]);

sub myFunc{
    my @result = ('a', 'c', 'b');
    return \@result;
}

@arr = ();
for ( @{myFunc()} ) {
	push @arr, $_;
}
aeq(\@arr, ['a','c','b']);

@arr = ();
for ( sort @{myFunc()} ) {
	push @arr, $_;
}
aeq(\@arr, ['a','b','c']);

@arr = ();
foreach $region (A, ABC, D, EF) {
	push @arr, $region;
}
aeqi(\@arr, [A,ABC,D,EF]);

@arr = ();
foreach $id (keys %tickets)
{
	push @arr, $id;
}
aeq_unordered(\@arr, ['t1', 't2', 't3']);
@arr = ();

foreach $id (%tickets)
{
	push @arr, $id;
}
aeq_unordered(\@arr, \@tkts);

@arr = ();
foreach $id (sort values %tickets)
{
	push @arr, $id;
}
aeq(\@arr, ['v1', 'v2', 'v3']);


@arr = ();
foreach $id (reverse sort keys %tickets)
{
	push @arr, $id;
}
aeq(\@arr, ['t3', 't2', 't1']);

@arr = ();
foreach $id (sort keys %tickets)
{
	push @arr, $id;
}
aeq(\@arr, ['t1', 't2', 't3']);

@arr = ();
foreach $id (sort %tickets)
{
	push @arr, $id;
}
aeq(\@arr, ['t1', 't2', 't3', 'v1', 'v2', 'v3']);

sub aeq {
    $a_ref1 = shift;
    $a_ref2 = shift;

    my ($package, $filename, $line) = caller;

    eval {
        assert(scalar(@$a_ref1) == scalar(@$a_ref2));
    };
    if($@) {
        say STDERR "scalar(\@\$a_ref1) != scalar(\@\$a_ref2), ".scalar(@$a_ref1)." != ".scalar(@$a_ref2);
        say STDERR "Assertion failed in aeq called from line $line";
        die($@);
    }
    for(my $i = 0; $i < scalar(@$a_ref1); $i++) {
        eval {
            assert($a_ref1->[$i] eq $a_ref2->[$i]);
        };
        if($@) {
            say STDERR "\$a_ref1->[$i] ne \$a_ref2->[$i], $a_ref1->[$i] ne $a_ref2->[$i]";
            say STDERR "Assertion failed in aeq called from line $line";
            die($@);
        }
    }
}

sub aeq_unordered {
    # check if a_ref1 eq a_ref2 in any order
    $a_ref1 = shift;
    $a_ref2 = shift;

    my ($package, $filename, $line) = caller;

    eval {
        assert(scalar(@$a_ref1) == scalar(@$a_ref2));
    };
    if($@) {
        say STDERR "Assertion failed in aeq_unordered called from line $line";
        say STDERR "scalar(\@\$a_ref1) != scalar(\@\$a_ref2), ".scalar(@$a_ref1)." != ".scalar(@$a_ref2);
        die($@);
    }
    for(my $i = 0; $i < scalar(@$a_ref1); $i++) {
        eval {
            $found = 0;
            for(my $j = 0; $j < scalar(@$a_ref2); $j++) {
                if($a_ref1[$i] eq $a_ref2[$j]) {
                    $found = 1;
                    last;
                }
            }
            assert($found);
        };
        if($@) {
            say STDERR "\$a_ref1->[$i] not found in @{$a_ref2}";
            say STDERR "Assertion failed in aeq_unordered called from line $line";
            die($@);
        }
    }
}

sub aeqi {
    $a_ref1 = shift;
    $a_ref2 = shift;

    my ($package, $filename, $line) = caller;

    eval {
        assert(scalar(@$a_ref1) == scalar(@$a_ref2));
    };
    if($@) {
        say STDERR "scalar(\@\$a_ref1) != scalar(\@\$a_ref2), ".scalar(@$a_ref1)." != ".scalar(@$a_ref2);
        say STDERR "Assertion failed in aeqi called from line $line";
        die($@);
    }
    for(my $i = 0; $i < scalar(@$a_ref1); $i++) {
        eval {
            assert($a_ref1->[$i] == $a_ref2->[$i]);
        };
        if($@) {
            say STDERR "\$a_ref1->[$i] ne \$a_ref2->[$i], $a_ref1->[$i] ne $a_ref2->[$i]";
            say STDERR "Assertion failed in aeqi called from line $line";
            die($@);
        }
    }
}

print "$0 - test passed!\n";
