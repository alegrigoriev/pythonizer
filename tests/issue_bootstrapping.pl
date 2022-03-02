# Issues found while bootstrapping
use Carp::Assert;
use feature 'state';
# pragma pythonizer -M

# Anonymous hashrefs weren't being initialized properly (they were being turned into sets!)
our %PREDEFINED_PACKAGES = (
	'POSIX'=>      [{perl=>'tmpnam', type=>':a', scalar=>'_tmpnam_s', scalar_type=>':S'},
			{perl=>'tmpfile', type=>':H'},
		       ],
	       );
my @all_perl;
my @all_type;
for my $pkg (keys %PREDEFINED_PACKAGES) { 
	for my $func_info(@{$PREDEFINED_PACKAGES{$pkg}}) {
		my $perl = $func_info->{perl};
		push @all_perl, $perl;
		my $type = $func_info->{type};
		push @all_type, $type;
	}
}

assert(join(' ', @all_perl) eq 'tmpnam tmpfile');
assert(join(' ', @all_type) eq ':a :H');

# Reference to __main__ as hash key was being changed to __main__()


%initialized = (__main__=>{'sys.argv'=>'a of S',
                       'os.name'=>'S',
                       EVAL_ERROR=>'S',
                       'os.environ'=>'h of s'});       # {sub}{varname} = type

assert($initialized{__main__}{EVAL_ERROR} eq 'S');

# shift @ARGV didn't generate proper code

@ARGV=('-a', '-b');
assert(shift @ARGV eq '-a');
assert(shift @ARGV eq '-b');
assert(!shift @ARGV);

# More cases of issue 129 where state variable is not interpolated

sub test_129
{
	my $arg = shift;

	state $sv = 'abc';

	$sv .= 'd';

	assert($sv eq 'abcd');
	assert("$sv" eq 'abcd');
	assert('abcd' =~ /$sv/);
	assert(`echo $sv` eq "abcd\n");
	assert(qx(echo $sv) eq "abcd\n");

	my $a = 'abcde';
	$a =~ s/$sv//;
	assert($a eq 'e');
}

test_129();

# Pythonizer.pm: a $) in a regex isn't the os grouplist

$line = ' # this is a comment';

if(  $line =~ /^\s*(#.*$)/ ){
	assert($1 eq '# this is a comment');
}

# getline: use <> to get a single line
@ARGV = ('issue_bootstrapping.pl');

sub getline
{
	my $line = <>;
	return $line;
}

$line = getline();
assert($line =~ /Issues found/);
assert($. == 1);
$line = getline();
assert($line =~ /Assert/);
assert($. == 2);
$line = getline();
assert($line =~ /^use feature/);
assert($. == 3);

@ValClass = qw/( a ) ( h ) (/;
 $balance=0;
 for ($i=0;$i<@ValClass;$i++ ){
    if( $ValClass[$i] eq '(' ){
       $balance++;
    }elsif( $ValClass[$i] eq ')' ){
       $balance--;
    }
 }
assert($balance == 1);

$closing_delim = '{';
   if( $closing_delim=~tr/{[>// ){
      $closing_delim=~tr/{[(</}])>/;
   }
assert($closing_delim eq '}');

eval {
	# Was giving a whole bunch of warning messages from the importer:
	require Net::FTP;
};

print "$0 - test passed!\n";
