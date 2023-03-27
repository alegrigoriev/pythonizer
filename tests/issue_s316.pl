# issue s316 - Hash being initialized from some hash keys/values and also another hashref generates bad code
no warnings 'experimental';

sub _new_drh {	# called by DBD::<drivername>::driver()
    my ($class, $initial_attr, $imp_data) = @_;
    # Provide default storage for State,Err and Errstr.
    # Note that these are shared by all child handles by default! XXX
    # State must be undef to get automatic faking in DBI::var::FETCH
    my ($h_state_store, $h_err_store, $h_errstr_store) = (undef, undef, '');
    my $attr = {
	# these attributes get copied down to child handles by default
	'State'		=> \$h_state_store,  # Holder for DBI::state
	'Err'		=> \$h_err_store,    # Holder for DBI::err
	'Errstr'	=> \$h_errstr_store, # Holder for DBI::errstr
	'TraceLevel' 	=> 0,
	FetchHashKeyName=> 'NAME',
	%$initial_attr,
    };
    $attr;
}

use Carp::Assert;

# Test 1: Ensure the default attributes are set correctly
{
    my $default_attr = _new_drh();

    assert(exists $$default_attr{'State'}, 'State attribute exists');
    assert(exists $$default_attr{'Err'}, 'Err attribute exists');
    assert(defined $$default_attr{'Errstr'}, 'Errstr attribute is defined');
    assert($$default_attr{'TraceLevel'} == 0, 'TraceLevel attribute is 0');
    assert($$default_attr{'FetchHashKeyName'} eq 'NAME', 'FetchHashKeyName attribute is NAME');
}

# Test 2: Ensure provided initial attributes are merged correctly
{
    my %initial_attr = (
        'TraceLevel' => 2,
        'FetchHashKeyName' => 'NAME_lc',
        'CustomAttribute' => 'custom_value',
    );
    my $merged_attr = _new_drh(undef, \%initial_attr);

    assert($$merged_attr{'TraceLevel'} == 2, 'TraceLevel attribute is updated to 2');
    assert($$merged_attr{'FetchHashKeyName'} eq 'NAME_lc', 'FetchHashKeyName attribute is updated to NAME_lc');
    assert($$merged_attr{'CustomAttribute'} eq 'custom_value', 'CustomAttribute is added to the merged attributes');
}

# Test 3: Ensure the subroutine returns the expected attribute hash reference
{
    my %initial_attr = (
        'TraceLevel' => 3,
        'FetchHashKeyName' => 'NAME_uc',
    );
    my $returned_attr = _new_drh('TestDriver', \%initial_attr);

    assert(!defined ${$returned_attr->{'State'}}, 'State attribute is undef');
    assert(!defined ${$returned_attr->{'Err'}}, 'Err attribute is undef');
    assert(${$returned_attr->{'Errstr'}} eq '', 'Errstr attribute is an empty string');
    assert($returned_attr->{'TraceLevel'} == 3, 'TraceLevel attribute is 3');
    assert($returned_attr->{'FetchHashKeyName'} eq 'NAME_uc', 'FetchHashKeyName attribute is NAME_uc');
}

# Now let's reproduce issue s228, but with a hashref:

our $entity2char;

$entity2char = {
 # Some normal chars that have special meaning in SGML context
 amp  => '&',     # ampersand
 'gt' => '>',     # greater than

 # PUBLIC ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML
 AElig	=> chr(198),  # capital AE diphthong (ligature)
 Aacute	=> chr(193),  # capital A, acute accent
 dummy => chr(0),
     # Comment after dummy line with no tail comment
 'emsp;' => chr(8195), # always include this key-value pair

     # Add some more to modern perls only

 ( $] > 5.007 ? (
  'OElig;'    => chr(338),  # comment OElig
  'diams;'    => chr(9830), # comment diams;
  silly => # c1
  chr      # c2
  (        # c3
      4    # c4
  )        # c5
  ,        # c6
  ) : ())
};

# Sample python code for this:
# {'a': 1, **({'b': 2, 'c': 3} if x > 3 else {})}

assert($entity2char->{amp} eq '&');
assert($entity2char->{AElig} eq chr(198));
assert($entity2char->{'diams;'} eq chr(9830));

# Try one with an array in it

my @array_of_more = ('key','override', 'key2', 'value2');
my $simple_array = {@array_of_more};
assert(keys %$simple_array == 2);
assert($simple_array->{key} eq 'override');
assert($simple_array->{key2} eq 'value2');

my $try_array = {key => 'value', xx=>'yy', @array_of_more};
assert(keys %$try_array == 3);
assert($try_array->{key} eq 'override');
assert($try_array->{key2} eq 'value2');
assert($try_array->{xx} eq 'yy');

my $aom = \@array_of_more;
my $try_array2 = {key => 'value', xx=>'yy', @$aom};
assert(keys %$try_array2 == 3);
assert($try_array2->{key} eq 'override');
assert($try_array2->{key2} eq 'value2');
assert($try_array2->{xx} eq 'yy');

# Try one with an array expression

my $array_expr = {split / /, 'key1 value1 key2 value2'};
assert(keys %$array_expr == 2);
assert($array_expr->{key1} eq 'value1');
assert($array_expr->{key2} eq 'value2');

$array_expr = {key1=>'wrong', xx=>'yy', split / /, 'key1 value1 key2 value2'};
assert(keys %$array_expr == 3);
assert($array_expr->{key1} eq 'value1');
assert($array_expr->{key2} eq 'value2');
assert($array_expr->{xx} eq 'yy');

# Try a simple conversion from a hash to a hashref

my %hash = (key1=>'value1', key2=>'value2');
my $hashref = {%hash};
assert($hashref->{key1} eq $hash{key1});
assert($hashref->{key2} eq $hash{key2});

# Try one with a hash in it

my $try_hash = {key1 => 'vv', xx=>'yy', %hash};
assert(keys %$try_hash == 3);
assert($try_hash->{key1} eq 'value1');
assert($try_array->{key2} eq 'value2');
assert($try_array->{xx} eq 'yy');

# Make sure arrayrefs still work too

my @init = (4,5,6);
my $arrref = [1, 2, 3, @init];
assert($arrref ~~ [1,2,3,4,5,6]);

my $init = [4, 5, 6];
my $arrref2 = [1, 2, 3, @$init];

assert($arrref2 ~~ [1,2,3,4,5,6]);

my %h = (k1=>'v1');
my $arrref3 = [1, 2, 3, %h];
assert($arrref3 ~~ [1,2,3,'k1','v1']);

my $h = {k1=>'v1'};
my $arrref4 = [1, 2, 3, %$h];
assert($arrref4 ~~ [1,2,3,'k1','v1']);

# Try interpolating a hashref into a hash

my %ha = (key1=>'value1', %$h);
assert(keys %ha == 2);
assert($ha{key1} eq 'value1');
assert($ha{k1} eq 'v1');

# Try interpolating an arrayref into a hash

my %ha2 = (key=>'value', xx=>'yy', @$aom);
assert(keys %ha2 == 3);
assert($ha2{key} eq 'override');
assert($ha2{key2} eq 'value2');
assert($ha2{xx} eq 'yy');

# Try interpolating an arrayref into an array
my @arr = (1, 2, 3, @$init);
assert(\@arr ~~ [1,2,3,4,5,6]);

# Another case from DBI.pm:

my $dbi_connect_method = 'method';

# clone_attr subroutine
sub clone_attr {
    my $attr = shift;

    # Try a hash:

    my (%at0, %at1);
    if($attr) {
        %at0 = %$attr;
        %at0 = (%at0, dbi_connect_method => $dbi_connect_method);
        %at1 = (%$attr, dbi_connect_method => $dbi_connect_method);
    } else {
        %at0 = (dbi_connect_method => $dbi_connect_method);
        %at1 = %at0;
    }
    my %at = ($attr ? %$attr : (), # clone, don't modify callers data
        dbi_connect_method => $dbi_connect_method,
    );
    assert(\%at ~~ \%at0);
    assert(\%at ~~ \%at1);

    $attr = {
        $attr ? %$attr : (), # clone, don't modify callers data
        dbi_connect_method => $dbi_connect_method,
    };
    assert(\%at ~~ $attr);
    $attr;
}

# Test cases
{
    my $input = { a => 1, b => 2, dbi_connect_method => 'initial' };
    my $output = clone_attr($input);

    assert(defined $output, 'Output is defined');
    assert(ref $output eq 'HASH', 'Output is a hash reference');
    #assert($input != $output, 'Input and output hash references are different');
    assert(%$input == %$output, 'Input and output have the same number of elements');

    while (my ($key, $value) = each %$input) {
        assert(exists $output->{$key}, "Output has key '$key'");
        $value = 'method' if $key eq 'dbi_connect_method';
        assert($output->{$key} == $value, "Output value for key '$key' ($output->{$key}) is the same as input ($value)");
    }

    assert($output->{dbi_connect_method} eq 'method', "'dbi_connect_method' key value is correct");
}

{
    my $input = {};
    my $output = clone_attr($input);

    assert(defined $output, 'Output is defined');
    assert(ref $output eq 'HASH', 'Output is a hash reference');
    #assert($input != $output, 'Input and output hash references are different');
    assert($output->{dbi_connect_method} eq 'method', "'dbi_connect_method' key value is correct");
}

{
    my $input = undef;
    my $output = clone_attr($input);

    assert(defined $output, 'Output is defined');
    assert(ref $output eq 'HASH', 'Output is a hash reference');
    assert($output->{dbi_connect_method} eq 'method', "'dbi_connect_method' key value is defined");
}

print "$0 - test passed!\n";
