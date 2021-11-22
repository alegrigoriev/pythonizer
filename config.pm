#
# Pythonizer config module
#

use strict;
use warnings;

package config;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( $DEFAULT_VAR $DEFAULT_MATCH $PERL_ARG_ARRAY $PERL_SORT_ %PYTHON_KEYWORD_SET );

# use Readonly;		# Readonly is not installed by default so skip it!

#Readonly our $DEFAULT_VAR => "default_var";
#Readonly our $DEFAULT_MATCH => "default_match";
#Readonly our $PERL_ARG_ARRAY => "perl_arg_array";
#Readonly our $PERL_SORT_ => "perl_sort_";

# issue 32 - configure and shorten special variables

#Readonly our $DEFAULT_VAR => "_d";
#Readonly our $DEFAULT_MATCH => "_m";
#Readonly our $PERL_ARG_ARRAY => "_args";
#Readonly our $PERL_SORT_ => "";
#Readonly our $PERL_SORT_B => "b";

our $DEFAULT_VAR = "_d";
our $DEFAULT_MATCH = "_m";
our $PERL_ARG_ARRAY = "_args";
our $PERL_SORT_ = "";
# issue 41
our @PYTHON_KEYWORDS = qw(False None True and as assert async await break class continue def del elif else except finally for from global if import in is lambda nonlocal not or pass raise try while with yield);
our %PYTHON_KEYWORD_SET = map { $_ => 1 } @PYTHON_KEYWORDS;

1;
