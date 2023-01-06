# issue s228: hash initialization with ? : condition generates bad code
# (from HTML::Entities)
use Carp::Assert;

our %entity2char;

%entity2char = (
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
);

# Sample python code for this:
# {'a': 1, **({'b': 2, 'c': 3} if x > 3 else {})}

assert($entity2char{amp} eq '&');
assert($entity2char{AElig} eq chr(198));
assert($entity2char{'diams;'} eq chr(9830));

sub subr {
    my($p1,     # c1
       $p2,     # c2
       $p3      # c3
      ) = @_;   # c4
}

subr(1, # C1
     2, # C2
     3  # C3
 )      # C4
 ;      # C5


sub test_mls {
    my $mls = 'l1 # not a comment
l2';
    assert($mls eq "l1 # not a comment\nl2");
}
test_mls();


print "$0 - test passed!\n";
