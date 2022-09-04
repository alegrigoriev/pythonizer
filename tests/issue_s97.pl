# issue s97 - File slurp idiom fails to read the file
# from agntm.pl
use Carp::Assert;

my $file = "tmp.tmp";
my %ggvt = ('3', 3, '1', 1, '2', 2);
my %keyEquivc = (1=>'e1', 2=>'e2', 3=>'e3');
my %flow_equivc = (e1=>1e7, e3=>3e7);

   open(FILE,">$file") or die("cannot open $file: $!");

   foreach $key (sort {$a<=>$b} keys %ggvt)
   {
      if (defined($flow_equivc{$keyEquivc{$key}}))
      {
         printf FILE ("$key %.6f %.6f\n",
            $flow_equivc{$keyEquivc{$key}}/1e6,
            $flow_equivc{$keyEquivc{$key}}/1e6);
      }
      else
      {
         printf FILE ("$key %.6f %.6f\n", 0, $ggvt{$key});
      }
   }
   close(FILE);

my $lines = "1 10.000000 10.000000\n2 0.000000 2.000000\n3 30.000000 30.000000\n";
open(FILE, "<$file") or die("cannot open $file: $!");
my $entire_file = do { local $/; <FILE> };
close(FILE);
assert($lines eq $entire_file);
print "$0 - test passed\n";

END {
	unlink "tmp.tmp";
}
