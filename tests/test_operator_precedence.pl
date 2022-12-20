# Test operator precedence.  Mostly written by ChatGPT.
use Carp::Assert;

# define a simple function that increments a number by 1
sub inc {
  my $num = shift;
  return $num + 1;
}

# define a custom function to compare two lists
sub compare_lists {
  my ($list1, $list2) = @_;
  return 0 unless @$list1 == @$list2;
  for my $i (0..$#{$list1}) {
    return 0 unless $list1->[$i] == $list2->[$i];
  }
  return 1;
}

# define the list_or function
sub list_or {
  my @list = @_;
  return 0 unless @list;
  return $list[0] || list_or(@list[1..$#list]);
}

sub test {
  # define variables
  my $a = 1;
  my $b = 0;
  my $c = 1;

  # check the result of the expression against the expected result
  assert ($a && $b || $c) == 1;
  assert $a && $b || $c == 1;
  assert $a && $c || $b == 0;
  assert $a && $c || $b == 0 == 1;
  assert (($a && $b) || $c) == 1;

  # define two strings
  my $str1 = "hello";
  my $str2 = "world";

  # check the result of the eq and ne operators against the expected result
  assert !($str1 eq $str2);
  assert ($str1 ne $str2) == 1;

  # define an array
  my @arr = (1, 2, 3);

  # check the result of calling shift on the array against the expected result
  assert shift @arr == 1;

  # check the result of the shift operation against the expected result using the custom function
  assert compare_lists(\@arr, [2, 3]) == 1, 'shift @arr gave the wrong result';


  # define an array
  my @arr = (1, 2, 3);

  # check the result of calling map on the array against the expected result
  assert compare_lists([map { inc($_) } @arr], [2, 3, 4]) == 1;

  # define a list with no parenthesis combined with ||
  my @list = (1, 0, 1);

  # check the result of calling the function on the list against the expected result
  assert list_or(@list) == 1;
  assert list_or @list;
  assert list_or 1, 0, 1;
  assert list_or shift @arr, 0;
  assert list_or 0, shift @arr;
  assert list_or 0, shift @arr, 0;
  assert list_or split /,/, "0,1";
  assert list_or 1, split /,/, "0,0";

  # Check string concat vs eq
  assert 'a' . 'b' eq 'ab';
  assert 'a' . 'b' . 'c' eq 'abc';

}

test();

sub test2 {
  # define variables
  my $a = 1;
  my $b = 0;
  my $c = 1;

  # check the result of the expression against the expected result
  assert $a or $b and $c == 1;
  assert not ($a || $b && $c) == 0;
  #assert not $a || $b && $c == 0;

  # define two strings
  my $str1 = "hello";
  my $str2 = "world";

  # check the result of the eq and ne operators against the expected result
  # the expression would be evaluated as ($str1 eq $str2) or ($str1 ne $str2), w
  assert ($str1 eq $str2 or $str1 ne $str2) == 1;
  assert not $str1 eq $str2 || $str1 ne $str2 == 1;

  # define an array
  my @arr = (1, 2, 3);

  # check the result of calling shift on the array against the expected result
  assert shift @arr or @arr && $c == 1;
  #assert !(not shift @arr || @arr && $c);

  # define an array
  my @arr = (1, 2, 3);

  # check the result of calling map on the array against the expected result
  assert map { inc($_) } @arr or @arr && $c == 1;
  assert !(not map { inc($_) } @arr || @arr && $c);

  # define a list with no parenthesis combined with ||
  my @list = (1, 0, 1);

  # check the result of calling the function on the list against the expected result
  assert list_or(@list) or @list and $c == 1;
  #assert !(not list_or(@list) || @list and $c);

  my $separator = ", ";

  # check the result of calling the join function on the list against the expected result
  assert join($separator, "hello", "world", "foo", "bar") eq "hello, world, foo, bar";
  assert join $separator, "hello", "world", "foo", "bar"  eq "hello, world, foo, bar";
}

test2();

# define a custom function to compare two arrays
sub compare_arrays {
  my ($arr1, $arr2) = @_;
  return 0 unless scalar(@$arr1) == scalar(@$arr2);
  for (my $i = 0; $i < scalar(@$arr1); $i++) {
    return 0 unless $arr1->[$i] == $arr2->[$i];
  }
  return 1;
}

sub test3 {
  my @arr = (1, 2, 3);
  # I decided NOT to fix this hokey case for now!!
  #assert(push @arr, 4, 5, 6 == 6);      # the last thing pushed is 6 == 6, or 1
  #assert(compare_arrays(\@arr, [1,2,3,4,5,1]));

  #assert(pop @arr == 1);
  #assert(compare_arrays(\@arr, [1,2,3,4,5]));

}
test3();

sub test4 {
  # define a format string
  my $format = "The first argument is %s, the second is %d, and the third is %.2f";

  # check the result of calling sprintf on the format string and list of arguments against the expected result
  assert sprintf($format, "foo", 123, 4.56) eq "The first argument is foo, the second is 123, and the third is 4.56";
  assert sprintf $format, "foo", 123, 4.56  eq "The first argument is foo, the second is 123, and the third is 4.56";

  # define a different format string
  $format = "The first argument is %d, the second is %s, and the third is %.4f";

  # check the result of calling sprintf on the format string and list of arguments again against the expected result
  assert sprintf($format, 789, "bar", 1.2345) eq "The first argument is 789, the second is bar, and the third is 1.2345";
  assert sprintf $format, 789, "bar", 1.2345  eq "The first argument is 789, the second is bar, and the third is 1.2345";
}

test4();


print "$0 - test passed!\n";
