# issue s80 - substr outside of string at ../pythonizer/pythonizer line
# code from Text/ParseWords.pm
use Carp::Assert;

# Start with some easy ones
my $str = '#abc';
$str =~ s/#/X/;
assert($str eq 'Xabc');

$str = '#abc';
$aye = 'a';
$str =~ s/[#]  $aye
          b     # comment
          /X/x;
assert($str eq 'Xc');

$str = '\\#abc';
$str =~ s/\\  \#  $aye
         b     # comment
         /X/x;
assert($str eq 'Xc');

$str = '\\#abc';
$str =~ s/\\  # comment not $str
         \# $aye
         b     # comment/X/x;
assert($str eq 'Xc');

# Try some matching only
$str = '\\#abc';
assert($str =~ /\\  # comment not $str
         \# $aye
         b     # comment/x);
assert($str =~ m(\\  # comment not $str
         \# $aye
         b     # comment)x);
my $pat = qr(\\  # comment not $str
         \# $aye
         b     # comment)x;
assert($str =~ $pat);

my @spl = split /B # comment not $str
                 # another comment/ix, $str;
assert(scalar(@spl) == 2);
assert($spl[0] eq '\\#a');
assert($spl[1] eq 'c');

$str = '123';
assert($str =~ /$#spl   # Prev # is not a comment! not @spl
                2       # comment not $str
                3/x);

# Try the double-x flag
$str = ' abc ';
$str =~ s/^[ a - z ]    # should not match - spaces are ignored
           [\\ a Z]/nope/xx;
assert($str eq ' abc ');
$str =~ s/^[ a - z \  ]     # should match the escaped space
           [\\	 a Z]/yup/xx;   # contains a tab char in the brackets
assert($str eq 'yupbc ');

my $PERL_SINGLE_QUOTE;

sub parse_line {
    my($delimiter, $keep, $line) = @_;
    my($word, @pieces);

    no warnings 'uninitialized';	# we will be testing undef strings

    while (length($line)) {
        # This pattern is optimised to be stack conservative on older perls.
        # Do not refactor without being careful and testing it on very long strings.
        # See Perl bug #42980 for an example of a stack busting input.
        $line =~ s/^
                    (?: 
                        # double quoted string
                        (")                             # $quote
                        ((?:[^\\"]*(?:\\.[^\\"]*)*))"   # $quoted 
		    |	# --OR--
                        # singe quoted string
                        (')                             # $quote
                        ((?:[^\\']*(?:\\.[^\\']*)*))'   # $quoted
                    |   # --OR--
                        # unquoted string
		        (                               # $unquoted 
                            (?:\\.|[^\\"'])*?           
                        )		
                        # followed by
		        (                               # $delim
                            \Z(?!\n)                    # EOL
                        |   # --OR--
                            (?-x:$delimiter)            # delimiter
                        |   # --OR--                    
                            (?!^)(?=["'])               # a quote
                        )  
		    )//xs or return;		# extended layout                  
        my ($quote, $quoted, $unquoted, $delim) = (($1 ? ($1,$2) : ($3,$4)), $5, $6);
        #print "$quote, $quoted, $unquoted, $delim\n";


	return() unless( defined($quote) || length($unquoted) || length($delim));

        if ($keep) {
	    $quoted = "$quote$quoted$quote";
	}
        else {
	    $unquoted =~ s/\\(.)/$1/sg;
	    if (defined $quote) {
		$quoted =~ s/\\(.)/$1/sg if ($quote eq '"');
		$quoted =~ s/\\([\\'])/$1/g if ( $PERL_SINGLE_QUOTE && $quote eq "'");
            }
	}
        $word .= substr($line, 0, 0);	# leave results tainted
        $word .= defined $quote ? $quoted : $unquoted;
 
        if (length($delim)) {
            push(@pieces, $word);
            push(@pieces, $delim) if ($keep eq 'delimiters');
            undef $word;
        }
        if (!length($line)) {
            push(@pieces, $word);
	}
    }
    return(@pieces);
}

my @pieces = parse_line('\s+', 0, q{this   is "a test" of\ parse_line \"for you});

assert( scalar(@pieces) == 6);
assert($pieces[0] eq 'this');
assert($pieces[1] eq 'is');
assert($pieces[2] eq 'a test');
assert($pieces[3] eq 'of parse_line');
assert($pieces[4] eq '"for');
assert($pieces[5] eq 'you');


print "$0 - test passed!\n"
