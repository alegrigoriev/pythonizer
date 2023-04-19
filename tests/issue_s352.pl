# issue s352 - Pattern match with variable sub-pattern doesn't create the match variable

package Date::Manip::TZ;
sub _config_var_setdate {
   my($self,$val,$force) = @_;
   my $base = $$self{'base'};

   my $dstrx = qr/(?:,\s*(stdonly|dstonly|std|dst))?/i;
   my $zonrx = qr/,\s*(.+)/;
   my $da1rx = qr/(\d\d\d\d)(\d\d)(\d\d)(\d\d):(\d\d):(\d\d)/;
   my $da2rx = qr/(\d\d\d\d)\-(\d\d)\-(\d\d)\-(\d\d):(\d\d):(\d\d)/;
   my $time  = time;

   my($op,$date,$dstflag,$zone,@date,$offset,$abb);

   #
   # Parse the argument
   #

   if ($val =~ /^now${dstrx}${zonrx}$/oi) {
      # now,ZONE
      # now,DSTFLAG,ZONE
      #    Sets now to the system date/time but sets the timezone to be ZONE

      $op = 'nowzone';
      ($dstflag,$zone) = ($1,$2);

   } elsif ($val =~ /^zone${dstrx}${zonrx}$/oi) {
      # zone,ZONE
      # zone,DSTFLAG,ZONE
      #    Converts 'now' to the alternate zone

      $op = 'zone';
      ($dstflag,$zone) = ($1,$2);

   } elsif ($val =~ /^${da1rx}${dstrx}${zonrx}$/o  ||
            $val =~ /^${da2rx}${dstrx}${zonrx}$/o) {
      # DATE,ZONE
      # DATE,DSTFLAG,ZONE
      #    Sets the date and zone

      $op = 'datezone';
      my($y,$m,$d,$h,$mn,$s);
      ($y,$m,$d,$h,$mn,$s,$dstflag,$zone) = ($1,$2,$3,$4,$5,$6,$7,$8);
      $date = [$y,$m,$d,$h,$mn,$s];

   } elsif ($val =~ /^${da1rx}$/o  ||
            $val =~ /^${da2rx}$/o) {
      # DATE
      #    Sets the date in the system timezone

      $op = 'date';
      my($y,$m,$d,$h,$mn,$s) = ($1,$2,$3,$4,$5,$6);
      $date   = [$y,$m,$d,$h,$mn,$s];
      #$zone   = $self->_now('systz',1);

   }
   return ($op, $dstflag, $zone, $date);
}

sub new {
	return bless { base => 'dummy_base' }, shift;
}

package main;

use strict;
use warnings;
no warnings 'experimental';
use Carp::Assert;

# Test object
#my $test_obj = bless {
#'base' => 'dummy_base'
#}, 'main';
my $test_obj = new Date::Manip::TZ;

# Test cases
my @tests = (
    {
        'input' => 'now,UTC',
        'expected' => ['nowzone', undef, 'UTC', undef],
    },
    {
        'input' => 'now,std,UTC',
        'expected' => ['nowzone', 'std', 'UTC', undef],
    },
    {
        'input' => 'now,dstonly,America/New_York',
        'expected' => ['nowzone', 'dstonly', 'America/New_York', undef],
    },
    {
        'input' => 'zone,Asia/Tokyo',
        'expected' => ['zone', undef, 'Asia/Tokyo', undef],
    },
    {
        'input' => 'zone,dst,Asia/Tokyo',
        'expected' => ['zone', 'dst', 'Asia/Tokyo', undef],
    },
    {
        'input' => '2023040712:34:56,UTC',
        'expected' => ['datezone', undef, 'UTC', [2023, 4, 7, 12, 34, 56]],
    },
    {
        'input' => '2023-04-07-12:34:56,std,America/New_York',
        'expected' => ['datezone', 'std', 'America/New_York', [2023, 4, 7, 12, 34, 56]],
    },
    {
        'input' => '2023040712:34:56',
        'expected' => ['date', undef, undef, [2023, 4, 7, 12, 34, 56]],
    },
    {
        'input' => '2023-04-07-12:34:56',
        'expected' => ['date', undef, undef, [2023, 4, 7, 12, 34, 56]],
    },
);

# Test subroutine
sub test_config_var_setdate {
    my ($test_obj, $input, $expected) = @_;
    my @result = $test_obj->_config_var_setdate($input);

    assert(@result == @$expected, "Expected and actual arrays have different lengths for $input");
    for (my $i = 0; $i < @result; $i++) {
        if (ref($result[$i]) eq 'ARRAY') {
            assert($result[$i] ~~ $expected->[$i], "Mismatch in array element $i for $input ($result[$i] vs $expected->[$i])");
        } else {
            assert((!defined $result[$i] && !defined $expected->[$i]) || ($result[$i] eq $expected->[$i]), "Mismatch in element $i: expected '".($expected->[$i] // 'undef')."', got '".($result[$i] // 'undef')."'");
        }
    }
}

# Execute tests
foreach my $test (@tests) {
    test_config_var_setdate($test_obj, $test->{'input'}, $test->{'expected'});
}

print "$0 - test passed!\n";
