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

my %char2entity = ('&'=>'amp', '>'=>'gt', '<'=>'lt', '"'=> 'quot', "'"=> 'apos');

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
