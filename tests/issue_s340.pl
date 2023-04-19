# issue s340 - substitute in elsif generates bad code
use strict;
use warnings;
use Carp::Assert;

sub process_string {
    my ($input) = @_;

    my $result;

    if ($input =~ /^HELLO/) {
        $result = "GREETING";
    } elsif ($input =~ s/^(FOO|BAR)//) {
        $result = "MATCHED";
    } else {
        $result = "NO_MATCH";
    }

    return $result;
}

# Test cases
my @tests = (
    {
        input  => "HELLO, WORLD!",
        output => "GREETING",
    },
    {
        input  => "FOO EXAMPLE",
        output => "MATCHED",
    },
    {
        input  => "BAR EXAMPLE",
        output => "MATCHED",
    },
    {
        input  => "BAZ EXAMPLE",
        output => "NO_MATCH",
    },
);

# Run the tests
for my $test (@tests) {
    my $result = process_string($test->{input});
    assert($result eq $test->{output}, sprintf("Expected: %s, Actual: %s, Input: %s", $test->{output}, $result, $test->{input}));
}

# Another case from Date::Manip::Delta:
#
sub format_it {
   my(@in) = @_;

   my @out;
   foreach my $in (@in) {
      my $out = '';
      while ($in) {
         if ($in =~ s/^([^%]+)//) {
            $out .= $1;

         } elsif ($in =~ s/^%%//) {
            $out .= "%";

         } elsif ($in =~ s/^%
                           (\+)?                   # sign
                           ([<>0])?                # pad
                           (\d+)?                  # width
                           ([yMwdhms])             # field
                           v                       # type
                          //ox) {
            my($sign,$pad,$width,$field) = ($1,$2,$3,$4);
            #$out .= $self->_printf_field($sign,$pad,$width,0,$field);
            if(defined $sign) {
                $out .= $sign . $field . 'v';
            } else {
                $out .= $field . 'v';
            }
         } elsif ($in =~ s/^%
                           (\+)?                   # sign
                           ([<>])?                 # pad
                           (\d+)?                  # width
                           Dt
                          //ox) {
            my($sign,$pad,$width) = ($1,$2,$3);
            if(defined $sign) {
                $out .= $sign . 'Dt';
            } else {
                $out .= 'Dt';
            }
         } else {
            $in =~ s/^(%[^%]*)//;
            $out .= $1;
         }
      }
      push(@out,$out);
   }

   return @out;
}

use Carp::Assert;
use strict;
use warnings;

# Test case 1: Basic string without any formatting
my @input1 = ('Hello, world!');
my @expected_output1 = ('Hello, world!');
my @actual_output1 = format_it(@input1);
assert($actual_output1[0] eq $expected_output1[0], 'Test case 1 failed');

# Test case 2: String with escaped percent sign
my @input2 = ('100%% completed');
my @expected_output2 = ('100% completed');
my @actual_output2 = format_it(@input2);
assert($actual_output2[0] eq $expected_output2[0], 'Test case 2 failed');

# Test case 3: String with formatting specifier without sign, pad, or width
my @input3 = ('Today is %dv');
my @expected_output3 = ('Today is dv');
my @actual_output3 = format_it(@input3);
assert($actual_output3[0] eq $expected_output3[0], "Test case 3 failed: @actual_output3 vs @expected_output3");

# Test case 4: String with formatting specifier with sign
my @input4 = ('Temperature: %+dv');
my @expected_output4 = ('Temperature: +dv');
my @actual_output4 = format_it(@input4);
assert($actual_output4[0] eq $expected_output4[0], "Test case 4 failed: @actual_output4 vs @expected_output4");

# Test case 5: String with formatting specifier with pad
my @input5 = ('Progress: %0dv');
my @expected_output5 = ('Progress: dv');
my @actual_output5 = format_it(@input5);
assert($actual_output5[0] eq $expected_output5[0], "Test case 5 failed: @actual_output5 vs @expected_output5");

# Test case 6: String with formatting specifier with width
my @input6 = ('Score: %5dv');
my @expected_output6 = ('Score: dv');
my @actual_output6 = format_it(@input6);
assert($actual_output6[0] eq $expected_output6[0], "Test case 6 failed: @actual_output6 vs @expected_output6");

# Test case 7: String with formatting specifier with all components
my @input7 = ('Time: %+5hv');
my @expected_output7 = ('Time: +hv');
my @actual_output7 = format_it(@input7);
assert($actual_output7[0] eq $expected_output7[0], "Test case 7 failed: @actual_output7 vs @expected_output7");

# Test case 8: Multiple strings in the list
my @input8 = ('Hello, world!', '100%% completed', 'Today is %dv');
my @expected_output8 = ('Hello, world!', '100% completed', 'Today is dv');
my @actual_output8 = format_it(@input8);
assert($actual_output8[0] eq $expected_output8[0] &&
       $actual_output8[1] eq $expected_output8[1] &&
       $actual_output8[2] eq $expected_output8[2], "Test case 8 failed: @actual_output8 vs @expected_output8");

# Test case 9: String with formatting specifier with width
my @input9 = ('Score: %5Dt');
my @expected_output9 = ('Score: Dt');
my @actual_output9 = format_it(@input9);
assert($actual_output9[0] eq $expected_output9[0], "Test case 9 failed: @actual_output9 vs @expected_output9");

print "$0 - test passed.\n";
