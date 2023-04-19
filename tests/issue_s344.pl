# issue s344 - Simple regex substitute generates bad code
use Carp::Assert;

sub _split_delta {
   my($self,$string) = @_;

   my $sign    = '[-+]?';
   my $num     = '(?:\d+(?:\.\d*)?|\.\d+)';
   my $f       = "(?:$sign$num)?";

   if ($string =~ /^$f(:$f){0,6}$/o) {
      $string =~ s/::/:0:/go;
      $string =~ s/^:/0:/o;
      $string =~ s/:$/:0/o;
      my(@delta) = split(/:/,$string);
      return(0,@delta);
   } else {
      return(1);
   }
}

# Test _split_delta, using Carp::Assert:

my @test_cases = (
    { input => "::", expected => [0, 0, 0, 0] },
    { input => "1:2", expected => [0, 1, 2] },
    { input => "1:2:3:4:5:6:7", expected => [0, 1, 2, 3, 4, 5, 6, 7] },
    { input => "-1.5:2.5", expected => [0, -1.5, 2.5] },
    { input => "abc", expected => [1] },
);

foreach my $test_case (@test_cases) {
    my $input    = $test_case->{input};
    my $expected = $test_case->{expected};

    my @result = _split_delta(undef, $input);
    assert(@result == @$expected, "Test case failed for input '$input': Expected " . join(', ', @$expected) . " but got " . join(', ', @result));
}

# Other related tests

# sub case 1
my $string = ':';
$string =~ s/:/0:/;
assert($string eq '0:');

# sub case 2
$string = ':';
my $cnt = $string =~ s/:/0:/;
assert($string eq '0:');
assert($cnt == 1);

# sub case 4
$string = ':';
my $new;
($new = $string) =~ s/:/0:/;
assert($new eq '0:');
assert($string eq ':');

# sub case 5

$main::string = ':';
assert($main::string =~ s/:/0:/o);
assert($main::string eq '0:');

# another sub case 4
$string = ':';
($main::newstr = $string) =~ s/:/0:/o;
assert($main::newstr eq '0:');
assert($string eq ':');

sub myout {
    $_[0] =~ s/:/0:/o;
    return 1;
}

myout($string);
assert($string eq '0:');

sub myoutref {
    my $strref = shift;

    $$strref =~ s/:/0:/o;
    return 1;
}
$string = ':';
myoutref(\$string);
assert($string eq '0:');

print "$0 - test passed\n";
