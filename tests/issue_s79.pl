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

sub testit_my
{
	$_ = 'thisandthat';
	my $that = 41;
	s/this/$that+1/e;
}

testit_my();

assert($_ eq '42andthat');

my %char2entity = ('&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"'=> '&quot;', "'"=> '&apos;');

sub return_or
{
	$char2entity{$_[0]} || num_entity($_[0]);
}
assert(return_or('&') eq '&amp;');
assert(return_or('+') eq '&#x2B;');

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

#print "$encoded\n";
assert($encoded eq 'abc&amp;&lt;def');

sub return_conditional
{
    my $result;

    $result = 1 if($_[0] == 1);
}
assert(return_conditional(1) == 1);
assert(!return_conditional(0));

sub return_conditional2
{
    return_conditional($_[0]) if($_[0] == 1);
}
assert(return_conditional2(1) == 1);
assert(!return_conditional2(0));

sub loop_exit
{
    my $cnt = $_[0];
    $tot = 0;
    $tot++ while($cnt--);
}

loop_exit(3);
assert($tot == 3);      # Make sure we don't sneak in a 'return' in the loop

sub process_file
{
    undef $fh;
    close($fh) or die("cannot close file!");
}
eval {
    process_file();
};
assert($@ =~ /close/);

sub process_file2
{
    open(IN, "<$0");
    undef $fh;
    close(IN, $fh) or die("cannot close file!");
}
eval {
    process_file();
};
assert($@ =~ /close/);
	
print "$0 - test passed!\n";
