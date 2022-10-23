#
# Pythonizer config module
#

use strict;
use warnings;

package Pyconfig;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( $TABSIZE $MAXNESTING $MAXLINELEN $DEFAULT_VAR $DEFAULT_MATCH $PERL_ARG_ARRAY $PERL_SORT_ $GLOB_LIST $ARG_PARSER $DIAMOND $EVAL_RESULT $EVAL_RETURN_EXCEPTION $SUBPROCESS_RC $SCRIPT_START $DO_CONTROL $ANONYMOUS_SUB $DIE_TRACEBACK %CONSTANT_MAP %GLOBALS %GLOBAL_TYPES %PYTHON_KEYWORD_SET %PYTHON_RESERVED_SET array_var_name hash_var_name scalar_var_name loop_var_name label_exception_name state_flag_name $ELSIF_TEMP $INDEX_TEMP $KEY_TEMP $SUBSCRIPT_TEMP %CONVERTER_MAP $LOCALS_STACK %SIGIL_MAP $MAIN_MODULE %BUILTIN_LIBRARY_SET $IMPORT_PATH_TEMP $IMPORT_MODULE_TEMP $MODULES_DIR $SUBPROCESS_OPTIONS $PERL_VERSION %PYF_CALLS %PYF_OUT_PARAMETERS $FUNCTION_RETURN_EXCEPTION %STAT_SUB %LSTAT_SUB %DASH_X $MAX_CHUNKS $MAX_DEPTH $DEFAULT_PACKAGE %ARRAY_INDEX_FUNCS %AUTOVIVIFICATION_CONVERTER_MAP $PERLLIB %PREDEFINED_PACKAGES @STANDARD_LIBRARY_DIRS $PRETTY_PRINTER $SHEBANG %OVERLOAD_MAP %CLASS_METHOD_SET $AUTHORS_FILE);

# use Readonly;		# Readonly is not installed by default so skip it!

#Readonly our $DEFAULT_VAR => "default_var";
#Readonly our $DEFAULT_MATCH => "default_match";
#Readonly our $PERL_ARG_ARRAY => "perl_arg_array";
#Readonly our $PERL_SORT_ => "perl_sort_";

# issue 32 - configure and shorten special variables

our $TABSIZE = 4;
our $MAXNESTING = 32;
our $MAXLINELEN = 188;
our $MAX_CHUNKS = 2048;		# Limit on gen_chunk
our $MAX_DEPTH = 1024;		# Limit on expression recursion depth
our $DEFAULT_VAR = "_d";
our $DEFAULT_MATCH = "_m";
our $GLOB_LIST = "_g";
our $PERL_ARG_ARRAY = "_args";
our $PERL_SORT_ = "";
our $ARG_PARSER = "_parser";
our $ELSIF_TEMP = "_e";                         # issue 58: used to capture complicated assignment in elsif, for and while loops
our $INDEX_TEMP = "_i";                         # SNOOPYJC: Used as a loop index for int temp expressions only
our $KEY_TEMP = "_k";				# SNOOPYJC: Used as a loop index for hash keys
our $SUBSCRIPT_TEMP = "_s";                     # Used to capture complicated expressions in subscripts for arrays that need type conversion involved in ++/-- or +=/-= etc
our $DIAMOND = "_dia";                          # issue 66: for the <> operator
our $EVAL_RESULT = "_eval_result";              # issue 42
our $EVAL_RETURN_EXCEPTION = "EvalReturn";      # issue 42
our $SUBPROCESS_RC = "CHILD_ERROR";
our $ANONYMOUS_SUB = "_f";                      # issue 81
our $DIE_TRACEBACK = "TRACEBACK";        # issue 81
our $SCRIPT_START = "BASETIME";    # Warning: if you change this, then also change pyf/_get*.py
our $LOCALS_STACK = "_locals_stack";    # issue 108
our $DO_CONTROL = "_do_";
our $IMPORT_PATH_TEMP = "_p";           # SNOOPYJC
our $IMPORT_MODULE_TEMP = "_m";         # SNOOPYJC
our $FUNCTION_RETURN_EXCEPTION="FunctionReturn";  # SNOOPYJC
our $DEFAULT_PACKAGE='main';            # SNOOPYJC: Default package name
our $PERLLIB='perllib';			# SNOOPYJC: our library name
#
# Put contants here that need to be recognized literally and translated to python references.
#
# flock uses LOCK_SH, LOCK_EX, LOCK_NB and LOCK_UN from fcntl.  
# os.open uses O_CREAT, O_EXCL, O_WRONLY, O_TRUNC, O_RDWR, O_APPEND, O_RDONLY, O_RANDOM, O_SEQUENTIAL, O_TEMPORARY, O_TEXT, O_BINARY, O_NOINHERIT, O_SHORT_LIVED
#
my @locks = qw/LOCK_SH LOCK_EX LOCK_NB LOCK_UN/;
my @stats = qw/S_IFSOCK S_IFLNK S_IFREG S_IFBLK S_IFDIR S_IFCHR S_IFIFO S_ISUID S_ISGID S_ISVTX S_IRWXU S_IRUSR S_IWUSR S_IXUSR S_IRWXG S_IRGRP S_IWGRP S_IXGRP S_IRWXO S_IROTH S_IWOTH S_IXOTH S_ENFMT S_IREAD S_IWRITE S_IEXEC UF_NODUMP UF_IMMUTABLE UF_APPEND UF_OPAQUE UF_NOUNLINK UF_COMPRESSED UF_HIDDEN SF_ARCHIVED SF_IMMUTABLE SF_APPEND SF_NOUNLINK SF_SNAPSHOT/;
my @opens = qw/O_CREAT O_EXCL O_WRONLY O_TRUNC O_RDWR O_APPEND O_RDONLY O_RANDOM O_SEQUENTIAL O_TEMPORARY O_TEXT O_BINARY O_NOINHERIT O_SHORT_LIVED SEEK_SET SEEK_CUR SEEK_END/;
my @signals = qw/ABRT ALRM BREAK BUS CHLD CLD CONT FPE HUP ILL INT KILL PIPE SEGV TERM USR1 USR2 WINCH _DFL _IGN/;
my @fhs = qw/STDERR STDIN STDOUT/;
my %flocks = map { $_ => "fcntl.$_" } @locks;
my %stat_flags = map { $_ => "stat.$_" } @stats;
my %os_opens = map { $_ => "os.$_" } @opens;
my %sigs = map { $_ => "signal.SIG$_" } @signals;
my %f_hs = map { $_ => "sys.".lc $_ } @fhs;
our %CONSTANT_MAP = (%flocks, %stat_flags, %os_opens, %sigs, %f_hs);

# SNOOPYJC: Globals to be generated in the code header
my $open_mode_map = "{'<': 'r', '>': 'w', '+<': 'r+', '+>': 'w+', '>>': 'a', '+>>': 'a+', '|': '|-'}";
my $dup_map = "dict(STDIN=0, STDOUT=1, STDERR=2)";
# **********
# ********** NOTE: When adding a new global, remember to define it's type below!! **********
# **********
our %GLOBALS = ($SCRIPT_START=>'tm_py.time()', 
                LIST_SEPARATOR=>"' '", 
                INPUT_LINE_NUMBER=>0,
                INPUT_RECORD_SEPARATOR=>'"\n"',
                OS_ERROR=>"''", 
		EVAL_ERROR=>"''",
                OUTPUT_AUTOFLUSH=>0,
		INPUT_LAYERS=>"''",
		OUTPUT_LAYERS=>"''",
		OUTPUT_FIELD_SEPARATOR=>"''",
		OUTPUT_RECORD_SEPARATOR=>"''",
                $SUBPROCESS_RC=>0, 
		# issue s45 WARNING=>1,
		WARNING=>0,		# issue s45
                AUTODIE=>0, 
                TRACEBACK=>0, 
		TRACE_RUN=>0,
                $LOCALS_STACK=>'[]',            # issue 108
                _OPEN_MODE_MAP=>$open_mode_map, 
                _DUP_MAP=>$dup_map);
our %GLOBAL_TYPES = ($SCRIPT_START=>'I', LIST_SEPARATOR=>'S', INPUT_LINE_NUMBER=>'I', 
		    INPUT_RECORD_SEPARATOR=>'m', OS_ERROR=>'S', EVAL_ERROR=>'S', OUTPUT_AUTOFLUSH=>'I', 
		    INPUT_LAYERS=>'S', OUTPUT_LAYERS=>'S', OUTPUT_FIELD_SEPARATOR=>'S', OUTPUT_RECORD_SEPARATOR=>'S',
		    $SUBPROCESS_RC=>'I', WARNING=>'I', _OPEN_MODE_MAP=>'h of S', _DUP_MAP=>'h of I',
                    $LOCALS_STACK=>'h of S',            # issue 108
		    TRACE_RUN=>'I', AUTODIE=>'I', TRACEBACK=>'I');

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
sub loop_var_name                      # issue s100
# Given the name of a loop var $scalar, return the python name for it.  Only used if there is a name conflict.
# Required because the value of the loop counter after a foreach loop reverts back to the value before the loop.
{
    my $name = shift;
    return "${name}_l";
}

sub label_exception_name                # issue 94
# Given the name of a label (or undef), generate an exception we can raise to break out of that label block
{
    my $label = shift;

    return "LoopControl" if(!defined $label || $label eq '');
    return "LoopControl_$label";
}

sub state_flag_name		# issue 128
# Given the long name of a state variable, return the name to use for the flag we
# set to only allow it to be initialized once
{
    my $name = shift;

    return "${name}_needs_init";
}

# issue 41

our @PYTHON_KEYWORDS = qw(False None True and as assert async await break class continue def del elif else except finally for from global if import in is lambda nonlocal not or pass raise return try while with yield);
our @PYTHON_BUILTINS = qw(abs aiter all any anext ascii bin bool breakpoint bytearray bytes callable chr classmethod compile complex delattr dict dir divmod enumerate eval exec filter float format frozenset getattr globals hasattr hash help hex id input int isinstance issubclass iter len list locals map max memoryview min next object oct open ord pow print property range re repr reversed round set setattr slice sorted staticmethod str sum super tuple type vars zip);
our @EXTRA_BUILTINS = qw(Array Hash ArrayHash perllib wantarray close);	# issue test coverage: Add "close" to prevent recursive loop calling fh.close()
our %PYTHON_KEYWORD_SET = map { $_ => 1 } @PYTHON_KEYWORDS;
our %PYTHON_RESERVED_SET = map { $_ => 1 } (@PYTHON_KEYWORDS, @PYTHON_BUILTINS, @EXTRA_BUILTINS);

our %CONVERTER_MAP = (I=>'_int', N=>'_num', F=>'_flt', S=>'_str', 'a of I'=>'_map_int', 'a of N'=>'_map_num', 'a of S'=>'_map_str', B=>'_pb');	# issue s124
our %AUTOVIVIFICATION_CONVERTER_MAP = (a=>'Array', h=>'Hash');
our %SIGIL_MAP = ('$'=>'s', '%'=>'h', '@'=>'a', ''=>'H');

our $MAIN_MODULE = 'sys.modules["__main__"]';	# Note this is changed to $DEFAULT_PACKAGE if the -m option is NOT passed (in Pythonizer.pm)

# List of libraries that pythonizer knows about and handles as built-ins:
our @BUILTIN_LIBRARIES = qw(strict warnings vars feature autodie utf8 autovivification subs Getopt::Long Getopt::Std Time::Local File::Basename Fcntl Carp::Assert Exporter Carp File::stat);
our %BUILTIN_LIBRARY_SET = map { $_ => 1 } @BUILTIN_LIBRARIES;

our $MODULES_DIR = "PyModules"; # Where we copy system modules to run pythonizer on them (for use/require)
our $SUBPROCESS_OPTIONS="-M -v0"; # Options to pythonizer for when we run on use/require'd modules
#our $SUBPROCESS_OPTIONS="-M -v3 -d5"; # Options to pythonizer for when we run on use/require'd modules

our $PERL_VERSION=5.034;
our %PYF_CALLS=(_basename=>'_fileparse', _croak=>'_shortmess', _confess=>'_longmess', 
		_format=>'_int,_num', _run=>'_carp,_cluck,_longmess,_shortmess,_need_sh',
                _lstat=>'_stat', _looks_like_binary=>'_looks_like_text,_carp,_longmess,_shortmess',
		Array=>'ArrayHash', Hash=>'ArrayHash',
		_bless=>'_carp,_init_package',
		_add_element=>'_num', _subtract_element=>'_num', _open=>'_need_sh',
		_close=>'_carp,_longmess,_shortmess', _run_s=>'_carp,_cluck,_longmess,_shortmess,_need_sh', _looks_like_text=>'_carp,_longmess,_shortmess',
		_get_creation_age_days=>'_cluck,_longmess',
		_get_access_age_days=>'_cluck,_longmess',
		_get_mod_age_days=>'_cluck,_longmess',
		_map_int=>'_int,_flatten', _map_num=>'_num,_flatten', _map_str=>'_flatten',
		_system=>'_carp,_cluck,_longmess,_shortmess,_need_sh',
		_kill=>'_carp,_cluck',
		_unpack=>'_pack', _assign_sparse=>'_int',
                _carp=>'_shortmess', _cluck=>'_longmess');      # Who calls who
our %PYF_OUT_PARAMETERS=();			# Functions with out parameters - which parameter (counting from 1) is "out"?
our %STAT_SUB=('File::stat'=>'_fstat');                 # Substitution for stat if they use File::stat
our %LSTAT_SUB=('File::stat'=>'_flstat');                 # Substitution for stat if they use File::stat

# Implementation of the "-X" unary operators.  (Note that these must also work on stat result tuples for File::stat)
our %DASH_X=(                   # https://perldoc.perl.org/functions/-X
#-r  File is readable by effective uid/gid.
            r=>'_is_readable',
#-w  File is writable by effective uid/gid.
            w=>'_is_writable',
#-x  File is executable by effective uid/gid.
            x=>'_is_executable',
#-o  File is owned by effective uid.
            o=>'_is_owned',
#-R  File is readable by real uid/gid.
            R=>'_is_real_readable',
#-W  File is writable by real uid/gid.
            W=>'_is_real_writable',
#-X  File is executable by real uid/gid.
            X=>'_is_real_executable',
#-O  File is owned by real uid.
            O=>'_is_real_owned',
#-e  File exists.
            e=>'_file_exists',
#-z  File has zero size (is empty).
            z=>'_is_empty_file',
#-s  File has nonzero size (returns size in bytes).
            s=>'_file_size',
#-f  File is a plain file.
            f=>'_is_file',
#-d  File is a directory.
            d=>'_is_dir',
#-l  File is a symbolic link (false if symlinks aren't supported by the file system).
            l=>'_is_link',
#-p  File is a named pipe (FIFO), or Filehandle is a pipe.
            p=>'_is_pipe',
#-S  File is a socket.
            S=>'_is_socket',
#-b  File is a block special file.
            b=>'_is_block_special',
#-c  File is a character special file.
            c=>'_is_char_special',
#-t  Filehandle is opened to a tty.
            t=>'_is_tty',
#-u  File has setuid bit set.
            u=>'_has_setuid',
#-g  File has setgid bit set.
            g=>'_has_setgid',
#-k  File has sticky bit set.
            k=>'_has_sticky',
#-T  File is an ASCII or UTF-8 text file (heuristic guess).
            T=>'_looks_like_text',
#-B  File is a "binary" file (opposite of -T).
            B=>'_looks_like_binary',
#-M  Script start time minus file modification time, in days.
            M=>'_get_mod_age_days',
#-A  Same for access time.
            A=>'_get_access_age_days',
#-C  Same for inode change time (Unix, may differ for other
#    platforms)
            C=>'_get_creation_age_days',
        );

# These are used when an array index or hash ref is used as an lvalue in an expression
our %ARRAY_INDEX_FUNCS = (''=>'_set_element', '+'=>'_add_element', '-'=>'_subtract_element',
    '*'=>'_multiply_element', '/'=>'_divide_element', '**'=>'_exponentiate_element',
    '.'=>'_concat_element', '%'=>'_mod_element', '^'=>'_xor_element',
    '|'=>'_or_element', '&'=>'_and_element', '<<'=>'_shift_left_element',
    '>>'=>'_shift_right_element', '~tr'=>'_translate_element', '~re'=>'_substitute_element');

# Standard perl libraries - if the "use" or "require" file path contains any of these names, then
# we don't try to translate it unless the '-s' flag is given:

our @STANDARD_LIBRARY_DIRS = qw(site_perl vendor_perl core_perl);

our $PRETTY_PRINTER = 'black -q -t py38 --fast';

our $SHEBANG = '#!/usr/bin/env python3';

our $AUTHORS_FILE = 'AUTHORS.rst';	# issue s19

# issue s3: implement Math::Complex - depends on use overload, which this table supports:
our %OVERLOAD_MAP = 	(
	'='	=> {normal=>'__copy__', unary=>1},
	'.='	=> {normal=>'__iadd__', assign=>1},
	'.'	=> {normal=>'__add__', reversed=>'__radd__'},
	'+='	=> {normal=>'__iadd__', assign=>1},
	'+'	=> {normal=>'__add__', reversed=>'__radd__'},
	'-='	=> {normal=>'__isub__', assign=>1},
	'-'	=> {normal=>'__sub__', reversed=>'__rsub__'},
	'*='	=> {normal=>'__imul__', assign=>1},
	'*'	=> {normal=>'__mul__', reversed=>'__rmul__'},
	'/='	=> {normal=>'__itruediv__', assign=>1},
	'/'	=> {normal=>'__truediv__', reversed=>'__rtruediv__'},
	'%='	=> {normal=>'__imod__', assign=>1},
	'%'	=> {normal=>'__mod__', reversed=>'__rmod__'},
	'**='	=> {normal=>'__ipow__', modulo=>1, assign=>1},
	'**'	=> {normal=>'__pow__', reversed=>'__rpow__', modulo=>1},
	'=='	=> {normal=>'__eq__'},
	'!='	=> {normal=>'__ne__'},
	'<='	=> {normal=>'__le__'},
	'>='	=> {normal=>'__ge__'},
	'<'	=> {normal=>'__lt__'},
	'>'	=> {normal=>'__gt__'},
	'eq'	=> {normal=>'__eq__'},
	'ne'	=> {normal=>'__ne__'},
	'le'	=> {normal=>'__le__'},
	'ge'	=> {normal=>'__ge__'},
	'lt'	=> {normal=>'__lt__'},
	'gt'	=> {normal=>'__gt__'},
	'<=>'	=> {normal=>'__spaceship__', reversed=>'__rspaceship__'},
	'cmp'	=> {normal=>'__cmp__', reversed=>'__rcmp__'},
	'<<='	=> {normal=>'__ilshift__', assign=>1},
	'<<'	=> {normal=>'__lshift__', reversed=>'__rlshift__'},
	'>>='	=> {normal=>'__irshift__', assign=>1},
	'>>'	=> {normal=>'__rshift__', reversed=>'__rrshift__'},
	'&='	=> {normal=>'__iand__', assign=>1},
	'&'	=> {normal=>'__and__', reversed=>'__rand__'},
	'|='	=> {normal=>'__ior__', assign=>1},
	'|'	=> {normal=>'__or__', reversed=>'__ror__'},
	'^='	=> {normal=>'__ixor__', assign=>1},
	'^'	=> {normal=>'__xor__', reversed=>'__rxor__'},
	'neg'	=> {normal=>'__neg__', unary=>1},
	'<>'	=> {normal=>'__iter__', unary=>1},
	#'-X'	=> {normal=>'_is_file', unary=>1}, # not handled
	#'!'	=> {normal=>'_not', unary=>1},	# not handled
	#'++'	=> {normal=>'_incr', unary=>1},	# not handled
	#'--'	=> {normal=>'_decr', unary=>1},	# not handled
	'~'	=> {normal=>'__invert__', unary=>1},
	'abs'	=> {normal=>'__abs__', unary=>1},
	'bool'	=> {normal=>'__bool__', unary=>1},
	'sqrt'	=> {normal=>'sqrt', unary=>1},
	'exp'	=> {normal=>'exp', unary=>1},
	'log'	=> {normal=>'log', unary=>1},
	'sin'	=> {normal=>'sin', unary=>1},
	'cos'	=> {normal=>'cos', unary=>1},
	'atan2'	=> {normal=>'__atan2__', reversed=>'__ratan2__'},
	#'int'	=> {normal=>'_int', unary=>1},	# not handled
        '""'    => {normal=>'__str__', unary=>1, converter=>$CONVERTER_MAP{S}},
	'${}'	=> {normal=>'_scalar', unary=>1},
	'@{}'	=> {normal=>'_array', unary=>1},
	'%{}'	=> {normal=>'_hash', unary=>1},
	'*{}'	=> {normal=>'_typeglob', unary=>1},
	'0+'	=> {normal=>'_num', unary=>1},
	#'qr'	=> {normal=>'_qr', unary=>1},		# not handled
	#'nomethod'=> {normal=>'_nomethod'},	# not handled
	#'fallback'=> {normal=>'_fallback'},	# not handled
	);

our @CLASS_METHODS = qw/new make/;	# These names will become class methods
our %CLASS_METHOD_SET = map { $_ => 1 } @CLASS_METHODS;

# Predefined package with function implementation.  The default python name
# for the function is "_perlName", unless python=>'...' is specified.  In perllib,
# the '_' is removed.  Specify the argument and result type with type=>"...". 
# If there is a separate function to call in scalar context, specify it 
# with scalar=>"...", and the corresponding type with scalar_type=>"..."
our %PREDEFINED_PACKAGES = (
	'File::Temp'=> [{perl=>'tempfile', type=>'a?:a', python=>'_tempfile_', 
			 scalar=>"_tempfile_s", scalar_type=>'a?:S', calls=>"_fileparse", scalar_calls=>"_tempfile_"},
			{perl=>'tempdir', type=>'a?:a', calls=>"_fileparse"},
			{perl=>'new', type=>'a?:H', python=>'_tempfile_s', calls=>"_fileparse,_tempfile_"},
			#this is a method only: {perl=>'filename', type=>'H:S'},
			{perl=>'newdir', type=>'a?:S', python=>'_tempdir'},
			{perl=>'mkstemp', type=>'S:a', calls=>"_fileparse"},
			{perl=>'mkstemps', type=>'SS:a', calls=>"_fileparse"},
			{perl=>'mktemp', type=>'S:S', calls=>"_fileparse"},
			{perl=>'mkdtemp', type=>'S:S', calls=>"_fileparse"},
			{perl=>'tmpnam', type=>':a', scalar=>"_tmpnam_s", scalar_type=>':S'},
			{perl=>'tmpfile', type=>':H'},
			{perl=>'tempnam', type=>'SS:S'},
		       ],
        'FileHandle'=>   [{perl=>'new', type=>'SI:H', python=>'_IOFile', 
			 calls=>'_open,_format,_autoflush,_binmode,_close,_eof,_fcntl,_fdopen,_format_write,_getc,_getpos,_ioctl,_input_line_number,_IOFile_open,_print,_printf,_read,_say,_setpos,_stat,_sysread,_sysseek,_syswrite,_truncate,_write_,_ungetc'},
			{perl=>'new_from_fd', type=>'II:H', python=>"_IOFile_from_fd", 
		         calls=>'_open,_IOFile,_format,_autoflush,_binmode,_close,_eof,_fcntl,_fdopen,_format_write,_getc,_getpos,_ioctl,_input_line_number,_IOFile_open,_print,_printf,_read,_say,_setpos,_stat,_sysread,_sysseek,_syswrite,_truncate,_write_,_ungetc'},
			{perl=>'new_tmpfile', type=>':H', python=>"_IOFile_tmpfile", 
		         calls=>'_open,_IOFile,_format,_autoflush,_binmode,_close,_eof,_fcntl,_fdopen,_format_write,_getc,_getpos,_ioctl,_input_line_number,_IOFile_open,_print,_printf,_read,_say,_setpos,_stat,_sysread,_sysseek,_syswrite,_truncate,_write_,_ungetc'},
		       ],
        'IO::File'=>   [{perl=>'new', type=>'SI:H', python=>'_IOFile', 
			 calls=>'_open,_format,_autoflush,_binmode,_close,_eof,_fcntl,_fdopen,_format_write,_getc,_getpos,_ioctl,_input_line_number,_IOFile_open,_print,_printf,_read,_say,_setpos,_stat,_sysread,_sysseek,_syswrite,_truncate,_write_,_ungetc'},
			{perl=>'new_from_fd', type=>'II:H', python=>"_IOFile_from_fd", 
		         calls=>'_open,_IOFile,_format,_autoflush,_binmode,_close,_eof,_fcntl,_fdopen,_format_write,_getc,_getpos,_ioctl,_input_line_number,_IOFile_open,_print,_printf,_read,_say,_setpos,_stat,_sysread,_sysseek,_syswrite,_truncate,_write_,_ungetc'},
			{perl=>'new_tmpfile', type=>':H', python=>"_IOFile_tmpfile", 
		         calls=>'_open,_IOFile,_format,_autoflush,_binmode,_close,_eof,_fcntl,_fdopen,_format_write,_getc,_getpos,_ioctl,_input_line_number,_IOFile_open,_print,_printf,_read,_say,_setpos,_stat,_sysread,_sysseek,_syswrite,_truncate,_write_,_ungetc'},
		       ],
        'IO::Handle'=> [],
	'POSIX'=>      [{perl=>'tmpnam', type=>':a', scalar=>'_tmpnam_s', scalar_type=>':S'},
			{perl=>'tmpfile', type=>':H'},
			{perl=>'ceil', type=>'F:I', python=>'math.ceil'},	# issue s3
			{perl=>'floor', type=>'F:I', python=>'math.floor'},	# issue s3
			{perl=>'trunc', type=>'F:I', python=>'math.trunc'},	# issue s3
			{perl=>'round', type=>'F:F', python=>'round'},		# issue s3
			{perl=>'strftime', type=>'a:S', calls=>'_timelocal'},	# issue s68
		       ],
        'File::Spec'=> [{perl=>'file_name_is_absolute', type=>'S:I', python=>'os.path.isabs'},
				   {perl=>'catfile', type=>'a:S', python=>'os.path.join'},
				   {perl=>'rel2abs', type=>'S:S', python=>'os.path.abspath'},
				   {perl=>'abs2rel', type=>'SS?:S', python=>'os.path.relpath'},
				   {perl=>'splitpath', type=>'SI?:a of S'},	# issue s51
				   {perl=>'splitdir', type=>'S:a of S'},	# issue s51
				   {perl=>'curdir', type=>':S'},	# issue s51
				   {perl=>'updir', type=>':S'},		# issue s51
				   {perl=>'tmpdir', type=>':S', python=>'tempfile.gettempdir'},	# issue 133 bootstrap
			   	  ],
        'File::Spec::Functions'=> [{perl=>'file_name_is_absolute', type=>'S:I', python=>'os.path.isabs'},
				   {perl=>'catfile', type=>'a:S', python=>'os.path.join'},
				   {perl=>'rel2abs', type=>'S:S', python=>'os.path.abspath'},
				   {perl=>'abs2rel', type=>'SS?:S', python=>'os.path.relpath'},
				   {perl=>'splitpath', type=>'SI?:a of S'},	# issue s51
				   {perl=>'splitdir', type=>'S:a of S'},	# issue s51
				   {perl=>'curdir', type=>':S'},	# issue s51
				   {perl=>'updir', type=>':S'},		# issue s51
				   {perl=>'tmpdir', type=>':S', python=>'tempfile.gettempdir'},	# issue 133 bootstrap
			   	  ],
	'Data::Dumper'=> [{perl=>'Dumper', type=>'m:S'}],
	'Text::Balanced'=> [{perl=>'extract_bracketed', type=>'SS?S?:a', scalar=>'_extract_bracketed_s', scalar_type=>'SS?S?:S', scalar_out_parameter=>1}],	# First parameter to scalar version is "out" parameter
	'Storable'=> [{perl=>'dclone', type=>'m:m', python=>'copy.deepcopy'}],
	'Cwd'=> [{perl=>'getcwd', type=>':S', python=>'os.getcwd'},
		 {perl=>'cwd', type=>':S', python=>'os.getcwd'},
		 {perl=>'fastcwd', type=>':S', python=>'os.getcwd'},
		 {perl=>'fastgetcwd', type=>':S', python=>'os.getcwd'},
		 {perl=>'abs_path', type=>'S?:S', python=>'_abspath'},
		 {perl=>'realpath', type=>'S?:S', python=>'_abspath'},
		 {perl=>'fast_abs_path', type=>'S?:S', python=>'_abspath'},
	        ],
	'File::Basename'=> [{perl=>'basename', type=>'S:S'},
			    {perl=>'dirname', type=>'S:S'},
			    {perl=>'fileparse', type=>'Sm?:a of S'},
		    ],
	'Carp'=>[{perl=>'carp', type=>'a:u'},
		 {perl=>'confess', type=>'a:u'},
		 {perl=>'croak', type=>'a:u'},
		 {perl=>'cluck', type=>'a:u'},
		 {perl=>'longmess', type=>'a:S'},
		 {perl=>'shortmess', type=>'a:S'},
	        ],
	       );


1;
