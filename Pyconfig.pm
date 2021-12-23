#
# Pythonizer config module
#

use strict;
use warnings;

package Pyconfig;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( $TABSIZE $MAXNESTING $MAXLINELEN $DEFAULT_VAR $DEFAULT_MATCH $PERL_ARG_ARRAY $PERL_SORT_ $GLOB_LIST $ARG_PARSER $DIAMOND $EVAL_RESULT $EVAL_RETURN_EXCEPTION $SUBPROCESS_RC $SCRIPT_START $DO_CONTROL $ANONYMOUS_SUB $DIE_TRACEBACK %CONSTANT_MAP %GLOBALS %GLOBAL_TYPES %PYTHON_KEYWORD_SET %PYTHON_RESERVED_SET array_var_name hash_var_name scalar_var_name label_exception_name $ELSIF_TEMP $INDEX_TEMP $SUBSCRIPT_TEMP %CONVERTER_MAP);

# use Readonly;		# Readonly is not installed by default so skip it!

#Readonly our $DEFAULT_VAR => "default_var";
#Readonly our $DEFAULT_MATCH => "default_match";
#Readonly our $PERL_ARG_ARRAY => "perl_arg_array";
#Readonly our $PERL_SORT_ => "perl_sort_";

# issue 32 - configure and shorten special variables

our $TABSIZE = 4;
our $MAXNESTING = 16;
our $MAXLINELEN = 188;
our $DEFAULT_VAR = "_d";
our $DEFAULT_MATCH = "_m";
our $GLOB_LIST = "_g";
our $PERL_ARG_ARRAY = "_args";
our $PERL_SORT_ = "";
our $ARG_PARSER = "_parser";
our $ELSIF_TEMP = "_e";                         # issue 58: used to capture complicated assignment in elsif, for and while loops
our $INDEX_TEMP = "_i";                         # SNOOPYJC: Used as a loop index for temp expressions
our $SUBSCRIPT_TEMP = "_s";                     # Used to capture complicated expressions in subscripts for arrays that need type conversion involved in ++/-- or +=/-= etc
our $DIAMOND = "_dia";                          # issue 66: for the <> operator
our $EVAL_RESULT = "_eval_result";              # issue 42
our $EVAL_RETURN_EXCEPTION = "EvalReturn";      # issue 42
our $SUBPROCESS_RC = "CHILD_ERROR";
our $ANONYMOUS_SUB = "_f";                      # issue 81
our $DIE_TRACEBACK = "TRACEBACK";        # issue 81
our $SCRIPT_START = "_script_start";    # Warning: if you change this, then also change pyf/_get*.py (now in lib/pythonizer.py)
our $DO_CONTROL = "_do_";
#
# Put contants here that need to be recognized literally and translated to python references.
#
# flock uses LOCK_SH, LOCK_EX, LOCK_NB and LOCK_UN from fcntl.  
# os.open uses O_CREAT, O_EXCL, O_WRONLY, O_TRUNC, O_RDWR, O_APPEND, O_RDONLY, O_RANDOM, O_SEQUENTIAL, O_TEMPORARY, O_TEXT, O_BINARY, O_NOINHERIT, O_SHORT_LIVED
#
my @locks = qw/LOCK_SH LOCK_EX LOCK_NB LOCK_UN/;
my @opens = qw/O_CREAT O_EXCL O_WRONLY O_TRUNC O_RDWR O_APPEND O_RDONLY O_RANDOM O_SEQUENTIAL O_TEMPORARY O_TEXT O_BINARY O_NOINHERIT O_SHORT_LIVED/;
my @signals = qw/ABRT ALRM BREAK BUS CHLD CLD CONT FPE HUP ILL INT KILL PIPE SEGV TERM USR1 USR2 WINCH _DFL _IGN/;
my %flocks = map { $_ => "fcntl.$_" } @locks;
my %os_opens = map { $_ => "os.$_" } @opens;
my %sigs = map { $_ => "signal.SIG$_" } @signals;
our %CONSTANT_MAP = (%flocks, %os_opens, %sigs);

# SNOOPYJC: Globals to be generated in the code header
my $open_mode_map = "{'<': 'r', '>': 'w', '+<': 'r+', '+>': 'w+', '>>': 'a', '+>>': 'a+', '|': '|-'}";
my $dup_map = "dict(STDIN=0, STDOUT=1, STDERR=2)";
# **********
# ********** NOTE: When adding a new global, remember to define it's type below!! **********
# **********
our %GLOBALS = ($SCRIPT_START=>'tm_py.time()', 
                LIST_SEPARATOR=>"' '", 
                INPUT_RECORD_SEPARATOR=>'"\n"',
                OS_ERROR=>"''", 
                OUTPUT_AUTOFLUSH=>0,
                $SUBPROCESS_RC=>0, 
                AUTODIE=>0, 
                TRACEBACK=>0, 
                _OPEN_MODE_MAP=>$open_mode_map, 
                _DUP_MAP=>$dup_map);
our %GLOBAL_TYPES = ($SCRIPT_START=>'I', LIST_SEPARATOR=>'S', INPUT_RECORD_SEPARATOR=>'S', OS_ERROR=>'S', OUTPUT_AUTOFLUSH=>'I', $SUBPROCESS_RC=>'I', _OPEN_MODE_MAP=>'h of S', _DUP_MAP=>'h of I',
                     AUTODIE=>'I', TRACEBACK=>'I');

sub hash_var_name                       # issue 92
# Given the name of a %hash, return the python name for it.  Only used if there is a name conflict.
# Required because they can also define a scalar of the same name, which needs to be distinct
{
    my $name = shift;
    return "${name}_h";
}
sub array_var_name                      # issue 92
# Given the name of an @array, return the python name for it.  Only used if there is a name conflict.
# Required because they can also define a scalar of the same name, which needs to be distinct
{
    my $name = shift;
    return "${name}_a";
}
sub scalar_var_name                      # issue 92
# Given the name of a $scalar, return the python name for it.  Only used if there is a name conflict.
# Required because they can also define a sub of the same name, which needs to be distinct
{
    my $name = shift;
    return "${name}_v";
}

sub label_exception_name                # issue 94
# Given the name of a label (or undef), generate an exception we can raise to break out of that label block
{
    my $label = shift;

    return "LoopControl" if(!defined $label || $label eq '');
    return "LoopControl_$label";
}

# issue 41

our @PYTHON_KEYWORDS = qw(False None True and as assert async await break class continue def del elif else except finally for from global if import in is lambda nonlocal not or pass raise try while with yield);
our @PYTHON_BUILTINS = qw(abs aiter all any anext ascii bin bool breakpoint bytearray bytes callable chr classmethod compile complex delattr dict dir divmod enumerate eval exec filter float format frozenset getattr globals hasattr hash help hex id input int isinstance issubclass iter len list locals map max memoryview min next object oct open ord pow print property range repr reversed round set setattr slice sorted staticmethod str sum super tuple type vars zip);
our %PYTHON_KEYWORD_SET = map { $_ => 1 } @PYTHON_KEYWORDS;
our %PYTHON_RESERVED_SET = map { $_ => 1 } (@PYTHON_KEYWORDS, @PYTHON_BUILTINS);

our %CONVERTER_MAP = (I=>'_int', N=>'_num', S=>'_str');

1;
