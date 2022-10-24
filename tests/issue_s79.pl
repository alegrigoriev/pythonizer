# issue s79 - Use of uninitialized value $prev_line in rindex at ../pythonizer/pythonizer line
use Carp::Assert;


sub testit
{
	$_ = 'thisandthat';
	$that = 42;
	s/this/$that+1/e;
}

testit();

assert($_ eq '43andthat');

my %char2entity = ('&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"'=> '&quot;', "'"=> '&apos;');

sub return_or
{
	$char2entity{$_[0]} || num_entity($_[0]);
}
assert(return_or('&') eq '&amp;');
assert(return_or('+') eq '&#x2B;');

sub return_or_split
{
	$char2entity{$_[0]} 
	|| 
	num_entity($_[0]);
}
assert(return_or_split('&') eq '&amp;');
assert(return_or_split('+') eq '&#x2B;');

sub return_and
{
	$char2entity{$_[0]} && num_entity($_[0]);
}
assert(return_and('&') eq '&#x26;');
assert(return_and('+') eq '');

sub return_this_or_that
{
	if($_[0]) { 1 } else { 2 }
}
assert(return_this_or_that(1) == 1);
assert(return_this_or_that(0) == 2);

sub return_qm_colon { $_[0] ? 1 : 2 }
assert(return_qm_colon(1) == 1);
assert(return_qm_colon(0) == 2);

sub encode_entities
{
    my $ref = \$_[0];
    if(0) {
	;
    } else {
 	$$ref =~ s/([^\n\r\t !\#\$%\(-;=?-~])/$char2entity{$1} || num_entity($1)/ge;
    }
    $$ref;
}

sub num_entity {
    sprintf "&#x%X;", ord($_[0]);
}

my $entity = "abc&<def";
my $encoded = encode_entities($entity);

print "$encoded\n";

	
print "$0 - test passed!\n";
