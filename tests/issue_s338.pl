# issue s338 - Use of uninitialized value $class in string eq at ../../Pythonizer.pm line 2171
use strict;
use warnings;
no warnings 'experimental';
use Carp::Assert;

my (@starts, @ends);

sub parse_datetime {
    my $datetime = shift;
    my $pattern = qr{
        (?<y>\d{4})-(?<m>\d{2})-(?<d>\d{2})\s
        (?<h>\d{2}):(?<mn>\d{2}):(?<s>\d{2})\s
        (?<mon_name>\w+)\s(?<mon_abb>\w{3})\s
        (?<dow_name>\w+)\s(?<dow_abb>\w{3})\s
        (?<dow_char>\w)\s(?<dow_num>\d)\s
        (?<doy>\d{3})\s(?<nth>\d+[a-z]{2})\s
        (?<ampm>[AP]M)\s(?<epochs>\d+)\s
        (?<epocho>\d+)\s(?<tzstring>[A-Za-z/_]+)\s
        (?<off>[+-]\d{4})\s(?<abb>\w+)\s
        (?<zone>[A-Za-z\s]+)\s(?<g>\d+)\s
        (?<w>\d+)\s(?<l>\d+)\s(?<u>\d+)
    }x;

    if ($datetime =~ $pattern) {
        my($y,$m,$d,$h,$mn,$s,
          $mon_name,$mon_abb,$dow_name,$dow_abb,$dow_char,$dow_num,
          $doy,$nth,$ampm,$epochs,$epocho,
          $tzstring,$off,$abb,$zone,
          $g,$w,$l,$u) =
            @+{qw(y m d h mn s
                  mon_name mon_abb dow_name dow_abb dow_char dow_num doy
                  nth ampm epochs epocho tzstring off abb zone g w l u)};
        @starts = @-;
        @ends = @+;
        return ($y,$m,$d,$h,$mn,$s,
                $mon_name,$mon_abb,$dow_name,$dow_abb,$dow_char,$dow_num,
                $doy,$nth,$ampm,$epochs,$epocho,
                $tzstring,$off,$abb,$zone,
                $g,$w,$l,$u);
    } else {
        return;
    }
}

# Test cases
my @test1 = parse_datetime('2023-04-03 08:30:45 April Apr Monday Mon M 1 093 3rd AM 1677627845 619315245 America/New_York -0400 EDT Eastern Daylight Time 1 15 0 123');
my @expected1 = ('2023', '04', '03', '08', '30', '45', 'April', 'Apr', 'Monday', 'Mon', 'M', '1', '093', '3rd', 'AM', '1677627845', '619315245', 'America/New_York', '-0400', 'EDT', 'Eastern Daylight Time', '1', '15', '0', '123');
my @expected_starts = qw/0 0 5 8 11 14 17 20 26 30 37 41 43 45 49 53 56 67 77 94 100 104 126 128 131 133/;
my @expected_ends = qw/136 4 7 10 13 16 19 25 29 36 40 42 44 48 52 55 66 76 93 99 103 125 127 130 132 136/;
assert(@test1 ~~ @expected1);
assert(@starts ~~ @expected_starts);
assert(@ends ~~ @expected_ends);

my @test2 = parse_datetime('2021-12-31 23:59:59 December Dec Friday Fri F 5 365 1st PM 1640995199 568492199 America/Los_Angeles -0800 PST Pacific Standard Time 0 52 1 53');
my @expected2 = ('2021', '12', '31', '23', '59', '59', 'December', 'Dec', 'Friday', 'Fri', 'F', '5', '365', '1st', 'PM', '1640995199', '568492199', 'America/Los_Angeles', '-0800', 'PST', 'Pacific Standard Time', '0', '52', '1', '53');
@expected_starts = qw/0 0 5 8 11 14 17 20 29 33 40 44 46 48 52 56 59 70 80 100 106 110 132 134 137 139/;
@expected_ends = qw/141 4 7 10 13 16 19 28 32 39 43 45 47 51 55 58 69 79 99 105 109 131 133 136 138 141/;
assert(@test2 ~~ @expected2);
assert(@starts ~~ @expected_starts);
assert(@ends ~~ @expected_ends);

my @test3 = parse_datetime('1999-01-01 00:00:00 January Jan Friday Fri F 5 001 1st AM 915148800 0 Europe/London +0000 GMT Greenwich Mean Time 1 0 0 1');
my @expected3 = ('1999', '01', '01', '00', '00', '00', 'January', 'Jan', 'Friday', 'Fri', 'F', '5', '001', '1st', 'AM', '915148800', '0', 'Europe/London', '+0000', 'GMT', 'Greenwich Mean Time', '1', '0', '0', '1');
@expected_starts = qw/0 0 5 8 11 14 17 20 28 32 39 43 45 47 51 55 58 68 70 84 90 94 114 116 118 120/;
@expected_ends = qw/121 4 7 10 13 16 19 27 31 38 42 44 46 50 54 57 67 69 83 89 93 113 115 117 119 121/;
assert(@test3 ~~ @expected3);
assert(@starts ~~ @expected_starts);
assert(@ends ~~ @expected_ends);

print "$0 - test passed!\n";
