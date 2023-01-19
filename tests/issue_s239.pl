# issue s239 - passing an anonymous sub as a sub arg generates bad code if the anonymous sub ends with an assignment statement
use Carp::Assert;

# Start with a simple test

my $result;

sub runit {
    my ($type, $subref, $arg) = @_;

    assert($type eq 'text');
    &$subref($arg);
}

runit(text => sub {
    my ($arg) = @_;
    $result = $arg + 1;
}, 2);

assert($result == 3);

# Now add some comments

runit(text => sub {
    my ($arg) = @_;
    # comment line
    $result = $arg + 1; # comment here
   }, # comment there
   7);      # comment everywhere

assert($result == 8);

# Try one where the sub is the last arg

sub runit2 {
    my ($type, $arg, $subref) = @_;

    assert($type eq 'text');
    &$subref($arg);
}

runit2(text => 3, sub {
    my ($arg) = @_;
    # comment line
    $result = $arg + 1;
    });

assert($result == 4);

# Now the harder test

package HTML::Parser;

sub new { bless {}, shift }
sub handler {
    ;
}
sub parse {
    ;
}

# Create an instance of the HTML::Parser class
my $parser = HTML::Parser->new(utf8_mode => 1);

# Define a variable to store the text extracted by the handler
my $Offset;

# Define a callback function to be called for each HTML tag
$parser->handler(text => sub {
  my ($offset) = @_;
  # Do something with the text here
  $Offset .= $offset;
}, "offset");

# Parse some HTML
$parser->parse('<html><body>This is a <strong>test</strong> of the <em>HTML::Parser</em> module.&amp;</body></html>');

eval {
    $parser->parse('');
};

print "$0 - test passed!\n";
