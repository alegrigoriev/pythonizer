package Perlscan;
## ABSTRACT:  Lexical analysis module for Perl -- parses one line of Perl program (which should contain a complete statement) into tokens/lexems
##          For alpha-testers only. Should be used with Pythoinizer testing suit
##
## Copyright Nikolai Bezroukov, 2019-2020.
## Licensed under Perl Artistic license
##
## REQURES
##        pythonizer.pl
##        Pythonizer.pm
##        Softpano.pm

#--- Development History
#
# Ver      Date        Who        Modification
# ====  ==========  ========  ==============================================================
# 0.10 2019/10/09  BEZROUN   Initial implementation
# 0.20 2019/11/13  BEZROUN   Tail comment is now treated as a special case and does not produce a lexem
# 0.30 2019/11/14  BEZROUN   Parsing of literals completly reorganized.
# 0.40 2019/11/14  BEZROUN   For now double quoted string are translatied into concatenation of components
# 0.50 2019/11/15  BEZROUN   Better parsing of Perl literals implemented
# 0.51 2019/11/19  BEZROUN   Problem of translation of ` ` (and rx() is that it is Python version dependent
# 0.52 2019/11/20  BEZROUN   Problem of translation of tr/abc/def/ solved
# 0.53 2019/12/20  BEZROUN   Here strings are now processed
# 0.60 2020/02/03  BEZROUN   Allow processing multiline statements
# 0.61 2020/02/03  BEZROUN   If the line does not ends with ; ){ or } we assume that the statement is continued on the next line
# 0.62 2020/05/16  BEZROUN   Nesting is performed from this module
# 0.63 2020/06/15  BEZROUN   Tail comments are artifically made properties of the last token in the line
# 0.64 2020/08/06  BEZROUN   gen_statement moved from pythonizer, ValCom became a local array
# 0.65 2020/08/08  BEZROUN   Diamond operator (<> <HANDLE>) is treated now as identifier
# 0.66 2020/08/09  BEZROUN   gen_chunk moved to Perlscan module. Pythoncode array made local
# 0.70 2020/08/10  BEZROUN   Postfix statements accomodated
# 0.71 2020/08/11  BEZROUN   scanning of regular expressions improved. / qr and 'm' are treated uniformly
# 0.72 2020/08/12  BEZROUN   Perl_default_var is renamed to default_var
# 0.73 2020/08/14  BEZROUN   Decoding of system variables in double quoted literals implemented
# 0.74 2020/08/18  BEZROUN   f-strings are generated for double quoted literals for Python 3.8
# 0.75 2020/08/25  BEZROUN   variable for other namespaces are recognized now
# 0.76 2020/08/27  BEZROUN   Special subroutine for putting regex in quote created
# 0.80 2020/08/31  BEZROUN   Handling of regex improved, keywords are added,
# 0.81 2020/08/31  BEZROUN   Handling of % improved.
# 0.82 2020/09/01  BEZROUN   my is eliminated, unless is the first token (for my $i...)
# 0.83 2020/09/02  BEZROUN   if regex contains both single and double quotes use """. Same for tranlation of double quoted
# 0.90 2020/09/17  BEZROUN   Adapted for detection of global identifiers.
# 0.91 2020/09/18  BEZROUN   ValType array added and now used in pass 0: values set to 'X' for special variables
# 0.92 2020/10/12  BEZROUN   Better special var handling. Many bug fixes
# 0.93 2021/11/21  SNOOPYJC  See specific changes in main module
#==start=============================================================================================
use v5.10.1;
use warnings;
#use strict 'subs';
use feature 'state';
use Softpano qw(abend logme out);
#use Pythonizer qw(correct_nest getline prolog epilog output_line);
use Pyconfig;				# issue 32
use Text::Balanced qw{extract_bracketed};       # issue 53
require Exporter;
use Data::Dumper;                       # issue 108
use Storable qw(dclone);                # SNOOPYJC
use Carp qw(cluck);                     # SNOOPYJC
use charnames qw/:full :short/;         # SNOOPYJC
use File::Basename;	                # SNOOPYJC
use File::Spec::Functions qw(file_name_is_absolute catfile);   # SNOOPYJC

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXPORT = qw(gen_statement tokenize gen_chunk append replace destroy insert destroy autoincrement_fix @ValClass  @ValPerl  @ValPy @ValCom @ValType $TokenStr escape_keywords %SPECIAL_FUNCTION_MAPPINGS save_code restore_code %token_precedence %SpecialVarsUsed @EndBlocks %SpecialVarR2L get_sub_vars_with_class %FileHandles add_package_to_mapped_name %FuncType %PyFuncType %UseRequireVars %UseRequireOptionsPassed %UseRequireOptionsDesired mapped_name);	# issue 41, issue 65, issue 74, issue 92, issue 93, issue 78, issue names
#our (@ValClass,  @ValPerl,  @ValPy, $TokenStr); # those are from main::

  $VERSION = '0.93';
  #
  # types of veriables detected during the first pass; to be implemented later
  #
  #%is_numeric=();

  %SpecialVarsUsed=();                  # SNOOPYJC: Keep track of special vars used so we can generate better code if you don't use some feature
  %NameMap=();                          # issue 92: Map names to python names
  @EndBlocks=();                        # SNOOPYJC: List of END blocks with their unique names
  %SpecialVarR2L=();                    # SNOOPYJC: Map from special var RHS to LHS
  %FileHandles = ();			# SNOOPYJC: Set of file handles used in this file
  @UseLib=();                           # SNOOPYJC: Paths added using "use lib"
  $fullpy = undef;                      # SNOOPYJC: Path to python file of package ref
  %UseRequireVars=();                   # issue names: map from fullpath to setref of perl varnames
  %UseRequireOptionsPassed=();          # issue names: map from fullpath to string of options that were sent to pythonizer
  %UseRequireOptionsDesired=();         # issue names: map from fullpath to string of options we want passed to pythonizer
#
# List of Perl special variables
#

   %SPECIAL_VAR=(';'=>'PERL_SUBSCRIPT_SEPARATOR','>'=>'os.geteuid()','<'=>'os.getuid()',
                '('=>"' '.join(map(str, os.getgrouplist(os.getuid(), os.getgid())))",     # SNOOPYJC
                ')'=>"' '.join(map(str, os.getgrouplist(os.geteuid(), os.getegid())))",   # SNOOPYJC
                '?'=>"$SUBPROCESS_RC",
		#SNOOPYJC '!'=>'unix_diag_message',
		'!'=>'OS_ERROR',		# SNOOPYJC
                # SNOOPYJC '$'=>'process_number',
		'$'=>'os.getpid()',             # SNOOPYJC
                ';'=>'subscript_separator,',
                # SNOOPYJC ']'=>'perl_version',
                ']'=>"$PERL_VERSION",           # SNOOPYJC
		#SNOOPYJC '&'=>'last_successful_match',
		'&'=>"$DEFAULT_MATCH.group(0)",	# SNOOPYJC, issue 32
                '@'=>'EVAL_ERROR',              # SNOOPYC
		'"'=>'LIST_SEPARATOR',		# issue 46
                '|'=>'OUTPUT_AUTOFLUSH',        # SNOOPYJC
		'`'=>"$DEFAULT_MATCH.string[:$DEFAULT_MATCH.start()]",  # SNOOPYJC
                "'"=>"$DEFAULT_MATCH.string[$DEFAULT_MATCH.end()]",     # SNOOPYJC
                '-'=>"$DEFAULT_MATCH.start",    # SNOOPYJC: Needs fixing at end to change [...] to (...)
                '+'=>"$DEFAULT_MATCH.end",      # SNOOPYJC: Needs fixing at end to change [...] to (...)
                '/'=>'INPUT_RECORD_SEPARATOR',','=>'OUTPUT_FIELD_SEPARATOR','\\'=>'OUTPUT_RECORD_SEPARATOR',
                '%'=>'FORMAT_PAGE_NUMBER', '='=>'FORMAT_LINES_PER_PAGE', '~'=>'FORMAT_NAME', '^'=>'FORMAT_TOP_NAME',    # SNOOPYJC
                ':'=>'FORMAT_LINE_BREAK_CHARACTERS',
                );
   %SPECIAL_VAR2=('O'=>'_os_name',     # SNOOPYJC: was os.name
                  'T'=>'OS_BASETIME', 'V'=>'sys.version[0]', 'X'=>'sys.executable', # $^O and friends
                  'L'=>'FORMAT_FORMFEED',                       # SNOOPYJC
                  'T'=>'BASETIME',                         # SNOOPYJC
                  'W'=>'WARNING');              # SNOOPYJC

   %SpecialVarType=('.'=>'I', '?'=>'S', '!'=>'I', '$'=>'I', ';'=>'S', ']'=>'F', 
                    '0'=>'S', '@'=>'S', '"'=>'S', '|'=>'I', '/'=>'S', ','=>'S',
                    '^O'=>'S', '^T'=>'S', '^V'=>'S', '^X'=>'S', '^W'=>'I',
                    '&'=>'S', '1'=>'S', '2'=>'S', '3'=>'S', '4'=>'S',
                    '5'=>'S', '6'=>'S', '7'=>'S', '8'=>'S', '9'=>'S',
                    '-'=>'I', '+'=>'I', '('=>'S', ')'=>'S', '>'=>'I', '<'=>'I',
                    '%'=>'I', '='=>'I', '~'=>'S', '^'=>'S', ':'=>'S',
                    '_'=>'s');
   %SpecialArrayType=('ARGV'=>'a of S', '_'=>'a of m', 'INC'=>'a of S');
   %SpecialHashType=('ENV'=>'h of m');          # Not 'h of S' as when we pull a non-existant key we get None!

   # NOTE: If you add to this, add the type of the scalar function to %SPECIAL_FUNCTION_TYPES below!!
   # Map of functions to python where the mapping is different for scalar and list context
   %SPECIAL_FUNCTION_MAPPINGS=('localtime'=>{scalar=>'tm_py.ctime', list=>'_localtime'},        # issue times
                'gmtime'=>{scalar=>'_cgtime', list=>'_gmtime'},                                 # issue times
                'splice'=>{scalar=>'_splice_s', list=>'_splice'},       # issue splice
                'reverse'=>{list=>'[::-1]', scalar=>'_reverse_scalar'}, # issue 65
		'grep'=>{list=>'filter', scalar=>'filter_s'},		# issue 37: Note: The "_s" gets removed when emitting the code
		'map'=>{list=>'map', scalar=>'map_s'},			# issue 37: Note: The "_s" gets removed when emitting the code
		'keys'=>{list=>'.keys()', scalar=>'.keys()_s'},		# issue s3: Note: The "_s" gets removed when emitting the code
		'values'=>{list=>'.values()', scalar=>'.values()_s'},	# issue s3: Note: The "_s" gets removed when emitting the code
                );

   %SPECIAL_FUNCTION_TYPES=('tm_py.ctime'=>'I?:S', '_cgtime'=>'I?:S', '_splice_s'=>'aI?I?a?:s',
                            '.keys()_s'=>'h:I', '.values()_s'=>'h:I',           # issue s3
                            '_reverse_scalar'=>'a:S', 'filter_s'=>'Sa:I', 'map_s'=>'fa:I');

   %keyword_tr=('eq'=>'==','ne'=>'!=','lt'=>'<','gt'=>'>','le'=>'<=','ge'=>'>=',
                'and'=>'and','or'=>'or','not'=>'not',
                'x'=>' * ',
                'abs'=>'abs',                           # SNOOPYJC
                'alarm'=>'signal.alarm',                # issue 81
		'assert'=>'assert',			# SNOOPYJC
		'atan2'=>'math.atan2',			# SNOOPYJC
		'basename'=>'_basename',		# SNOOPYJC
                'binmode'=>'_dup',                      # SNOOPYJC
                'bless'=>'_bless','BEGIN'=>'for _ in range(1):',        # SNOOPYJC, issue s12
                'UNITCHECK'=>'for _ in range(1):', 'CHECK'=>'for _ in range(1):', 'INIT'=>'for _ in range(1):',       # SNOOPYJC, issue s12
                # SNOOPYJC 'caller'=>q(['implementable_via_inspect',__file__,sys._getframe().f_lineno]),
		# issue 54 'chdir'=>'.os.chdir','chmod'=>'.os.chmod',
                'carp'=>'_carp', 'confess'=>'_confess', 'croak'=>'_croak', 'cluck'=>'_cluck',   # SNOOPYJC
                'longmess'=>'_longmess', 'shortmess'=>'_shortmess',                             # SNOOPYJC
		'chdir'=>'os.chdir','chmod'=>'_chmod',	# issue 54
		'chomp'=>'.rstrip("\n")','chop'=>'[0:-1]','chr'=>'chr',
		# issue close 'close'=>'.f.close',
		'close'=>'_close',	# issue close, issue 72
                'cmp'=>'_cmp',                          # SNOOPYJC
                'cos'=>'math.cos',                      # issue s3
                # issue 42 'die'=>'sys.exit', 
                'die'=>'raise Die',     # issue 42
                'dirname'=>'_dirname',          # SNOOPYJC
                'defined'=>'unknown', 'delete'=>'.pop(','defined'=>'perl_defined',
                'each'=>'_each',                        # SNOOPYJC
                'END'=>'_END_',                      # SNOOPYJC
                'exp'=>'math.exp',                      # issue s3
                'for'=>'for','foreach'=>'for',          # SNOOPYJC: remove space from each
                'else'=>'else: ','elsif'=>'elif ',
                # issue 42 'eval'=>'NoTrans!', 
                'eval'=>'try',  # issue 42
                'exit'=>'sys.exit','exists'=> 'in', # if  key in dictionary 'exists'=>'.has_key'
                'fc'=>'.casefold()',                    # SNOOPYJC
		'flock'=>'_flock',			# issue flock
                'fileno'=>'_fileno',                    # SNOOPYJC
                'fileparse'=>'_fileparse',              # SNOOPYJC
                'fork'=>'os.fork',                      # SNOOPYJC
		'glob'=>'glob.glob',			# SNOOPYJC
                'hex'=>'int',                           # SNOOPYJC
                'if'=>'if ', 'index'=>'.find',
		'int'=>'_int',				# issue int
		'GetOptions'=>'argparse',		# issue 48
		'gmtime'=>'_gmtime',    		# issue times
                'grep'=>'filter', 'goto'=>'goto', 'getcwd'=>'os.getcwd',
                'join'=>'.join(',
		# issue 33 'keys'=>'.keys',
                'keys'=>'.keys()',	# issue 33
                'kill'=>'_kill',      # SNOOPYJC
                'last'=>'break', 'local'=>'', 'lc'=>'.lower()', 
                'length'=>'lens',               # SNOOPYJC
		# issue localtime 'localtime'=>'.localtime',
		'localtime'=>'_localtime',		# issue times
                'log'=>'math.log',              # issue s3
                'lstat'=>'_lstat',              # SNOOPYJC
                'map'=>'map', 
                # issue mkdir 'mkdir'=>'os.mkdir', 
                'mkdir'=>'_mkdir',              # issue mkdir
                'my'=>'',
                'next'=>'continue', 
                # SNOOPYJC 'no'=>'NoTrans!',
                'no'=>'import',         # SNOOPYJC: for "no autovivification;";
                'own'=>'global', 
                # SNOOPYJC 'oct'=>'oct', 
                'oct'=>'int',           # SNOOPYJC: oct is the reverse in python!
                'ord'=>'ord',
                'our'=>'',                      # SNOOPYJC
                'pack'=>'_pack',                # SNOOPYJC
                'package'=>'package', 'pop'=>'.pop()', 'push'=>'.extend(',
                'pos'=>'pos',                   # SNOOPYJC
                'printf'=>'print',
                'quotemeta'=>'re.escape',       # SNOOPYJC
                'rename'=>'os.replace',         # SNOOPYJC
                'say'=>'print','scalar'=>'len', 'shift'=>'.pop(0)', 
                'sin'=>'math.sin',              # issue s3
                'splice'=>'_splice',            # issue splice
                # SNOOPYJC 'split'=>'re.split', 
                'split'=>'_split',      # SNOOPYJC perl split has different semantics on empty matches at the end
                'seek'=>'_seek',                # SNOOPYJC
		# issue 34 'sort'=>'sort', 
                'sleep'=>'tm_py.sleep',         # SNOOPYJC
		'sqrt'=>'math.sqrt',		# SNOOPYJC
		'sort'=>'sorted', 		# issue 34
		'state'=>'global',
                'rand'=>'_rand',                # SNOOPYJC
                'read'=>'.read',                # issue 10
                   'stat'=>'_stat','sysread'=>'.sysread',
                   'substr'=>'_substr','sub'=>'def','STDERR'=>'sys.stderr','STDIN'=>'sys.stdin',        # issue bootstrap
                   # SNOOPYJC 'system'=>'os.system',
                   'system'=>'_system',         # SNOOPYJC
                   'sprintf'=>'_sprintf',
		   'STDOUT'=>'sys.stdout',	# issue 10
                   'sysseek'=>'perl_sysseek',
                   'STDERR'=>'sys.stderr','STDIN'=>'sys.stdin', '__LINE__' =>'sys._getframe().f_lineno',
                   '__FILE__'=>'__file__',      # SNOOPYJC
                   '__SUB__'=>'_sub',           # SNOOPYJC
                'reverse'=>'[::-1]',            # issue 65
                'rindex'=>'.rfind', 
                # SNOOPYJC 'ref'=>'type', 
                'ref'=>'_ref',                  # SNOOPYJC
                # SNOOPYJC 'require'=>'NoTrans!', 
	        'opendir'=>'_opendir', 'closedir'=>'_closedir', 'readdir'=>'_readdir', 'seekdir'=>'_seekdir', 'telldir'=>'_telldir', 'rewinddir'=>'_rewinddir',	# SNOOPYJC
                'redo'=>'continue',             # SNOOPYJC
                'require'=>'__import__',        # SNOOPYJC
                'return'=>'return', 'rmdir'=>'os.rmdir',
                'tell'=>'_tell',                # SNOOPYJC
                'tie'=>'NoTrans!',
		'time'=>'_time',		# SNOOPYJC
		'timelocal'=>'_timelocal',	# issue times
                'timegm'=>'_timegm',            # issue times
                'truncate'=>'_truncate',        # SNOOPYJC
                'uc'=>'.upper()', 'ucfirst'=>'.capitalize()', 'undef'=>'None', 'unless'=>'if not ', 'unlink'=>'os.unlink',
                'umask'=>'os.umask',            # SNOOPYJC
                   'unshift'=>'.insert(0,',
                   # SNOOPYJC 'use'=>'NoTrans!', 
                   'use'=>'import',
                'unpack'=>'_unpack',    # SNOOPYJC
                   'until'=>'while not ','untie'=>'NoTrans!',
                'values'=>'.values()',	# SNOOPYJC
                 'warn'=>'print',
                 'wait'=>'_wait',       # SNOOPYJC
                 'waitpid'=>'_waitpid',         # SNOOPYJC
                 # issue s3 'wantarray'=>'True',           # SNOOPYJC
               );

       #
       # TOKENS TYPES:
       # a => Array like @arr
       # b
       # c => Control like if, for, foreach, while, unless, until, ...
       # d => Digits like 123 or 12.34 or .5
       # e
       # f => Built-in function like abs, atan2, basename, or chomp
       # g => Glob like <*.c>
       # h => Hashname like %hash
       # i => BareWord like ABC or abc - could be a local sub name
       # j => Diamond like <> or <$fh> or <FH>
       # k => Special control like last, next, return, or sub
       # l, m, 
       # n => not
       # o => or, and, xor - lower precedence than || &&
       # p
       # q => Pattern like  m/.../, s/../.../, tr/../../, or wr, or /.../
       # r => range (..)
       # s => Scalar like $var
       # t => Variable type like local, my, own, state
       # u, v, w
       # x => Executable in `...` or qx
       # y => Extra python code we need to generate as is (used in multi_subscripts)
       # z
       # A => => (arrow)
       # C => More control like default, else, elsif
       # D => -> (dot in python)
       # F => Named Unary Operators (not generated, but used in calls to next_lower_or_equal_precedent_token)
       # G => TypeGlob *name
       # H => Here doc <<
       # I => >>
       # P => :: (package reference)
       # W => Context manager (with)
       # 0 => &&, ||
       # ^ => ++ or --
       # > => comparison like > < >= <= == eq ne lt gt le ge
       # = => assignment like = += -= etc
       # ? => ? (part of ? : )
       # : => : or =>
       # . => . or -> or ::
       # * => *, **, or x
       # ! => !
       # +, -, /, % => Operators
       # ~ => Pattern match like =~ or !~
       # " => Quoted string or q/abc/, qq(def), etc
       
       %token_precedence=(
			# Prec    Assoc       Token       Desc
                        c=>26, C=>26, k=>26, W=>26,
			# 25      left        ashi        terms and list operators (leftward)
                        a=>25, s=>25, h=>25, i=>25, '('=>25, ')'=>25, '"'=>25, q=>25, x=>25, f=>25, G=>25,
			# 24      left        D           ->
                        D=>24,
			# 23      nonassoc    ^           ++ --
                        '^'=>23,
			# 22      right       *           **
                        #'*'=>22,
			# 21      right       !~\+-       ! ~ ~. \ and unary + and -
                        '!'=>21, '\\'=>21,
			# 20      left        ~           =~ !~
                        '~'=>20,
			# 19      left        */%         * / % x
                        '*'=>19, '/'=>19, '%'=>19,
			# 18      left        +-.         + - .
                        '+'=>18, '-'=>18, '.'=>18,
			# 17      left        HI          << >>
                        H=>17, I=>17,
			# 16      nonassoc    f           named unary operators
                        F=>16,      # Not real in the code, but used in a call to next_lower_or_equal_precedent_token
			# 15      nonassoc    N/A         isa
			# 14      chained     >           < > <= >= lt gt le ge
                        '>'=>14,
			# 13      chain/na    >           == != eq ne <=> cmp ~~
			# 12      left        &           & &.
                        '&'=>12,
			# 11      left        |           | |. ^ ^.
                        '|'=>11,
			# 10      left        0           &&
                        '0'=>10,
			# 9       left        0           || //
			# 8       nonassoc    r           ..  ...
                        'r'=>8,
			# 7       right       ?:          ?:
                        '?'=>7, ':'=>7,
			# 6       right       =           = += -= *= etc. goto last next redo dump
                        '='=>6,
			# 5       left        ,A          , =>
                        ','=>5, A=>5,
			# 4       nonassoc    f           list operators (rightward)
			# 3       right       n           not
                        n=>3,
			# 2       left        o           and
			# 1       left        o           or xor
                        o=>1);

       %TokenType=('eq'=>'>','ne'=>'>','lt'=>'>','gt'=>'>','le'=>'>','ge'=>'>',
                  'x'=>'*',
                  'y'=>'q', 'q'=>'q','qq'=>'q','qr'=>'q',
		  # issue 44 'wq'=>'q',
		  'qw'=>'q',		# issue 44
		  'wr'=>'q','qx'=>'q','m'=>'q','s'=>'q','tr'=>'q',
                  # issue 93 'and'=>'0',
                  'and'=>'o',           # issue 93
		  'abs'=>'f',	        # SNOOPYJC
                  'alarm'=>'f',         # issue 81
		  'assert'=>'c',	# SNOOPYJC
		  'atan2'=>'f',		# SNOOPYJC
		  'autoflush'=>'f',	# SNOOPYJC
		  'basename'=>'f',	# SNOOPYJC
		  'binmode'=>'f',	# SNOOPYJC
                  'bless'=>'f',         # SNOOPYJC
                  'caller'=>'f','chdir'=>'f','chomp'=>'f', 'chop'=>'f', 'chmod'=>'f','chr'=>'f','close'=>'f',
                  'continue'=>'C',      # SNOOPYJC
                  'cos'=>'f',           # issue s3
                  'carp'=>'f', 'confess'=>'f', 'croak'=>'f', 'cluck'=>'f',   # SNOOPYJC
                  'longmess'=>'f', 'shortmess'=>'f',                         # SNOOPYJC
                  'cmp'=>'>',           # SNOOPYJC: comparison
                  'delete'=>'f',        # issue delete
                  'default'=>'C','defined'=>'f','die'=>'f',
                  'dirname'=>'f',     # SNOOPYJC
                  'do'=>'C',            # SNOOPYJC
                  'each'=>'f',          # SNOOPYJC
                  'else'=>'C', 'elsif'=>'C', 'exists'=>'f', 'exit'=>'f', 'export'=>'f',
                  'exp'=>'f',           # issue s3
                  'eval'=>'C',          # issue 42
                  'fc'=>'f',            # SNOOPYJC
                  'fileno'=>'f',        # SNOOPYJC
                  'fileparse'=>'f',     # SNOOPYJC
		  'flock'=>'f',		# issue flock
		  'fork'=>'f',		# SNOOPYJC
		  'glob'=>'f',		# SNOOPYJC
                  'if'=>'c',  'index'=>'f',
		  'int'=>'f',		# issue int
                  'for'=>'c', 'foreach'=>'c',
		  'GetOptions'=>'f',	# issue 48
                  'goto'=>'k',          # SNOOPYJC
                  'given'=>'c','grep'=>'f',
                  'hex'=>'f',           # SNOOPYJC
                  'join'=>'f',
                  'keys'=>'f',
                  'kill'=>'f',          # SNOOPYJC
                  'last'=>'k', 'lc'=>'f', 'length'=>'f', 'local'=>'t', 'localtime'=>'f',
                  'log'=>'f',           # issue s3
                  'lstat'=>'f',
                  'my'=>'t', 'map'=>'f', 'mkdir'=>'f',
                  'next'=>'k','not'=>'!',
                  'no'=>'k',                    # SNOOPYJC
                  'our'=>'t',                   # SNOOPYJC
                  # issue 93 'or'=>'0', 
                  'or'=>'o',                    # issue 93
                  'own'=>'t', 'oct'=>'f', 'ord'=>'f', 'open'=>'f',
		  'opendir'=>'f', 'closedir'=>'f', 'readdir'=>'f', 'seekdir'=>'f', 'telldir'=>'f', 'rewinddir'=>'f',	# SNOOPYJC
                  'push'=>'f', 'pop'=>'f', 'print'=>'f', 'package'=>'c',
                  'pack'=>'f',
                  'pos'=>'f',                   # SNOOPYJC
                  'printf'=>'f',                # SNOOPYJC
                  'quotemeta'=>'f',             # SNOOPYJC
                  'rand'=>'f',                  # SNOOPYJC
                  'redo'=>'k',                  # SNOOPYJC
                  'require'=>'k',               # SNOOPYJC
                  'rindex'=>'f','read'=>'f', 
                  'rename'=>'f',                # SNOOPYJC
		  # issue 61 'return'=>'f', 
		  'return'=>'k', 		# issue 61
                  'reverse'=>'f',               # issue 65
		  'ref'=>'f',
                  'rmdir'=>'f',         # SNOOPYJC
                  'say'=>'f','scalar'=>'f','shift'=>'f', 
                  'select'=>'f',        # SNOOPYJC
                  'sin'=>'f',           # issue s3
                  'splice'=>'f',                # issue splice
                  'split'=>'f', 'sprintf'=>'f', 'sort'=>'f','system'=>'f', 'state'=>'t',
                  'seek'=>'f',          # SNOOPYJC
		  'sleep'=>'f',		# SNOOPYJC
		  'sqrt'=>'f',		# SNOOPYJC
                  'stat'=>'f','sub'=>'k','substr'=>'f','sysread'=>'f',  'sysseek'=>'f',
                  'tell'=>'f',          # SNOOPYJC
                  'tie'=>'f',
		  'time'=>'f', 'gmtime'=>'f', 'timelocal'=>'f',	'timegm'=> 'f', # SNOOPYJC
                  'truncate'=>'f',              # SNOOPYJC
		  'unlink'=>'f',		# SNOOPYJC
                  'unpack'=>'f',                # SNOOPYJC
                  'use'=>'k',                   # SNOOPYJC
                  'values'=>'f',
                  'warn'=>'f', 'when'=>'C', 'while'=>'c',
                  'undef'=>'f', 'unless'=>'c', 'unshift'=>'f','until'=>'c','uc'=>'f', 'ucfirst'=>'f',
                  # SNOOPYJC 'use'=>'c',
                  'untie'=>'f',
                  'umask'=>'f',                  # SNOOPYJC
                  'wait'=>'f',                   # SNOOPYJC
                  'waitpid'=>'f',                # SNOOPYJC
                  'wantarray'=>'d',              # SNOOPYJC
                  '__FILE__'=>'"', '__LINE__'=>'d', '__PACKAGE__'=>'"', '__SUB__'=>'f', # SNOOPYJC
                  );
                      # NB: Use ValPerl[$i] as the key here!
       %FuncType=(    # a=Array, h=Hash, s=Scalar, I=Integer, F=Float, N=Numeric, S=String, u=undef, f=function, H=FileHandle, ?=Optional, m=mixed
                  '_num'=>'m:N', '_int'=>'m:I', '_str'=>'m:S',
                  '_flt'=>'m:F',                                        # issue s3
                  '_map_int'=>'a:a of I', '_map_num'=>'a:a of N', '_map_str'=>'a:a of S',
                  '_assign_global'=>'SSm:m', '_read'=>'HsII?:s',
                  'exp'=>'F:F', 'log'=>'F:F', 'cos'=>'F:F', 'sin'=>'F:F',       # issue s3
                  '$#'=>'a:I',                                                # issue 119: _last_ndx
                  're'=>'S', 'tr'=>'S',                                         # SNOOPYJC
		  'abs'=>'N:N', 'alarm'=>'N:N', 'atan2'=>'NN:F', 
                  'autoflush'=>'I?:I', 'basename'=>'S:S', 'binmode'=>'HS?:m',
                  'bless'=>'mS?:m',                      # SNOOPYJC
                  'caller'=>'I?:a',
                  'carp'=>'a:u', 'confess'=>'a:u', 'croak'=>'a:u', 'cluck'=>'a:u',   # SNOOPYJC
                  'longmess'=>'a:S', 'shortmess'=>'a:S',                             # SNOOPYJC
                  'chdir'=>'S:I','chomp'=>'S:m', 'chop'=>'S:m', 'chmod'=>'Ia:I','chr'=>'I?:S','close'=>'H:I',
                  'cmp'=>'SS:I', '<=>'=>'NN:I',
                  'delete'=>'u:a', 'defined'=>'u:I','die'=>'S:m', 'dirname'=>'S:S', 'each'=>'h:a', 'exists'=>'u:I', 
                  'exit'=>'I?:u', 'fc'=>'S:S', 'flock'=>'HI:I', 'fork'=>':m', 'fileno'=>'H:I',
                  'fileparse'=>'Sm?:a of S', 'hex'=>'S:I', 'GetOptions'=>'a:I',
                  'glob'=>'S:a of S', 'index'=>'SSI?:I', 'int'=>'s:I', 'grep'=>'Sa:a of S', 'join'=>'Sa:S', 'keys'=>'h:a of S', 
                  'kill'=>'mI:u', 'lc'=>'S:S', 'lstat'=>'S:a of I',
                  'length'=>'S:I', 'localtime'=>'I?:a of I', 'map'=>'fa:a', 'mkdir'=>'SI?:I', 'oct'=>'S:I', 'ord'=>'S:I', 'open'=>'HSS?:I',
                  'pack'=>'Sa:S',
		  'opendir'=>'HS:I', 'closedir'=>'H:I', 'readdir'=>'H:S', 'rename'=>'SS:I', 'rmdir'=>'S:I',
                  'seekdir'=>'HI:I', 'telldir'=>'H:I', 'rewinddir'=>'H:m',
                  'push'=>'aa:I', 'pop'=>'a:s', 'pos'=>'s:I', 'print'=>'H?a:I', 'printf'=>'H?Sa:I', 'quotemeta'=>'S:S', 'rand'=>'F?:F',
                  'rindex'=>'SSI?:I','read'=>'HsII?:I', '.read'=>'HsII?:I', 'reverse'=>'a:a', 'ref'=>'u:S', 
                  '_refs'=>'u:S',               # issue s3
                  'say'=>'H?a:I','scalar'=>'a:I','seek'=>'HII:u', 'shift'=>'a?:s', 'sleep'=>'I:I', 'splice'=>'aI?I?a?:a',
                  'select'=>'H?:H',             # SNOOPYJC
                  'split'=>'SSI?:a of m', 'sprintf'=>'Sa:S', 'sort'=>'fa:a','system'=>'a:I',
                  'sqrt'=>'N:F', 'stat'=>'S:a of I', 'substr'=>'SII?S?:S','sysread'=>'HsII?:I',  'sysseek'=>'HII:I', 'tell'=>'H:I', 'time'=>':I', 'gmtime'=>'I?:a of I', 'timegm'=>'IIIIII:I',
                  'truncate'=>'HI:I',
                  'timelocal'=>'IIIIII:I', 'unlink'=>'a?:I', 'values'=>'h:a', 'warn'=>'a:I', 'undef'=>'a?:u', 'unshift'=>'aa:I', 'uc'=>'S:S',
                  'unpack'=>'SS:a', 'ucfirst'=>'S:S', 'umask'=>'I?:I', 'wait'=>':I', 'waitpid'=>'II:I', '__SUB__'=>':f',
                  );
        for my $func (values %ARRAY_INDEX_FUNCS) {
            $FuncType{$func} = 'asN:N';
            if($func =~ /concat/) {
                $FuncType{$func} = 'asS:S';
            } elsif($func =~ /set/) {
                $FuncType{$func} = 'ass:s';
            } elsif($func =~ /translate/) {
                $FuncType{$func} = 'ass:S';
            } elsif($func =~ /substitute/) {
                $FuncType{$func} = 'asss:S';
            }
        }

	%PyFuncType=();						# SNOOPYJC
	for my $func (keys %FuncType) {
            my $py = $func;
            if(exists $keyword_tr{$func}) {
                $py = $keyword_tr{$func};
            }
            $PyFuncType{$py} = $FuncType{$func};
        }

        %PyFuncType = (%PyFuncType, %SPECIAL_FUNCTION_TYPES);   # SNOOPYJC: Add in the special scalar ones
        # Handle a couple of special cases that are not words
        $PyFuncType{_last_ndx} = $FuncType{'$#'};
        $PyFuncType{_spaceship} = $FuncType{'<=>'};
        $PyFuncType{_read} = $FuncType{read};
        $PyFuncType{_sysread} = $FuncType{sysread};
        $PyFuncType{_IOFile_open} = $FuncType{open};
        $PyFuncType{_binmode} = $FuncType{binmode};
        $PyFuncType{_assign_global} = 'SSm:m';
        $PyFuncType{_substitute_global} = 'SSSS:s';
        $PyFuncType{_translate_global} = 'SSm:s';
        $PyFuncType{'signal.signal'} = 'If:f';
        $PyFuncType{'signal.getsignal'} = 'I:f';
        $PyFuncType{'pdb.set_trace'} = ':I';

        for my $d (keys %DASH_X) {
            $FuncType{"-$d"} = 'm:I';
            $PyFuncType{$DASH_X{$d}} = 'm:I';
        }

        for my $pkg (keys %PREDEFINED_PACKAGES) {       # See Pyconfig.pm
            $BUILTIN_LIBRARY_SET{$pkg} = 1;
            for my $func_info (@{$PREDEFINED_PACKAGES{$pkg}}) {
                my $perl = $func_info->{perl};
                my $type = $func_info->{type};
                my $python = "_$perl";
                $python = $func_info->{python} if(exists $func_info->{python});
                if(exists $func_info->{calls}) {
                    $PYF_CALLS{$python} = $func_info->{calls};
                }
                my $fullname = "${pkg}::$perl";
                if(exists $func_info->{scalar}) {
                    my $scalar = $func_info->{scalar};
                    $SPECIAL_FUNCTION_MAPPINGS{$perl} = {scalar=>$scalar, list=>$python};
                    $SPECIAL_FUNCTION_MAPPINGS{$fullname} = {scalar=>$scalar, list=>$python};
                    if(exists $func_info->{scalar_calls}) {
                        $PYF_CALLS{$scalar} = $func_info->{scalar_calls};
                    }
                    $PyFuncType{$scalar} = $func_info->{scalar_type};
                    if(exists $func_info->{scalar_out_parameter}) {
                        $PYF_OUT_PARAMETERS{$scalar} = $func_info->{scalar_out_parameter};
                    }
                }
                if($perl ne 'new') {
                    $FuncType{$perl} = $type;
                    $TokenType{$perl} = 'f';
                    $keyword_tr{$perl} = $python;
                }
                $PyFuncType{$python} = $type;
                $TokenType{$fullname} = 'f';
                $FuncType{$fullname} = $type;
                $keyword_tr{$fullname} = $python;
            }
        }
#
# one to one translation of digramms. most are directly translatatble.
#
   %digram_tokens=('++'=>'^', '--'=>'^', '+='=>'=', '-='=>'=', '.='=>'=', '%='=>'=', 
                   '|='=>'=', '&='=>'=',                        # SNOOPYJC
                   '^='=>'=',                                   # SNOOPYJC
                   '=~'=>'~','!~'=>'~',
                   '=='=>'>', '!='=>'>', '>='=>'>', '<='=>'>', # comparison
                   '=>'=>'A', '->'=>'D',                        # issue 93
                   '<<' => 'H', '>>'=>'I', '&&'=>'0', '||'=>'0', # issue 93
                   '*='=>'=', '/='=>'=', '**'=>'*', '::'=>'P' ); # issue 93

   %digram_map=('++'=>'+=1','--'=>'-=1','+='=>'+=', '*='=>'*=', '/='=>'/=', '.='=>'+=', '=~'=>'','<>'=>'readline()','=>'=>': ','->'=>'.',
                '&&'=>' and ', '||'=>' or ',
                # SNOOPYJC '::'=>'.',
                '::'=>'.__dict__',               # SNOOPYJC
               );

#  %SpaceBefore=(in=>1, is=>1, an=>1, or=>1);                  # SNOOPYJC - always generate a space before these 2-letter output words

   %SpaceBoth=('='=>1, '+='=>1, '-='=>1, '*='=>1, '/='=>1, '%='=>1,
               '>'=>1, '>='=>1, '<'=>1, '<='=>1, '=='=>1, '!='=>1,
               '||='=>1, '&&='=>1,                                      # issue s3
               '|='=>1, '&='=>1, '^='=>1, '>>='=>1, '<<='=>1, '**='=>1, '//='=>1); # SNOOPYJC - always generate a space before and after these

# issue 39 my ($source,$cut,$tno)=('',0,0);
my $source='';                  # issue 39, issue 108
$cut=0;                         # issue 39
$tno=0;                         # issue 108
@PythonCode=(); # array for generated code chunks
$PREV_HAD_COLON=1;               # SNOOPYJC
@SavePythonCode=();     # issue 74
@BufferValClass=@BufferValCom=@BufferValPerl=@BufferValPy=();
@BufferValType=();		# issue 37
$TokenStr='';
$delayed_block_closure=0;
$nesting_level=0;               # issue 94
@nesting_stack=();              # issue 94
$nesting_last=undef;            # issue 94: Last thing we popped off the stack
$last_block_lno=0;              # issue 94
$last_label=undef;              # issue 94
%all_labels=(''=>1);            # issue 94: all labels seen in this file
$uses_function_return_exception = 0;    # SNOOPYJC
%sub_external_last_nexts=();    # issue 94: Map of subnames to set of all last/next labels that propagate out ('' if no label)
sub TRY_BLOCK_EXCEPTION    { 1 }
sub TRY_BLOCK_FINALLY      { 2 }
sub TRY_BLOCK_HAS_CONTINUE { 4 }      # Has a 'continue' block
sub TRY_BLOCK_HAS_NEXT     { 8 }         # Has a 'last' stmt for this loop
sub TRY_BLOCK_HAS_LAST    { 16 }         # Has a 'next' stmt for this loop
sub TRY_BLOCK_REDO_LOOP   { 32 }         # Needs a nested loop for 'redo'
$statement_starting_lno = 0;            # issue 116
%line_contains_stmt_modifier=();        # issue 116
%line_contains_for_loop_with_modified_counter=();       # SNOOPYJC
%line_contains_pos_gen=();      # SNOOPYJC: {lno=>scalar, ...} on any stmt that can generate the pos of this scalar
%scalar_pos_gen_line=();        # SNOOPYJC: {scalar=>last_lno, ...} - opposite of prev hash
%line_needs_try_block=();       # issue 94, issue 108: Map from line number to TRY_BLOCK_EXCEPTION|TRY_BLOCK_FINALLY if that line needs a try block
%line_locals=();                # issue 108: Map from line number to a list of locals
%line_locals_map=();            # issue 108: Map from line number to a map from perl name to python name
%line_sub=();                   # issue 108: Map from line number to sub name
%line_substitutions=();         # SNOOPYJC: Map from line number to a hash ref of pattern substitutions needed
%line_varclasses=();            # SNOOPYJC: Map from line number to var classes (e.g. 'my', 'our', etc)
%sub_varclasses=();             # SNOOPYJC: Map from sub to var classses
$last_varclass_lno = 0;         # SNOOPYJC: Last entry in the above
%last_varclass_sub=();             # SNOOPYJC: What sub were we in when we set the last %line_varclasses for this name
$ate_dollar = -1;               # issue 50: if we ate a '$', where was it?
sub initialize                  # issue 94
{
    $nesting_level = 0;
    @nesting_stack = ();
    $last_label = undef;
    $last_block_lno=0;
    $ate_dollar = -1;
    $nesting_last=undef;            # issue 94: Last thing we popped off the stack
    if($Pythonizer::PassNo==&Pythonizer::PASS_1) {
        push @UseLib, dirname($Pythonizer::fname);   # SNOOPYJC: Always good to look here!
    }
}


sub add_package_name
# Add the package name to this var if it's a global and it doesn't already have a package name
# Arg = the real perl name of this var, e.g. $xxx{} => %xxx
{
    my $name = shift;
    my $py = $ValPy[$tno];

    #say STDERR "add_package_name($name), py=$py, lno=$.";
    return if($::implicit_global_my);
    return if(index($py, '.') >= 0);
    return unless(exists $line_varclasses{$.});
    if(substr($name,0,2) eq '$#') {
        $name = '@' . substr($name,2);
    }
    return unless(exists $line_varclasses{$.}{$name});
    my $class;
    return unless(($class = $line_varclasses{$.}{$name}) =~ /global|local/);
    my $sigil = substr($name,0,1);
    $sigil = '' if($sigil =~ /\w/);
    if($ValPy[$tno] =~ /^\(len\((.*)\)-1\)$/) {		# for $#arr
        my $id = $1;
        $id = remap_conflicting_names($id, $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        $ValPy[$tno] = '(len(' . cur_package() . '.' . $id . ')-1)';
    }elsif($ValPy[$tno] =~ /^len\((.*)\)$/) {		# issue bootstrap: for scalar(@arr)
        my $id = $1;
        $id = remap_conflicting_names($id, $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        $ValPy[$tno] = 'len(' . cur_package() . '.' . $id . ')';
    }elsif(substr($ValPy[$tno],0,1) eq '*') {           # issue bootstrap: we splatted this reference
        my $id = substr($ValPy[$tno],1);
        $id = remap_conflicting_names($id, $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        $ValPy[$tno] = '*' . cur_package() . '.' . $id;     # Add the package name, moving the splat to the front
    } else {
        my $id = $ValPy[$tno];
        $id = remap_conflicting_names($id, $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        $ValPy[$tno] = cur_package() . '.' . $id;         # Add the package name
    }
    say STDERR "Changed $py to $ValPy[$tno] for global" if($::debug >= 5);
}

sub add_package_name_sub
# Add a package name to a sub call
# Arg: position of the 'i' token for the sub
# Returns: Updates $ValPy[$pos] if a change is needed
{
    my $tno = shift;

    my $perl_name = $ValPerl[$tno];
    my $py = $ValPy[$tno];
    return if($::implicit_global_my);
    return if(index($py, '.') >= 0);
    return if(substr($perl_name,0,1) eq '$');          # issue 117: Is a sub-ref, not a regular sub
    return if($tno != 0 && $ValPy[$tno-1] eq '.');
    # Here we check if it's actually defined locally (LocalSub == 1) or if
    # it's imported by name (LocalSub == 2).  It could also have the "8" value bit turned on,
    # which only means it was referenced with a '&':
    return if(exists $Pythonizer::LocalSub{$py} && ($Pythonizer::LocalSub{$py} & 3));
    $ValPy[$tno] = cur_package() . '.' . $ValPy[$tno];         # Add the package name
    $Pythonizer::LocalSub{$ValPy[$tno]} = $Pythonizer::LocalSub{$py} if exists $Pythonizer::LocalSub{$py};                        # issue s3
    $Pythonizer::SubAttributes{$ValPy[$tno]} = $Pythonizer::SubAttributes{$py} if exists $Pythonizer::SubAttributes{$py};         # issue s3
    say STDERR "Changed $py to $ValPy[$tno] for non-local sub" if($::debug >= 5);
}

sub add_package_name_fh
# Add a package name to a file handle
# Arg: position of the 'i' token for the sub
# Returns: Updates $ValPy[$pos] if a change is needed
{
    my $tno = shift;

    my $perl_name = $ValPerl[$tno];
    my $py = $ValPy[$tno];
    return if($::implicit_global_my);
    return if(index($py, '.') >= 0);
    my $name = '*' . $perl_name;		# TypeGlob, e.g. local *FH;
    if($Pythonizer::PassNo==&Pythonizer::PASS_1 && $last_varclass_lno != $. && $last_varclass_lno) {
	# We don't capture filehandles, so we need to propagate the last line down on the first pass
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
        $last_varclass_lno = $.;
    }
    my $class;
    return if(exists $line_varclasses{$.} && exists $line_varclasses{$.}{$name} &&
	      $line_varclasses{$.}{$name} !~ /global|local/);
    return if($tno != 0 && $ValPy[$tno-1] eq '.');
    $ValPy[$tno] = cur_package() . '.' . $ValPy[$tno];         # Add the package name
    say STDERR "Changed $py to $ValPy[$tno] for file handle" if($::debug >= 5);
}

sub add_package_name_j
# For <$fh>, add the package name if need be.  This is a little harder than the
# normal case, because $ValPy[$tno] could be either like fh.readlines() -or- 
# _readline(fh) -or- _readline_full(fh) and we need to find the filehandle and
# potentially replace it.
{
    my $name = substr($ValPerl[$tno],1,length($ValPerl[$tno])-2);    # <$fh> -> $fh
    my $tg = 0;
    my $sigil = '$';
    if(index($ValPerl[$tno], '$') < 0) {
        return if(!$name);      # <>
        $name = '*' . $name;	# TypeGlob
	$tg = 1;
        $sigil = '';
    }
    return if($::implicit_global_my);
    my $class = '';
    if($tg) {
        return if(exists $line_varclasses{$.} && exists $line_varclasses{$.}{$name} &&
	          $line_varclasses{$.}{$name} !~ /global|local/);
    } else {
    	return unless(exists $line_varclasses{$.});
    	return unless(exists $line_varclasses{$.}{$name});
    	return unless(($class = $line_varclasses{$.}{$name}) =~ /global|local/);
    }

    my $py = $ValPy[$tno];
    my $var = substr($name,1);          # fh
    if($py =~ /\b($var(?:_|_v)?)\b/) {
        my $start = $-[1];
        my $end = $+[1];
        my $len = $end - $start;
        return if(substr($py,$start-1,1) eq '.');
        my $id = substr($ValPy[$tno],$start,$len);
        $id = remap_conflicting_names($id, $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        substr($ValPy[$tno], $start, $len) = cur_package() . '.' . $id;
        say STDERR "Changed $py to $ValPy[$tno] for global" if($::debug >= 5);
    }
}

sub get_perl_name               # SNOOPYJC
# Get the real perl name of the current var, e.g. map $xxx{...} to %xxx and $xxx[...] to @xxx
# Note that $$xxx{...} stays mapped to $xxx as it's a hashref
{
    my $name = shift;   # Perl name referenced
    my $next = shift;   # Next char after perl name
    my $prev = shift;   # Prev char before perl name

    if($prev eq '$' || $name eq '$') {
        say STDERR "get_perl_name($name, $next, $prev) = $name" if($::debug >= 5);
        return $name;
    }
    my $oname = $name;
    if($next eq '[') {
        $name = '@' . substr($name,1);
    } elsif($next eq '{') {
        $name = '%' . substr($name,1);
    } elsif(substr($name,0,2) eq '$#') {
        $name = '@' . substr($name,2);
    }
    say STDERR "get_perl_name($oname, $next, $prev) = $name" if($::debug >= 5);
    return $name;
}

sub cur_package
{
    my $result;
    if($Pythonizer::PassNo == &Pythonizer::PASS_2) {
        $result = $::CurPackage;
    } elsif(!@Pythonizer::Packages) {
        $result = $DEFAULT_PACKAGE;
    } else {
        $result = $Pythonizer::Packages[-1];
    }
    $Pythonizer::Packages{$result} = 1;
    return escape_keywords($result, 1);
}

sub capture_varclass_j          # SNOOPYJC: Only called in the first pass
# We just lexed a <$fh>, Keep track of what class this is
{
    my $name = substr($ValPerl[$tno],1,length($ValPerl[$tno])-2);    # <$fh> -> $fh
    my $class = 'global';
    if($last_varclass_lno != $. && $last_varclass_lno) {
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
    }
    return if(index($ValPerl[$tno], '$') < 0);
    $last_varclass_lno = $.;
    if(exists $line_varclasses{$last_varclass_lno}{$name}) {
        $class = $line_varclasses{$last_varclass_lno}{$name};
    }
    add_package_name_j() if($class eq 'global');
}

sub capture_varclass                    # SNOOPYJC: Only called in the first pass
# We just lexed a scalar, array, hash, or TypeGlob.  Keep track of what class ('my', 'our', etc) this is
{
    my $name = get_perl_name($ValPerl[$tno], substr($source,$cut,1), ($ate_dollar == $tno  ? '$' : ''));
    my $class = 'global';
    $class = 'myfile' if(defined $ValType[$tno] && $ValType[$tno] eq "X");
    $class = 'myfile' if($::implicit_global_my);
    $class = 'myfile' if($ValPerl[$tno] =~ /^\$[ab]$/);  # Sort vars
    $TokenStr=join('',@ValClass);
    my $declared_here = 0;
    if($ValClass[0] eq 't' && index($TokenStr,'=') < 0) {           # We are declaring this var
        $class = $ValPerl[0];
        $class = 'myfile' if($class eq 'my' && !in_sub());
        $declared_here = 1;
    } elsif($ValClass[0] eq 'c' && $ValClass[1] eq '(' && $ValClass[2] eq 't' && 
            $ValClass[3] =~ /[sahG]/ && $ValPerl[3] eq $ValPerl[$tno]) {      # e.g. for(my $i...; while my(@arr...
        $class = $ValPerl[2];
        $declared_here = 1;
    } elsif($ValClass[0] eq 'c' && $ValClass[1] eq 't' && $tno == 2) {  # e.g. foreach my $i (@arr)
        $class = $ValPerl[1];
        $declared_here = 1;
    } elsif($ValClass[0] eq 'f' && $ValPerl[0] eq 'open' && $ValClass[1] eq 't' && $tno == 2) {  # e.g. open my $fh
        $class = $ValPerl[1];
        $declared_here = 1;
    } elsif($ValClass[0] eq 'f' && $ValPerl[0] eq 'open' && $ValClass[1] eq '(' && 
            $ValClass[2] eq 't' && $tno == 3) {                                                  # e.g. open(my $fh
        $class = $ValPerl[2];
        $declared_here = 1;
    } elsif($tno != 0 && $ValClass[$tno-1] eq 't') {    # issue s3: for(my $i, my $j...)
        $class = $ValPerl[$tno-1];
        $declared_here = 1;
    }
    $class = 'myfile' if($class eq 'local' && !@nesting_stack); # 'local' at outer scope is same as 'my'
    if($class eq 'our') {
        if($::implicit_global_my) {
            $class = 'myfile' 
        } else {
            $class = 'global' 
        }
    }
    if($last_varclass_lno != $. && $last_varclass_lno) {
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
    }
    $last_varclass_lno = $.;
    my $cs = cur_sub();
    if(!exists $line_varclasses{$last_varclass_lno}{$name} || $class eq 'my' || $class eq 'local') {
        my $cls = $class;
        if(!exists $last_varclass_sub{$name} || $last_varclass_sub{$name} ne $cs) {
            $cls = map_var_class_into_sub($class) if(!$declared_here);
            $last_varclass_sub{$name} = $cs;
        }
        $line_varclasses{$last_varclass_lno}{$name} = $class;
        $sub_varclasses{$cs}{$name} = $cls;
    } elsif(exists $line_varclasses{$last_varclass_lno}{$name}) {
        $class = $line_varclasses{$last_varclass_lno}{$name};
        my $cls = $class;
        if(!exists $last_varclass_sub{$name} || $last_varclass_sub{$name} ne $cs) {
            $cls = map_var_class_into_sub($class) if(!$declared_here);
            $last_varclass_sub{$name} = $cs;
            $sub_varclasses{$cs}{$name} = $cls;
        }
    }
    # Moved this code into add_package_name and friends so it runs in pass 2
    #if($::remap_global && !$::remap_all && $class eq 'global') {
    #$::remap_all = 1;
    #my $sigil = substr($name,0,1);
    #my $id = substr($name,1);
    #if(index('$@%&*', $sigil) < 0) {
    #$id = $name;
    #$sigil = '';
    #}
    #$ValPy[$tno] = remap_conflicting_names($id, $sigil, '');
    #$::remap_all = 0;
    #}
    add_package_name($name) if($class eq 'global' || $class eq 'local');
}

sub propagate_varclass_for_here
# For a here doc, just propagate the varclass from the prior line
{
    say STDERR "propagate_varclass_for_here: last_varclass_lno=$last_varclass_lno, lno=$." if($::debug);
    if($last_varclass_lno != $. && $last_varclass_lno) {
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
    }
    $last_varclass_lno = $.;
}

sub map_var_class_into_sub
# For a sub, map the class of the incoming (non-arg) variable
{
    my $cls = shift;
    $cls = 'nonlocal' if($cls eq 'my');
    $cls = 'package' if($cls eq 'global');
    $cls = 'global' if($cls eq 'myfile');
    return $cls;
}

sub determine_varclass_keepers
# We just exited a block, determine what varclass entries survive
{
    my $varclasses_at_top = shift;
    my $top_lno = shift;

    #if($last_varclass_lno == $top_lno) {          # We added nothing (WRONG!  We could have a one-line sub)
    #$line_varclasses{$.} = $varclasses_at_top;
    #$last_varclass_lno = $.;
    #return;
    #}
    my $varclasses_at_bottom = dclone($line_varclasses{$last_varclass_lno});
    for my $name (keys %{$varclasses_at_bottom}) {
        my $class = $varclasses_at_bottom->{$name};
        if($class ne 'global') {
            delete $varclasses_at_bottom->{$name};
            $varclasses_at_bottom->{$name} = $varclasses_at_top->{$name} if(exists $varclasses_at_top->{$name});
        }
    }
    $line_varclasses{$.} = $varclasses_at_bottom;
    $last_varclass_lno = $.;
}

sub get_sub_vars_with_class
# For nested subs: Using sub_varclasses, return a list of variable we need to declare as class (e.g. global/nonlocal)
{
    my $sub = shift;
    my $class = shift;

    my @result = ();
    return @result unless(exists $sub_varclasses{$sub});
    for my $perl_name (keys %{$sub_varclasses{$sub}}) {
        if($sub_varclasses{$sub}{$perl_name} eq $class) {
            my $py = get_py_name($perl_name);
            push @result, $py if(defined $py);
        }
    }
    return @result;
}

sub get_py_name
# From the perl_name, get the python name from our NameMap.  Returns undef if we don't have a real python name
# for this variable, e.g. $1
{
    my $perl_name = shift;

    my $sigil = substr($perl_name,0,1);
    my $name = substr($perl_name,1);
    if($sigil =~ /[a-z_]/) {
        $sigil = '';
        $name = $perl_name;
    }
    if(!$::import_perllib && length($name) == 1 && exists $SPECIAL_VAR{$name}) {
        # Handle the case of assignments to vars like $@ which is mapped to EVAL_ERROR and we have
        # to declare global unless we're using perllib (in which case it assigns perllib.EVAL_ERROR)
        $pyname = $SPECIAL_VAR{$name};
        return $pyname if(exists $GLOBALS{$pyname});
    }
    return undef unless(exists $NameMap{$name});
    return undef unless(exists $NameMap{$name}{$sigil});
    return $NameMap{$name}{$sigil};
}

sub def_label                   # issue 94
{
    $label = shift;
    if($::debug >= 4) {
        say STDERR "def_label($label)";
    }
    $last_label = $label;
    $all_labels{$label} = 1;
}

sub could_be_anonymous_sub_close        # SNOOPYJC
# Could this '}' be the close of an anonymous sub?
{
    return 0 if(!@nesting_stack);
    $top = $nesting_stack[-1];
    return 0 if(!$top->{is_sub});
    return 1 if($top->{cur_sub} =~ /^$ANONYMOUS_SUB\d+$/);
    return 0;
}

sub in_conditional                      # SNOOPYJC
{
    my $pos = shift;
    for(my $i=$pos+1; $i <= $#ValClass; $i++) {         # Check for a conditional statement modifier
        if($ValClass[$i] eq 'c' && ($ValPerl[$i] eq 'if' || $ValPerl[$i] eq 'unless')) {
            return 1;
        }
    }
    return 0 if(!@nesting_stack);
    $top = $nesting_stack[-1];
    return $top->{in_cond};
}

sub in_sub                      # SNOOPYJC
{
    return 0 if(!@nesting_stack);
    $top = $nesting_stack[-1];
    return $top->{in_sub};
}

sub cur_sub                     # SNOOPYJC
{
    return '__main__' if(!@nesting_stack);
    $top = $nesting_stack[-1];
    return (defined $top->{cur_sub} ? $top->{cur_sub} : '__main__');
}

sub get_loop_ctr		# SNOOPYJC
{
    return undef if(!@nesting_stack);
    $top = $nesting_stack[-1];
    if(defined $top->{loop_ctr}) {
    	return $top->{loop_ctr};
    }
    return undef;
}

sub set_loop_ctr_mod		# SNOOPYJC
# Set that the loop counter is modified in the loop
{
    my $lc_name = shift;

    for(my $i = $#nesting_stack; $i >= 0; $i--) {
        if($nesting_stack[$i]->{type} eq 'for' && exists($nesting_stack[$i]->{loop_ctr}) && index($nesting_stack[$i]->{loop_ctr}, $lc_name) == 0) {
            say STDERR "exit_block: setting line_contains_for_loop_with_modified_counter{$nesting_stack[$i]->{lno}} from assignment to $lc_name in line $." if($::debug >= 5);
            $line_contains_for_loop_with_modified_counter{$nesting_stack[$i]->{lno}} = $lc_name;
            last;
        }
    }
}

sub is_continue_block
# Return True if this is a continue block.  Pass "1" if calling at the bottom of the block
{
    my $at_bottom = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    return 1 if($top->{type} eq 'continue');
    return 0;
}

sub track_continue
# Track a 'continue' statement as soon as we lex it in the first pass
{
    say STDERR "track_continue setting line_needs_try_block{$nesting_last->{lno}} to EXCEPTION|CONTINUE" if($::debug >= 5);
    my $ex = 0;
    if(exists $line_needs_try_block{$nesting_last->{lno}} &&
        ($line_needs_try_block{$nesting_last->{lno}} & TRY_BLOCK_HAS_NEXT)) {
       $ex = TRY_BLOCK_EXCEPTION;
    }
    $line_needs_try_block{$nesting_last->{lno}} |= $ex | TRY_BLOCK_HAS_CONTINUE;
}

sub track_redo
# Track a 'redo' statement and warn if it's in a continue block
# Called in the first pass after we lex the entire statement
{
    my $pos = shift;

    my $label = undef;

    if($#ValClass >= $pos+1 && $ValClass[$pos+1] eq 'i') {
        $label = $ValPerl[$pos+1];
    }
    return if(!@nesting_stack);
    $ndx = loop_ndx_with_label($label);
    if($nesting_stack[$ndx]->{type} eq 'continue') {
        logme('W',"A 'redo' statement in a continue block is not supported");
        return;
    } elsif(defined $label) {
        logme('W',"A 'redo' statement with a label ($label) is not supported");
        return;
    }
    say STDERR "track_redo setting line_needs_try_block{$nesting_stack[$ndx]->{lno}} to REDO" if($::debug >= 5);
    $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= TRY_BLOCK_REDO_LOOP;
}

sub flag_next_in_continue
# Flag a 'next' statement if it's in a continue block
{
    return if(!@nesting_stack);
    $ndx = cur_loop_ndx();
    if($nesting_stack[$ndx]->{type} eq 'continue') {
        logme('W',"A 'next' statement in a continue block is not supported");
    }
}

sub enter_block                 # issue 94
{
    # SNOOPYJC: Now we use a different character (^ all alone) to replace the '{' for the second round
    # SNOOPYJC return if($last_block_lno == $. && scalar(@ValPerl) <= 1);       # We see the '{' twice on like if(...) {
    if($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
        no warnings;
        say STDERR "enter_block at line $., prior nesting_level=$nesting_level, ValPerl=@ValPerl";
    }
    if($Pythonizer::PassNo == &Pythonizer::PASS_1) {          # Do this in the first pass only
        $last_block_lno = $.;
        if(!$last_varclass_lno) {
            $last_varclass_lno = $.;
            $line_varclasses{$last_varclass_lno} = {};
        }
        if($last_varclass_lno != $last_block_lno) {
            $line_varclasses{$last_block_lno} = dclone($line_varclasses{$last_varclass_lno});
        }
    }
    my %nesting_info = ();
    my $begin = 0;
    $begin++ if(scalar(@ValClass) >= 2 && $ValClass[0] eq 'W');         # with fileinput...
    $nesting_info{type} = '';
    $nesting_info{type} = $ValPy[$begin];
    $nesting_info{type} =~ s/:\s*$//;           # Change "else: " to "else"
    $nesting_info{loop_ctr} = $nesting_stack[-1]{loop_ctr} if(scalar(@nesting_stack) && exists($nesting_stack[-1]{loop_ctr}));
    if($nesting_info{type} eq 'for') {
        my $lcx = index($TokenStr,'s=');
        $lcx = index($TokenStr, 's^') if($lcx < 0);     # Loop for $i++ or $i-- if no loop ctr init
        if($lcx > 0) {
	    if(exists $nesting_info{loop_ctr}) {
                $nesting_info{loop_ctr} = $ValPerl[$lcx] . ',' . $nesting_info{loop_ctr};
	    } else {
                $nesting_info{loop_ctr} = $ValPerl[$lcx];
            }
        }
    }
    $nesting_info{lno} = $.;
    $nesting_info{varclasses} = dclone($line_varclasses{$last_block_lno}) if($Pythonizer::PassNo == &Pythonizer::PASS_1);
    $nesting_info{level} = $nesting_level;
    # Note a {...} block by itself is considered a loop
    $nesting_info{is_loop} = ($begin <= $#ValClass && ($ValPy[$begin] eq '{' || $ValPerl[$begin] eq 'for' || 
                                                       $ValPerl[$begin] eq 'foreach' || $ValPerl[$begin] eq 'continue' ||
                                                       $ValPerl[$begin] eq 'while' || $ValPerl[$begin] eq 'until'));
    $nesting_info{is_cond} = ($begin <= $#ValClass && ($ValPerl[$begin] eq 'if' || $ValPerl[$begin] eq 'unless' ||
                                                       is_eval() ||    # issue ddts
                                                       $ValPerl[$begin] eq 'elsif' || $ValPerl[$begin] eq 'else'));
    # SNOOPYJC: eval doesn't have to be first! $nesting_info{is_eval} = ($begin <= $#ValClass && $ValPerl[$begin] eq 'eval');
    $nesting_info{is_eval} = is_eval();		# SNOOPYJC
    $nesting_info{is_sub} = ($begin <= $#ValClass && $ValPerl[$begin] eq 'sub');
    $nesting_info{cur_sub} = (($begin+1 <= $#ValClass && $nesting_info{is_sub}) ? $ValPerl[$begin+1] : undef);

    $nesting_info{in_loop} = ($nesting_info{is_loop} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_loop}));
    $nesting_info{in_cond} = ($nesting_info{is_cond} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_cond}));
    $nesting_info{in_eval} = ($nesting_info{is_eval} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_eval}));
    $nesting_info{in_sub} = ($nesting_info{is_sub} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_sub}));
    if($nesting_info{in_sub} && !$nesting_info{is_sub}) {
        $nesting_info{cur_sub} = $nesting_stack[-1]{cur_sub};
    }
    if(defined $last_label) {
        $nesting_info{label} = $last_label;
        $last_label = undef;            # We used it up
    }
    push @nesting_stack, \%nesting_info;
    if($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
        no warnings 'uninitialized';
        say STDERR "nesting_info=@{[%nesting_info]}";
    }
    $nesting_level++;
}

sub exit_block                  # issue 94
{
    if($nesting_level == 0) {
        if($::debug >= 1) {
            say STDERR "ERROR: exit_block at line $., prior nesting_level=$nesting_level <<<<";
        }
        return;
    }
    $nesting_last = pop @nesting_stack;
    if($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
        say STDERR "exit_block at line $., prior nesting_level=$nesting_level, nesting_last->{type} is now $nesting_last->{type}";
    }
    determine_varclass_keepers($nesting_last->{varclasses}, $nesting_last->{lno}) if($Pythonizer::PassNo == &Pythonizer::PASS_1);
    my $label = '';
    $label = $nesting_last->{label} if(exists $nesting_last->{label});
    if(exists $nesting_last->{can_call} && $Pythonizer::PassNo == &Pythonizer::PASS_1) {
        for $sub (keys %{$nesting_last->{can_call}}) {
            if(exists $sub_external_last_nexts{$sub} && exists $sub_external_last_nexts{$sub}{$label}) {
                say STDERR "exit_block: setting line_needs_try_block{$nesting_last->{lno}} from call to $sub" if($::debug >= 5);
                $line_needs_try_block{$nesting_last->{lno}} |= TRY_BLOCK_EXCEPTION;
            }
        }
    }
    $nesting_level--;
}

sub is_eval                             # SNOOPYJC
# Is this an 'eval'?
{
    for(my $i=0; $i <= $#ValClass; $i++) {
        return 1 if($ValClass[$i] eq 'C' && $ValPerl[$i] eq 'eval');
    }
    return 0;
}

sub last_next_propagates        # issue 94
# Does this last/next propagate out of this sub?
# Side effect - sets {needs_try_block} on any loops we need to generate a try block for
{
    $pos = shift;
    $label = shift;

    if(!defined $label && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
        return 1 if($nesting_level == 0);
        $top = $nesting_stack[-1];
        if($top->{in_loop}) {      # If this is NOT a stmt level last/next, we need the exception for it
            for $ndx (reverse 0 .. $#nesting_stack) {
                if($nesting_stack[$ndx]->{is_loop}) {
                    my $exc = ($pos == 0) ? 0 : TRY_BLOCK_EXCEPTION;
                    if($exc) {
                        $nesting_stack[$ndx]->{needs_try_block} = 1;
                        say STDERR "last_next_propagates: setting line_needs_try_block{$nesting_stack[$ndx]->{lno}} from last/next at line $." if($::debug >= 5);
                    }
                    my $typ = ($ValPerl[$pos] eq 'last') ? TRY_BLOCK_HAS_LAST : TRY_BLOCK_HAS_NEXT;
                    $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= $exc | $typ;
                    last;
                }
            }
        }
        return !($top->{in_loop} || $top->{in_eval});
    } elsif($Pythonizer::PassNo == &Pythonizer::PASS_1) {         # only do this once
        for $ndx (reverse 0 .. $#nesting_stack) {
            if(exists $nesting_stack[$ndx]->{label} && $nesting_stack[$ndx]->{label} eq $label) {
                if($ndx != $#nesting_stack) {           # No need to use exception for last/next inner if at stmt level;
                    $nesting_stack[$ndx]->{needs_try_block} = 1;
                    say STDERR "last_next_propagates: setting line_needs_try_block{$nesting_stack[$ndx]->{lno}} from last/next at line $." if($::debug >= 5);
                    my $typ = ($ValPerl[$pos] eq 'last') ? TRY_BLOCK_HAS_LAST : TRY_BLOCK_HAS_NEXT;
                    $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= TRY_BLOCK_EXCEPTION | $typ;
                }
                return 0;
            }
        }
        return 1;
    }
}

sub handle_pos_ref
# Handle reference to pos function by marking the appropriate loop with a 'pos' flag
{
    my $pos = shift;

    if($Pythonizer::PassNo == &Pythonizer::PASS_1) {         # only do this once
        #say STDERR "handle_pos_ref($ValPerl[$pos]) scalar_pos_gen_line=@{[%scalar_pos_gen_line]}";
        if(exists $scalar_pos_gen_line{$ValPerl[$pos]}) {
            $line_contains_pos_gen{$scalar_pos_gen_line{$ValPerl[$pos]}} = $ValPerl[$pos];
        }
    }
}

sub handle_return_in_expression         # SNOOPYJC: Handle 'return' in the middle of an expression
{
    return if($Pythonizer::PassNo != &Pythonizer::PASS_1);
    # In the first pass, just mark that we need a try/except block for this sub,
    # but do nothing if we're in an eval since that case is already handled.
    for $ndx (reverse 0 .. $#nesting_stack) {
        return if($nesting_stack[$ndx]->{is_eval});     # We already have an exception to get out of an eval
        if($nesting_stack[$ndx]->{is_sub}) {
            $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= TRY_BLOCK_EXCEPTION;  # Need an exception to return from this sub
            $uses_function_return_exception = 1;
            return;
        }
    }
}

sub handle_last_next            # issue 94
{
    my $pos = shift;

    my $label = undef;

    return if($nesting_level == 0);
    if($#ValClass >= $pos+1 && $ValClass[$pos+1] eq 'i') {
        $label = $ValPerl[$pos+1];
    }
    if(last_next_propagates($pos, $label)) {
        my $top = $nesting_stack[-1];
        my $sub = $top->{cur_sub};
        return if(!defined $sub);
        $label = '' if(!defined $label);
        $sub_external_last_nexts{$sub}{$label} = 1;
    }
}

sub track_potential_sub_call    # issue 94
# Keep track of what subs are potentially called in this loop (if we're in a loop)
# Ok if it contains mistakes as long as it contains the actual subs we can call, e.g. 'i' class values that turn into strings
{
    my $name = shift;
    
    return if($nesting_level == 0);
    return if(!$nesting_stack[-1]->{in_loop});
    say STDERR "track_potential_sub_call($name) at line $." if($::debug >= 5);
    for $ndx (reverse(0 .. $#nesting_stack)) {
        $nesting_stack[$ndx]->{can_call}{$name} = 1;
    }
}

sub needs_try_block                # issue 94, issue 108
{
    my $at_bottom = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($::debug >= 4) {
        no warnings 'uninitialized';
        say STDERR "needs_try_block($at_bottom), top=@{[%$top]}";
    }
    return 1 if(exists $line_needs_try_block{$top->{lno}} && 
        ($line_needs_try_block{$top->{lno}} & (TRY_BLOCK_EXCEPTION|TRY_BLOCK_FINALLY)));
    return 0;
}

sub in_eval
# Are we in an eval?
{
    return 0 if($nesting_level == 0);
    $top = $nesting_stack[-1];
    return $top->{in_eval};
}

sub in_BEGIN            # issue s12
# Are we in a BEGIN/UNITCHECK/CHECK/INIT block?
{
    return 0 if($nesting_level == 0);
    for $ndx (reverse 0 .. $#nesting_stack) {
        return 1 if $nesting_stack[$ndx]->{type} eq 'for _ in range(1)';
    }
    return 0;
}

sub has_continue                # SNOOPYJC
{
    my $at_bottom = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($::debug >= 4) {
        no warnings 'uninitialized';
        say STDERR "has_continue($at_bottom), top=@{[%$top]}";
    }
    return 1 if(exists $line_needs_try_block{$top->{lno}} && 
        ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_HAS_CONTINUE));
    return 0;
}

sub set_needs_implicit_continue
{
    my $saved_tokens = shift;

    my $top = $nesting_stack[-1];
    $top->{implicit_continue} = $saved_tokens;
    my $exc = 0;
    $exc = 1 if(exists $line_needs_try_block{$top->{lno}} && ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_HAS_NEXT));
    $line_needs_try_block{$top->{lno}} |= $exc | TRY_BLOCK_HAS_CONTINUE;
    say STDERR "set_needs_implicit_continue, setting line_needs_try_block{$top->{lno}} to EXCEPTION|CONTINUE" if($::debug >= 3);
    say STDERR "set_needs_implicit_continue = @{$saved_tokens->{py}}" if($::debug >= 3);
}

sub needs_implicit_continue
{
    my $at_bottom = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($::debug >= 4) {
        no warnings 'uninitialized';
        say STDERR "needs_implicit_continue($at_bottom), top=@{[%$top]}";
    }
    return $top->{implicit_continue} if(exists $top->{implicit_continue});
    return 0;
}

sub needs_redo_loop                # SNOOPYJC
{
    my $at_bottom = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($::debug >= 4) {
        no warnings 'uninitialized';
        say STDERR "needs_try_block($at_bottom), top=@{[%$top]}";
    }
    return 1 if(exists $line_needs_try_block{$top->{lno}} && 
                ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_REDO_LOOP));
    return 0;
}

sub cur_loop_ndx                     # SNOOPYJC
# Get the index of the current loop block, if any
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        next if(!$nesting_stack[$ndx]->{is_loop});
        return $ndx;
    }
    return -1;
}

sub loop_ndx_with_label                     # SNOOPYJC
# Get the index of the current loop block, if any
{
    my $label = shift;

    if(!defined $label) {
        return cur_loop_ndx();
    }
    for $ndx (reverse 0 .. $#nesting_stack) {
        next if(!$nesting_stack[$ndx]->{is_loop});
        if(exists $nesting_stack[$ndx]->{label} && $nesting_stack[$ndx]->{label} eq $label) {
            return $ndx;
        }
    }
    return -1;
}

sub cur_loop_label                     # issue 94
# Get the label of the current block, if any
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        next if(!$nesting_stack[$ndx]->{is_loop});
        if(exists $nesting_stack[$ndx]->{label}) {
            return $nesting_stack[$ndx]->{label};
        }
        return '';
    }
    return '';
}

sub try_block_exception_name           # issue 94
# What is the exception label for this try block?  Called at the bottom of the block only.
# Returns undef if no exception needs to be caught
{
    my $top = $nesting_last;
    return undef if(!($line_needs_try_block{$top->{lno}} & TRY_BLOCK_EXCEPTION));
    return $FUNCTION_RETURN_EXCEPTION if($top->{is_sub});
    return label_exception_name('') if(!exists $top->{label} || !defined $top->{label});      # issue 108
    return label_exception_name($top->{label});
}

sub gen_try_block_finally               # issue 108
# If this try block needs a finally clause, generate it
{
    my $top = $nesting_last;
    return if(!($line_needs_try_block{$top->{lno}} & TRY_BLOCK_FINALLY));
    gen_statement();
    &Pythonizer::correct_nest(-1,-1);
    gen_statement('finally:');
    &Pythonizer::correct_nest(1,1);
    my $lno = $top->{lno};
    my $code_generated = 0;
    for my $local (reverse @{$line_locals{$lno}}) {
        my $sigil = substr($local,0,1);
        if($sigil eq '*') {         # We appended the ones we need to the name
            # We have like *id,$%@ - split out each of the "$%@".  We encode a
            # bare one as '^'.
            my ($quote, $sigils) = split /,/, $local;
            my $id = substr($quote,1);
            $sigils = '' if(!defined $sigils);
            for(my $i=length($sigils)-1; $i >= 0; $i--) {       # Grab them in reverse order
                my $sig = substr($sigils,$i,1);
                $sig = '' if($sig eq '^');
                $quote = $sig . $id;
                $pyname = $line_locals_map{$lno}{$quote};
                gen_statement("$pyname = $LOCALS_STACK.pop()");
                $code_generated = 1;
            }
        } else {
            $pyname = $line_locals_map{$lno}{$local};
            $pyname = $SpecialVarR2L{$pyname} if(exists $SpecialVarR2L{$pyname});       # Map _nr() to INPUT_LINE_NUMBER etc
            # For signals, $pyname is like "signal.signal(signal.SIGINT)"
            if($pyname =~ /^signal\.signal\(/) {
                $pyname =~ s/\)/, $LOCALS_STACK.pop())/;
                gen_statement($pyname);
            } else {
                gen_statement("$pyname = $LOCALS_STACK.pop()");
            }
            $code_generated = 1;
        }
    }
    if(!$code_generated) {
        gen_statement('pass');
    }
}

sub next_last_needs_raise               # issue 94
# Do we need to generate a raise statement for this next/last?
{
    my $pos = shift;

    return 1 if($nesting_level == 0);           # Generate an exception instead of a syntax error
    my $top = $nesting_stack[-1];
    return 1 if(!$top->{in_loop});
    my $ndx = cur_loop_ndx();
    my $is_next = ($ValPerl[$pos] eq 'next');
    return 1 if(exists $line_needs_try_block{$nesting_stack[$ndx]->{lno}} && $is_next &&
                ($line_needs_try_block{$nesting_stack[$ndx]->{lno}} & (TRY_BLOCK_HAS_CONTINUE|TRY_BLOCK_REDO_LOOP)));
    return 1 if(exists $line_needs_try_block{$nesting_stack[$ndx]->{lno}} && !$is_next &&
                ($line_needs_try_block{$nesting_stack[$ndx]->{lno}} & TRY_BLOCK_REDO_LOOP));
    return 0;
}

sub handle_local                        # issue 108
# Called in the first pass when we see a 'local' statement
{
    # local EXPR
    # A local modifies the listed variables to be local to the enclosing block, file, or eval. If more than one value is listed, the list must be placed in parentheses.
    # local $foo;                # make $foo dynamically local
    # local (@wid, %get);        # make list of variables local
    # local $foo = "flurp";      # make $foo dynamic, and init it
    # local @oof = @bar;         # make @oof dynamic, and init it
    # local *FH;                 # localize $FH, @FH, %FH, &FH  ...
    #
    # NOT SUPPORTED:
    #
    # local $hash{key} = "val";  # sets a local value for this hash entry
    # delete local $hash{key};   # delete this entry for the current block
    # local ($cond ? $v1 : $v2); # several types of lvalues support localization

    if($ValClass[-1] eq 'k' && $ValPerl[-1] eq 'sub') {         # This line is like "local $SIG{__WARN__} = sub {"
        return;                                                 # Skip it as we will see it again after handling the sub
    }
    my @locals = ();

    my $i;
    for($i = 1; $i<=$#ValClass; $i++) {
        last if($ValClass[$i] eq '=');
        if($ValClass[$i] =~ /[ashG]/) {
            if($i+1 <= $#ValClass && $ValClass[$i+1] eq '(') {
                #logme('W',"A 'local' statement with a subscript or hash key is not implemented for $ValPerl[$i]");
                my $real_name = actual_sigil(substr($ValPerl[$i],0,1), $ValPerl[$i+1]) . substr($ValPerl[$i],1);
                #say STDERR "local real_name=$real_name";
                push @locals, $real_name;
                $i = &::end_of_variable($i);
            } else {
                push @locals, $ValPerl[$i];
            }
        } elsif($ValClass[$i] eq 'f' && $ValPerl[$i] eq '%SIG' && $ValClass[$i+1] eq '(' &&
                $ValClass[$i+2] eq 'i') {       # SNOOPYJC: Special handling for local $SIG{XXX}
            my $real_name = "$ValPy[$i]($ValPy[$i+2])";
            push @locals, $real_name;
            last;
        }
    }
    return if(!@nesting_stack);       # Local at the outermost file level is treated like "my" so we can skip them
    $top = $nesting_stack[-1];
    #if($ValClass[-1] eq 'k' && $ValPerl[-1] eq 'sub') {         # This line is like "local $SIG{__WARN__} = sub {"
    #    $top = $nesting_stack[-2];                              # so these locals belong to the outer scope
    #}
    my $lno = $top->{lno};
    if($::debug >=5) {
        say STDERR "handle_local for line $. pushed @locals to block on line $lno";
    }
    if(exists $line_locals{$lno}) {
        push @{$line_locals{$lno}}, @locals;
    } else {
        $line_locals{$lno} = \@locals;
    }
    $line_sub{$lno} = (defined $top->{cur_sub} ? $top->{cur_sub} : '__main__');
    $line_needs_try_block{$top->{lno}} |= TRY_BLOCK_FINALLY;
}

sub prepare_local
{
    my $quote = shift;
    my $lno = shift;

    my $sigil = substr($quote,0,1);
    my $sub = $line_sub{$lno};

    my $bare = 0;
    my $bare1 = 0;
    if($sigil eq '$') {
        decode_scalar($quote,0);
        $ValPy[0] = 'perllib.TRACEBACK' if($ValPy[0] eq 'perllib_.TRACEBACK_v'); # issue ddts: local %SIG{__DIE__};
        $ValPy[0] = 'perllib.TRACEBACK' if($ValPy[0] eq 'perllib_.TRACEBACK'); # issue ddts: local %SIG{__DIE__};
    } elsif($sigil eq '@') {
        decode_array($quote);
    } elsif($sigil eq '%') {
        decode_hash($quote);
    } elsif($sigil =~ /[A-Za-z_]/) {
        decode_bare($quote);
	$bare = 1 if($FileHandles{$quote});
        $bare1 = 1 unless($FileHandles{$quote});
    } else {
        return;
    }
    #add_package_name(substr($quote,0,$cut));           # SNOOPYJC: Doesn't work here
    my $has_dot = (index($ValPy[0],'.') >= 0);
    if(!$::implicit_global_my && !$bare1 && !$has_dot) {  # SNOOPYJC: Add the package name manually
        if($ValPy[0] =~ /^\(len\((.*)\)-1\)$/) {
            $ValPy[0] = '(len(' . cur_package() . '.' . $1 . ')-1)';
        } elsif($ValPy[0] =~ /^len\((.*)\)$/) {
            $ValPy[0] = 'len(' . cur_package() . '.' . $1 . ')';
        } else {
            $ValPy[0] = cur_package() . '.' . $ValPy[0];         # Add the package name
        }
    }
    $Pythonizer::VarSubMap{$ValPy[0]}{$sub} = '+' if($bare);  # We don't detect it because it's normally an 'i' token like FH
    $line_locals_map{$lno}{$quote} = $ValPy[0];
    if(!$has_dot && !exists $Pythonizer::NeedsInitializing{$sub}{$ValPy[0]}) {
        my $typ = 'm';
        $typ = $Pythonizer::VarType{$ValPy[0]}{$sub} if(exists $Pythonizer::VarType{$ValPy[0]}{$sub});
        $Pythonizer::NeedsInitializing{$sub}{$ValPy[0]} = $typ;
    }
}

sub prepare_locals              # issue 108
# Prepare all locals for code generation.  Call this once before the second pass.
# We map the perl names to the python names and decide which of the *XXXX variables
# we need to push on the stack.
# Note that file scoped locals are not handled here (they are treated like "my" vars).
{
    local $cut;
    local @ValPy;
    local @ValType;
    local $tno = 0;
    foreach my $lno (keys %line_locals) {
        for(my $i = 0; $i < scalar(@{$line_locals{$lno}}); $i++) {
            my $quote = $line_locals{$lno}->[$i];
            my $sigil = substr($quote,0,1);
            prepare_local($quote, $lno);
            if($sigil eq '*') {
                my $id = substr($quote,1);
                $line_locals{$lno}->[$i] .= ',';
                if(exists $NameMap{$id}) {
                    for my $sig (keys %{$NameMap{$id}}) {
                        next if($sig eq '&');
                        #push @{$line_locals{$lno}}, ($sig . $id);
                        prepare_local("$sig$id", $lno);
                        $sig = '^' if(!$sig);
                        $line_locals{$lno}->[$i] .= $sig;       # Append a little char list of the ones we need
                    }
                }
            }
        }
    }
    if($::debug >= 5) {
       $Data::Dumper::Indent=1;
       $Data::Dumper::Terse = 1;
       print STDERR "line_locals = ";
       say STDERR Dumper(\%line_locals);
       print STDERR "line_locals_map = ";
       say STDERR Dumper(\%line_locals_map);
       print STDERR "line_sub = ";
       say STDERR Dumper(\%line_sub);
    }
}

sub push_locals               # issue 108
# Push all locals declared in this block
{
    my $cursub = shift;

    my $top = $nesting_stack[-1];
    return if(!($line_needs_try_block{$top->{lno}} & TRY_BLOCK_FINALLY));
    gen_statement();
    my @globals = ();
    if(exists $Pythonizer::GlobalVar{$cursub}) { 
        my $globals_decl = $Pythonizer::GlobalVar{$cursub};
        @globals = split /,/, substr($globals_decl,length('global '));
    }
    my %globals_set = map { $_ => 1 } @globals;
    my $lno = $top->{lno};
    for my $local (@{$line_locals{$lno}}) {
        my $sigil = substr($local,0,1);
        if($sigil eq '*') {         # We appended the ones we need to the name
            # We have like *id,$%@ - split out each of the "$%@".  We encode a
            # bare one as '^'.
            my ($quote, $sigils) = split /,/, $local;
            my $id = substr($quote,1);
            $sigils = '' if(!defined $sigils);
            for(my $i=0; $i < length($sigils); $i++) {
                my $sig = substr($sigils,$i,1);
                $sig = '' if($sig eq '^');
                $quote = $sig . $id;
                $pyname = $line_locals_map{$lno}{$quote};
                if(!exists $globals_set{$pyname} && $pyname =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
                    gen_statement("global $pyname") 
                }
                gen_statement("$LOCALS_STACK.append($pyname)");
            }
        } else {
            $pyname = $line_locals_map{$lno}{$local};
            if(!exists $globals_set{$pyname} && $pyname =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
                gen_statement("global $pyname") 
            }
            # For signals, $pyname is like "signal.signal(signal.SIGINT)"
            $pyname =~ s/^signal\.signal\(/signal.getsignal(/;
            gen_statement("$LOCALS_STACK.append($pyname)");
        }
    }
}

sub init_local_typeglobs                         # issue 108
#  Initialize all the typeglob (*XXXX) locals declared on this statement
{
    my $cursub = shift;

    return if(!@nesting_stack);       # File scoped locals are not handled here

    my $top = $nesting_stack[-1];
    my $lno = $top->{lno};

    # In the case of a conditional local statement, like local x if(y);, we won't
    # have a mapping for the line number of that block we inserted, and we
    # already generated the code to push the locals, so we skip it.
    return if(!exists $line_locals_map{$lno});

    my $eq = &Pythonizer::next_same_level_token('=', 1, $#ValClass);
    return if($eq >= 0);

    for(my $i = 1; $i<=$#ValClass; $i++) {
        last if($ValClass[$i] eq '=');
        if($ValClass[$i] eq 'G') { # typeglob
            my $id = substr($ValPerl[$i],1);
            for my $sig (keys %{$NameMap{$id}}) {
                next if($sig eq '&');
                my $pyname = $line_locals_map{$lno}{$sig.$id};
                say STDERR "ERROR: Can't find line_locals_map{$lno}{$sig$id}!!" if(!defined $pyname);
                # Initialize typeglobs
                my $type = $SIGIL_MAP{$sig};
                $type = $Pythonizer::VarType{$pyname}{$cursub} if(exists $Pythonizer::VarType{$pyname}{$cursub});
                gen_statement("$pyname = " . &Pythonizer::init_val($type));
            }
        }
    }
}

sub choose_glob                 # issue 108
# Given a reference (probably an assignment to) a *typeglob, choose one of it's components to assign to
# Give a warning if there was more than one possibility
# arg1 = ValPerl
# arg2 = ValPy = default if not found
# result = ValPy
{
    my $perl = shift;
    my $py = shift;

    my $id = substr($perl,1);           # Remove the '*'
    return $py if(!exists $NameMap{$id});
    my @keys = keys %{$NameMap{$id}};
    return $py if(scalar(@keys) == 0);
    my $rdot = rindex($py, '.');
    my $package = '';
    $package = substr($py,0,$rdot+1) if($rdot >= 0);
    return ($package . $NameMap{$id}{$keys[0]}) if(scalar(@keys) == 1);      # That was easy!
    my @selection = ('%', '@', '$', '');
    foreach my $sel (@selection) {
        if(exists $NameMap{$id}{$sel}) {
            $result = $NameMap{$id}{$sel};
            logme('W',"Choosing $sel$id ($result) for $perl typeglob");
            return $package . $result;
        }
    }
    return $package . $NameMap{$id}{$keys[0]};
}

#
# Tokenize line into one string and three arrays @ValClass  @ValPerl  @ValPy
#
sub tokenize
{
my ($l,$m);
   $source=$line=$_[0];
   if(scalar(@_) != 2) {        # 2nd arg means to continue where we left off
       $tno=0;
       @ValClass=@ValCom=@ValPerl=@ValPy=@ValType=(); # "Token Type", token comment, Perl value, Py analog (if exists)
       $TokenStr='';
       $statement_starting_lno = $.;                      # issue 116
   } else {
       $tno = scalar(@ValClass);
       $TokenStr=join('', @ValClass);
   }
   $ExtractingTokensFromDoubleQuotedTokensEnd = -1;     # SNOOPYJC
   $ExtractingTokensFromDoubleQuotedStringEnd = 0;      # SNOOPYJC
   $ExtractingTokensFromDoubleQuotedStringTnoStart = -1; # SNOOPYJC
   $ate_dollar = -1;                                    # issue 50
   my $end_br;                  # issue 43
   
   #if( $::debug > 3 && $main::breakpoint >= $.  ){
   #$DB::single = 1;
   #}
   while( defined $source && $source ne ''){    # issue s13
      $had_space = (substr($source,0,1) =~ /\s/);   # issue 50
      ($source)=split(' ',$source,1);  # truncate white space on the left (Perl treats ' ' like AWK. )
      last if(!defined $source || $source eq '');             # SNOOPYJC, issue s13
      $s=substr($source,0,1);
      if(exists $line_substitutions{$.}) {              # SNOOPYJC: Used to handle do{...}if{...};
          while(my ($pattern, $substitution) = each(%{$line_substitutions{$.}})) {
              say STDERR "Applying s/$pattern/$substitution/  on   $source" if($::debug >= 3);
              $source =~ s/$pattern/$substitution/;
              say STDERR "Applied  s/$pattern/$substitution/ gives $source" if($::debug >= 3);
          }
      }
      if($tno != 0 && $ValClass[$tno-1] eq 'i' && $ValPerl[$tno-1] =~ /^v\d/ &&
          $s ne '}' && $source !~ m'=>') {           # SNOOPYJC: Handle 'vNN' after the fact, making sure it's not a hash key
          $ValClass[$tno-1] = '"';
          $ValPy[$tno-1] = interpolate_string_hex_escapes(sprintf('\'\\x{%x}\'', int(substr($ValPy[$tno-1],1))));
      }
      if( $s eq '#'  ){
         # plain vanilla tail comment
         if( $tno > 0  ){
             # issue 82 $tno--;
             # issue 82 $ValCom[$tno]=$source;
            $ValCom[$tno-1]=$source;                    # issue 82
         }else{
             Pythonizer::output_line('',$source); # to block reproducing the first source line
         }
         my @tmpBuffer = @BufferValClass;	# SNOOPYJC: Must get a real line even if we're buffering stuff
         @BufferValClass = ();		        # SNOOPYJC
         $source=Pythonizer::getline();
         @BufferValClass = @tmpBuffer;	# SNOOPYJC
	 # SNOOPYJC last if( $source=~/^\s*[;{}]\s*(#.*)?$/); # single closing statement symnol on the line.
         next;
      }elsif( $s eq ';' ){
         #
         # buffering tail is possible only if banace of round bracket is zero
         # because of for($i=0; $i<@x; $i++)
         #
         $balance=0;
         for ($i=0;$i<@ValClass;$i++ ){
            if( $ValClass[$i] eq '(' ){
               $balance++;
            }elsif( $ValClass[$i] eq ')' ){
               $balance--;
            }
         }
         {
          no warnings 'uninitialized';
          say STDERR "Perlscan got ; balance=$balance, tno=$tno, nesting_last=$nesting_last" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
         }
         if( $balance != 0  ){
            # for statement or similar situation
            $ValClass[$tno]=$ValPerl[$tno]=$s;
            $ValPy[$tno]=',';
            $cut=1; # we need to continue

         }else{
            # this is regular end of statement
            if( $tno>0 && $ValPerl[0] eq 'sub' ){
               $ValPy[0]='#NoTrans!'; # this is a subroutne prototype, ignore it.
            } elsif($tno == 0 && defined $nesting_last && $nesting_last->{type} eq 'do') { # SNOOPYC
               # if this is a do{...}; we will generate an infinite loop unless we add a False condition here!
               $ValClass[$tno]='c'; $ValPy[$tno]=$ValPerl[$tno]='while'; $tno++;
               $ValClass[$tno]=$ValPy[$tno]=$ValPerl[$tno]='('; $tno++;
               $ValClass[$tno]='d'; $ValPy[$tno]='False'; $ValPerl[$tno]='0'; $tno++;
               $ValClass[$tno]=$ValPy[$tno]=$ValPerl[$tno]=')'; $tno++;
            }
            # issue 86 if( $delayed_block_closure ){
            while( $delayed_block_closure ){
               Pythonizer::getline('}');
               # issue 86 $delayed_block_closure=0;
               $delayed_block_closure--;        # issue 86
            }
            last if( length($source) == 1); # we got full statement; semicolon needs to be ignored.
            last if( substr($source,1) =~ /^\s*$/);     # SNOOPYJC: Ignore trailing spaces
            if( $source !~/^;\s*#/  ){
               # there is some meaningful tail -- multiple statement on the line
               Pythonizer::getline(substr($source,1)); # save tail that we be processed as the next line.
               last;
            }else{
               # comment after ; this is end of statement
               if( $tno==0 ){
                  Pythonizer::getline(substr($source,1)); # save tail that we be processed as the next line.
               }else{
                 $ValCom[$tno-1]=substr($source,1); # comment attributed to the last token
               }
               last; # we got full statement for analysis
            }
         }
     }
      # This is a meaningful symbol which tranlates into some token.
      $ValClass[$tno]=$ValPerl[$tno]=$ValPy[$tno]=$s;
      $ValCom[$tno]='';
      if(index('$@%&*', $s) >= 0 && substr($source,1,1) eq '{' &&
         length($source) >= 4 &&
         index('$@%&*"\'', substr($source,2,1)) < 0) {     # issue 43 - Look for ${...} and delete the brackets
         #-> THIS BREAKS issue 43:  !exists $SPECIAL_VAR{substr($source,2,1)}) {     # issue 43 - Look for ${...} and delete the brackets
                                                        # Don't do this on @{$...}, ${"..."}, etc
         $end_br = matching_curly_br($source, 1);       # issue 43
         if($end_br > 0) {                              # issue 43
            if(index(substr($source,0,$end_br), '(') < 0) {    # issue 43: Don't do this on @{myFunc()}
               substr($source,$end_br,1) = '';          # issue 43
               substr($source,1,1) = '';                # issue 43
            }
         }                                              # issue 43
      }
      if( $s eq '}' ){
         # we treat '}' as a separate "dummy" statement -- eauvant to ';' plus change of nest -- Aug 7, 2020
         #say STDERR "Got }, tno=$tno, source=$source";
         if( $tno==0  ){
              # we recognize it as the end of the block if '}' is the first symbol
             if( length($source)>=1 ){
                exit_block();                 # issue 94
                Pythonizer::getline(substr($source,1)); # save tail
                $source=$s; # this was we artifically create line with one symbol on it;
             }
             last; # we need to process it as a seperate one-symbol line
         }elsif( $tno>0 && (length($source)==1 || $source =~ /^}\s*$/ ||	# issue ddts: Handle spaces at end
                 $source =~ /^}\s*#/ || 
		 could_be_anonymous_sub_close() ||              # SNOOPYJC
                 $source =~ /^}\s*(?:(?:(?:else|elsif|while|until|continue|)\b)|;)/)){    # issue 45, issue 95
             # NOTE: here $tno>0 and we reached the last symbol of the line
             # we recognize it as the end of the block
             #curvy bracket as the last symbol of the line
             
             # issue 85 - recognize a couple of different cases and handle them properly.
             # Case 1: sub abc { ... }  <- need to recognize end of block
             # Case 2: $i = $h{v}       <- need to NOT recognize end of block
             #say STDERR "Got }, tno=$tno, ValClass=@ValClass, source=$source";
             # The way we tell is to look at the tokens and if there are unbalanced (), then this is NOT a block end
             
             if(parens_are_balanced()) {                # issue 85: Note: this '}' is NOT considered to be a ')'
                #say STDERR "parens_are_balanced";
                # issue 45 Pythonizer::getline('}'); # make it a separate statement
                #exit_block();                 # issue 94
                Pythonizer::getline($source); # make it a separate statement # issue 45
                popup(); # kill the last symbol
                last; # we truncate '}' and will process it as the next line
             }
             #say STDERR "parens_are_NOT_balanced";
         }
         # this is closing bracket of hash element
	 if( $tno > 2 && $ValClass[$tno-1] eq 'i' and $ValPerl[$tno-2] eq '{' ) {	# issue 13
	    $ValPy[$tno-1] = "'".$ValPy[$tno-1]."'";					# issue 13: quote bare word
            $ValClass[$tno-1]='"';							# issue 13
	 }										# issue 13
         $ValClass[$tno]=')';
         $ValPy[$tno]=']';
         $cut=1;
         # SNOOPYJC: If this is a hashref { x => y, ... }, then change the brackets from '[]' to '{}'
         $TokenStr = join('',@ValClass);
         my $sbr = &Pythonizer::reverse_matching_br($tno);
         if($sbr != -1) {
             if(&Pythonizer::next_same_level_token('A', $sbr+1, $tno-1) != -1) {
                 $ValPy[$tno]='}';
                 $ValPy[$sbr]='{';
             }
         }
      }elsif( $s eq '{' || ($s eq '^' && $tno==0) ){    # SNOOPYJC
          #say STDERR "got {, tno=$tno, source=$source, ValPerl=@ValPerl";
         # we treat '{' as the beginning of the block if it is the first or the last symbol on the line or is preceeded by ')' -- Aug 7, 2020
          if( $tno==0 ){
             if($s eq '{') {    # SNOOPYJC: We swap '{' for '^' the second time around so we know if we need to call enter_block
                enter_block();                 # issue 94
             } else {
                $ValClass[$tno]=$ValPerl[$tno]=$ValPy[$tno]='{';
             }
             if( length($source)>1  ){
                Pythonizer::getline(substr($source,1)); # save tail
             }
             last; # artificially truncating the line making it one-symbol line
             # issue 82 }elsif( length($source)==1 ){
          } elsif($tno == 2 && $ValClass[0] eq 'k' && $ValClass[1] eq 'i' &&    # SNOOPYJC
              $ValPerl[0] eq 'use' && ($ValPerl[1] eq 'constant' || $ValPerl[1] eq 'overload')) {       # issue s3
              ;
          }elsif( (length($source)==1 || $source =~ /^{\s*#/) && $ValClass[$tno-1] ne '=' && $ValClass[$tno-1] ne 'f' && # issue 82, issue 60 (map/grep)
                  $ValClass[$tno-1] ne 's' &&                   # SNOOPYJC: $var\n with '{' on next line
                  $ValClass[$tno-1] ne '(' && $ValClass[$tno-1] ne ',') {       # SNOOPYJC
             # $tno>0 but line may came from buffer.
             # We recognize end of statemt only if previous token eq ')' to avod collision with #h{$s}
             enter_block() if($s eq '{');                 # issue 94
             # SNOOPYJC Pythonizer::getline('{'); # make $tno==0 on the next iteration
             Pythonizer::getline('^'); # SNOOPYJC: make $tno==0 on the next iteration
             popup(); # eliminate '{' as it does not have tno==0
             last;
	  # issue 35 }elsif( $ValClass[$tno-1] eq ')' || $source=~/^.\s*#/ || index($source,'}',1) == -1){
          }elsif( $ValClass[$tno-1] ne '=' &&                   # issue 82
                  $ValClass[$tno-1] ne 'f' &&                   # issue 60 (map/grep)
                  $ValClass[$tno-1] ne 'A' &&                   # SNOOPYJC: key=>{ is not a new block
                  $ValClass[$tno-1] ne '(' && $ValClass[$tno-1] ne ',' &&       # SNOOPYJC
                  $ValClass[$tno-1] ne 's' &&                   # SNOOPYJC: $var{'...'\n with } on the next line!
                 ($ValPerl[$tno-1] eq ')' || $source=~/^.\s*#/ || index($source,'}',1) == -1 || 
                  ($tno == 1 && $ValClass[0] eq 'C')||  # SNOOPYJC: do {...} until(...); else {...}; elsif {...}; eval {...};
                  ($tno == 2 && $ValPerl[0] eq 'sub') ||
                  $ValPerl[$tno-1] eq 'sub' ||          # issue 81
                  ($tno == 1 && $ValPerl[0] =~ /BEGIN|END|UNITCHECK|CHECK|INIT/))){	# issue 35, 45
             # $tno>0 this is the case when curvy bracket has comments'
             enter_block() if($s eq '{');                 # issue 94
             # SNOOPYJC Pythonizer::getline('{',substr($source,1)); # make it a new line to be proceeed later
	     # issue 42 Pythonizer::getline('^',substr($source,1)); # SNOOPYJC: make it a new line to be proceeed later
             Pythonizer::getline('^');			# issue 42: Send 1 line at a time
	     Pythonizer::getline(substr($source,1));    # SNOOPYJC: make it a new line to be proceeed later
             popup(); # eliminate '{' as it does not have tno==0
             last;
          }elsif($ValClass[$tno-1] eq 'D') {	# issue 50, issue 93
	    popup();                            # issue 50, 37
            $TokenStr=join('',@ValClass);       # issue 50
	    $tno--;				# issue 50 - no need to keep arrow operator in python
      	    $ValPerl[$tno]=$ValPy[$tno]=$s;	# issue 50
          }
         $ValClass[$tno]='('; # we treat anything inside curvy backets as expression
         $ValPy[$tno]='[';
         $cut=1;
      # issue 17 }elsif( $s eq '/' && ( $tno==0 || $ValClass[$tno-1] =~/[~\(,k]/ || $ValPerl[$tno-1] eq 'split') ){
      }elsif( $s eq '/' && ( $tno==0 || $ValClass[$tno-1] =~/[~\(,kc=o0!>]/ || $ValPerl[$tno-1] eq 'split' ||   # issue ddts: add '>' to list
          $ValPerl[$tno-1] eq 'grep' || $ValClass[$tno-1] eq 'r') ){	# issue 17, 32, 66, 60, range
           # typical cases: if(/abc/ ){0}; $a=~/abc/; /abc/; split(/,/,$text)  split /,/,$text REALLY CRAZY STAFF
           $ValClass[$tno]='q';
           $cut=single_quoted_literal($s,1);
           # issue 51 $ValPerl[$tno]=substr($source,1,$cut-2);
           $original_regex = substr($source,1,$cut-2);                          # issue 111
           $ValPerl[$tno]=remove_escaped_delimiters($s, $original_regex);       # issue 51, issue 111
           substr($source,0,$cut)=''; # you need to provide modifiers to perl_match
           $cut=0;
           if( $tno>=1 && ( ($ValClass[$tno-2] eq 'f' && $ValPerl[$tno-2] !~ /^(?:chomp|chop|chr|shift)$/)      # issue 99: not a function that takes no args
                            || $ValPerl[$tno-1] eq 'split') ){
              # in split regex should be plain vanilla -- no re.match is needed.
              $ValPy[$tno]=put_regex_in_quotes( $ValPerl[$tno], '/', $original_regex); # double quotes neeed to be escaped just in case, issue 111
           }else{
              $ValPy[$tno]=perl_match($ValPerl[$tno], '/', $original_regex); # there can be modifiers after the literal., issue 111
           }
      }elsif( $s eq "'"  ){
         #simple string, but backslashes of  are allowed
         $ValClass[$tno]='"';
         $cut=single_quoted_literal($s,1);
         $ValPerl[$tno]=substr($source,1,$cut-2);
         # issue 51 - we leave the \' in place because we use a single quote deliminator below
         # NO GOOD!!  $ValPerl[$tno]=remove_escaped_delimiters($s, substr($source,1,$cut-2));       # issue 51
         if( ($tno>0 && $ValPerl[$tno-1] eq '<<') ||
             ($tno>1 && $ValPerl[$tno-1] eq '~' && $ValPerl[$tno-2] eq '<<')  ){
            # my $here_str = <<'END'; -- added Dec 20, 2019
            my $has_squiggle = ($ValPerl[$tno-1] eq '~');
            $tno--; # overwrite previous token; Dec 20, 2019 --NNB
            $tno-- if($has_squiggle);
	    # issue 39 $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno]);
	    $ValClass[$tno]='"';
            $ValPerl[$tno]=substr($source,1,$cut-2);
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);	# issue 39
	    popup();                            # issue 39
            popup() if($has_squiggle);
            # issue 39 $cut=length($source);
	 }elsif(index($ValPerl[$tno], "\n") >= 0) {		# issue 39 - multi-line string
            $ValPy[$tno]="'''".escape_non_printables(escape_backslash($ValPerl[$tno], "'"),0)."'''"; # only \n \t \r, etc needs to be  escaped # issue 39
         }else{
            $ValPy[$tno]="'".escape_non_printables(escape_backslash($ValPerl[$tno], "'"),0)."'"; # only \n \t \r, etc needs to be  escaped
         }
         $ValPy[$tno] = replace_usage($ValPy[$tno]) if($::replace_usage);
         #say STDERR "Simple String: ValPerl=$ValPerl[$tno], ValPy=$ValPy[$tno]";
      }elsif( $s eq '"'  ){
         $ValClass[$tno]='"';
         $cut=double_quoted_literal('"',1); # side affect populates $ValPy[$tno] and $ValPerl[$tno]
         if( ($tno>0 && $ValPerl[$tno-1] eq '<<') ||
             ($tno>1 && $ValPerl[$tno-1] eq '~' && $ValPerl[$tno-2] eq '<<')  ){
            # my $here_str = <<'END'; -- added Dec 20, 2019
            my $has_squiggle = ($ValPerl[$tno-1] eq '~');
            $tno--; # overwrite previous token; Dec 20, 2019 --NNB
            $tno-- if($has_squiggle);
	    # issue 39 $ValClass[$tno]="'";
            $ValClass[$tno]='"';		# issue 39
            $ValPerl[$tno]=substr($source,1,$cut-2);
	    # issue 39 $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno]);
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);	# issue 39
            my $quote = substr($ValPy[$tno],3,length($ValPy[$tno])-6);  # issue 39: remove the """ and """
            interpolate_strings($quote, $quote, 0, 0, 0);     # issue 39
            popup();                            # issue 39
            popup() if($has_squiggle);
	    $TokenStr=join('',@ValClass);       # issue 39
	    # issue 39 $cut=length($source);
	 }elsif(index($ValPy[$tno], "\n") >= 0 && substr($ValPy[$tno],0,1) eq 'f' && $ValPy[$tno] !~ /^f"""/) {	# issue 39 - multi-line string
            $ValPy[$tno] =~ s/^f"/f"""/;			# issue 39
	    $ValPy[$tno] .= '""';				# issue 39
         }
         $ValPy[$tno] = replace_usage($ValPy[$tno]) if($::replace_usage);
         $ValPerl[$tno]=substr($source,1,$cut-2);
      }elsif( $s eq '`'  ){
          $ValClass[$tno]='x';
          $cut=double_quoted_literal('`',1);
          $ValPy[$tno]=$ValPy[$tno];
      }elsif( $s=~/\d/  ){
         # processing of digits should preceed \w ad \w includes digits
	 # issue 23 if( $source=~/(^\d+(?:[.e]\d+)?)/  ){
         if( $source=~/^(0x\w+)/  ){
            # need to add octal andhexadecila later
            $val=$1;
            #$ValType[$tno]='x';
         }elsif( $source=~/(0b\d+)/  ){
            #binary
            $val=$1;
            #$ValType[$tno]='b';
         }elsif( $source=~/(^\d+(?:[_]\d+)*(?:[.]\d*(?:[_]\d+)*)?(?:[Ee][+-]?\d+(?:[_]\d+)*)?)/  ){	# issue 23, SNOOPYJC: Handle '_'
             $val=$1;
             if(substr($val,-1,1) eq '.' && substr($source,length($val),1) eq '.') { # issue range: change 0.. to 0
                 substr($val, -1, 1) = '';              # issue range
             }                                          # issue range
             #$ValType[$tno]='e';
         }elsif(  $source=~/(\d+)/  ){
             $val=$1;
             #$ValType[$tno]='i';
         }
         $ValClass[$tno]='d';
         $ValPy[$tno]=$ValPerl[$tno]=$val;
         $cut=length($val);
	 if($cut > 1 && substr($ValPy[$tno], 0, 1) eq '0' && $ValPy[$tno] !~ /[.exb]/) {   # issue 22
            $ValPy[$tno] = "0o".substr($ValPy[$tno], 1);	# issue 22
	 }							# issue 22
     }elsif( $s=~/\w/  ){
         # SNOOPYJC var $source=~/^(\w+(\:\:\w+)*)/;
         $source=~/^(\w+((?:(?:\:\:)|\')\w+)*)/;         # SNOOPYJC: Old perl used ' in a name instead of ::
         $w=$1;
         $cut=length($w);
         if($tno == 0 && $w eq 'END') {         # SNOOPYJC: END block
             $ValClass[$tno]='k';
             $ValPerl[$tno]='sub';
             $ValPy[$tno]='def';
             $ValCom[$tno]='';
             $tno++;
             $w = "__END__$.";                  # SNOOPYJC: Special name checked in pythonizer
             push @EndBlocks, $w if($Pythonizer::PassNo == &Pythonizer::PASS_1);         # SNOOPYJC
         }
         my $pq;
         if(($pq = index($w, "'")) > 0 && exists $TokenType{substr($w,0,$pq)} &&
             $TokenType{substr($w,0,$pq)} eq 'q') {     # SNOOPYJC: qq'...' or qw'...' or q'...' etc
             $w = substr($w,0,$pq);
             $cut=length($w);
         }
         $ValPerl[$tno]=$w;
         $ValClass[$tno]='i';
         $ValPy[$tno]=$w;
         if($tno != 0 && ($ValClass[$tno-1] eq 'k' && $ValPerl[$tno-1] eq 'sub') ||
             ($ValClass[$tno-1] eq 'f' && ($ValPerl[$tno-1] =~ m'^(?:opendir|open|closedir|close|printf|print|say|readdir|telldir|rewinddir|sysread|sysseek|syswrite|seek|tell|read|binmode|write)$')) ||
             ($tno-2>=0 && $ValClass[$tno-1] eq '(' && $ValClass[$tno-2] eq 'f' &&
                ($ValPerl[$tno-2] =~ m'^(?:opendir|open|closedir|close|printf|print|say|readdir|telldir|rewinddir|sysread|sysseek|syswrite|seek|tell|read|binmode|write)$'))) {       # issue 92
            my $sigil = '';
            $sigil = '&' if($ValPerl[$tno-1] eq 'sub');   # issue 92, 108: Differentiate between sub and FH
	    $FileHandles{$w} = $. if($sigil eq '' && 
                                     !exists $keyword_tr{$w} && 
                                     substr($source,$cut) !~ /\s*\(/ &&         # issue ddtr: print mysub() - mysub is not a FH!
                                     !exists $FileHandles{$w});  # skip STDIN and friends
            remap_conflicting_names($w, $sigil, '');      # issue 92: sub takes the name from other vars
         }
         $ValPy[$tno]=~tr/:/./s;                # SNOOPYJC
         $ValPy[$tno]=~tr/'/./s;                # SNOOPYJC
         $ValCom[$tno]='';                      # SNOOPYJC
         my $core = 0;                          # SNOOPYJC
         if(substr($w,0,5) eq "CORE'") {        # SNOOPYJC
             $w = substr($w,5);
             $core = 1;
         } elsif(substr($w,0,6) eq 'CORE::') {  # SNOOPYJC
             $w = substr($w,6);
             $core = 1;
         }
         if(substr($w,0,5) eq "Carp'" && $w =~ /carp|confess|croak|cluck/) {    # SNOOPYJC
             $w = substr($w,5);
         } elsif(substr($w,0,6) eq 'Carp::' && $w =~ /carp|confess|croak|cluck/) {      # SNOOPYJC
             $w = substr($w,6);
         }
         if( exists($keyword_tr{$w}) ){
            $ValPy[$tno]=$keyword_tr{$w};
         }
         if( exists($CONSTANT_MAP{$w}) ) {      # SNOOPYJC
             $ValPy[$tno] = $CONSTANT_MAP{$w};  # SNOOPYJC
         }                                      # SNOOPYJC
	 if($Pythonizer::PassNo!=&Pythonizer::PASS_0 && exists $FileHandles{$w}) {		# SNOOPYJC
             if($tno == 0 || $ValClass[$tno-1] ne 'k' || $ValPerl[$tno-1] ne 'sub') {	# SNOOPYJC
	         add_package_name_fh($tno);	# SNOOPYJC
	     }					# SNOOPYJC
	 }					# SNOOPYJC
         if( exists($TokenType{$w}) ){
            $class=$TokenType{$w};
            if($class eq 'f' && !$core && exists $Pythonizer::UseSub{$w}) {     # SNOOPYJC
                $class = 'i';
                $ValPy[$tno] = $w;
            } elsif($class eq 'q' && $tno != 0 && $ValClass[$tno-1] eq 'q') {   # issue 120: flags!
                $class = 'i';
                $ValPy[$tno] = $w;
            } elsif($class eq '"' && $w eq '__PACKAGE__') {             # issue s3
                $ValPy[$tno] = "'" . escape_keywords(cur_package(), 1) . "'";
            }
            if($tno != 0 && (($ValPerl[$tno-1] eq '{' && $source =~ /^[a-z0-9]+}/) ||   # issue 89: keyword in a hash like $hash{delete} or $hash{q}
                (index('{(,', $ValPerl[$tno-1])>=0 && $source =~ /^[a-z0-9]+\s*=>/))) {  # issue 89: keyword in hash def like (qw=>14, use=>15)
                $class = 'i';                   # issue 89
                $ValPy[$tno] = $w;              # issue 89
            } elsif($tno == 2 && $ValClass[0] eq 'G' && $ValClass[1] eq '=' && $class eq 'k' &&
                    $w eq 'sub') {                    # SNOOPYJC: *GLOB = sub {...} - change to sub GLOB {...}
                $TokenStr = join('',@ValClass);                # replace doesn't work w/o $TokenStr
                my $subname = $ValPy[0];
                my $pd = rindex($ValPy[0], '.');
                $subname = substr($subname, $pd+1) if($pd >= 0);        # Remove package name
                replace(1, 'i', substr($ValPerl[0],1), $subname);       # Change the = to the subname (eat the '*')
                replace(0, $class, $ValPerl[$tno], $ValPy[$tno]);      # Start with the sub
                popup();                                       # Eat the extra 'sub'
                remap_conflicting_names($ValPerl[1], '&', '');      # issue 92: sub takes the name from other vars
                $class = 'i';
                $tno--;
                $Pythonizer::LocalSub{$ValPy[$tno]} = 1;
                $Pythonizer::LocalSub{cur_package() . '.' . $ValPy[$tno]} = 1;          # issue s3
            } elsif($tno != 0 && ($ValClass[$tno-1] eq 'D' || 
                ($ValClass[$tno-1] eq 'c' && $ValPerl[$tno-1] eq 'package') ||  # SNOOPYJC: package name
                ($ValClass[$tno-1] eq 'k' && $ValPerl[$tno-1] eq 'require' && $class ne 'q') || # SNOOPYJC: Allow require q(...)
                ($ValClass[$tno-1] eq 'k' && $ValPerl[$tno-1] =~ /^(?:sub|use|no)$/))) {    # SNOOPYJC: Part of an OO method ref or sub def - change this to an 'i' class
                $class = 'i';
                $ValPy[$tno] = $w;
            } elsif($class eq 'f' && $w eq 'pos') {     # SNOOPYJC: implement 'pos'
                my $cs = cur_sub();
                $SpecialVarsUsed{'@-'}{$cs} = 1;
                $SpecialVarsUsed{'pos'}{$cs} = 1;
            } elsif($class eq 'f' && $w eq 'bless') {   # issue s3
                my $cs = cur_sub();
                $SpecialVarsUsed{'bless'}{$cs} = 1;
                $Pythonizer::SubAttributes{$cs}{blesses} = 1;
                $SpecialVarsUsed{'bless'}{cur_package()} = 1;
            # issue s3 } elsif($class eq 'd' && $w eq 'wantarray' && $Pythonizer::PassNo == &Pythonizer::PASS_2) {   # SNOOPYJC: give warning
            } elsif($class eq 'd' && $w eq 'wantarray') {   # issue s3
                my $cs = cur_sub();
                # issue s3 logme('W',"'wantarray' reference in $cs is hard wired to $ValPy[$tno]");
                $SpecialVarsUsed{'wantarray'}{$cs} = 1;         # issue s3
                $Pythonizer::SubAttributes{$cs}{wantarray} = 1; # issue s3
            }                                   # issue 89
            $ValClass[$tno]=$class;
            if( $class eq 'c' && $tno > 0 && $w ne 'assert' && $Pythonizer::PassNo == &Pythonizer::PASS_1 && ($ValClass[0] ne 'C' || $ValPerl[0] ne 'do')){ # issue 116: Control statement, like if and do
                $line_contains_stmt_modifier{$statement_starting_lno} = 1;      # issue 116: Remember for PASS_2
            }
                
            if( $class eq 'c' && $tno > 0 && $w ne 'assert' && $Pythonizer::PassNo == &Pythonizer::PASS_2 && ($ValClass[0] ne 'C' || $ValPerl[0] ne 'do')){ # Control statement, like if # SNOOPYJC: and do
               # The current solution is pretty britle but works
               # You can't recreate Perl source from ValPerl as it does not have 100% correspondence.
               # So the token buffer implemented Oct 08, 2020 --NNB
               # Note you can't use both getline buffer and token buffer, so you can't add '{' to the end of if statement
               # You need to jump thoou the hoops in Pythonizer to inject '{' and '}' into the stream
               #
               # Issue 108: If we have a conditional "local" statement, we need to do the init of
               # the typeglob locals here since we won't generate the code inside the new 'if' block we 
               # are making because we won't be able to find the variables in the new line number.
               #
               if($ValClass[0] eq 't' && $ValPerl[0] eq 'local') {      # issue 108
                  init_local_typeglobs($::CurSub);                      # issue 108
               }
               pop(@ValClass); pop(@ValCom); pop(@ValPerl); pop(@ValPy);
               # issue 37 - we don't pop ValType since we haven't set it
               @BufferValClass=@ValClass; @BufferValCom=@ValCom; @BufferValPerl=@ValPerl; @BufferValPy=@ValPy;
	       @BufferValType=@ValType;	# issue 37
               @ValClass=@ValCom=@ValPerl=@ValPy=();
	       @ValType=();	# issue 37
               $tno=0;
               $ValClass[$tno]=$class;
               $TokenStr = $class;      # issue 37
               $ValPy[$tno]=$w;
               if( exists($keyword_tr{$w}) ){
                  $ValPy[$tno]=$keyword_tr{$w};
               }
               $ValPerl[$tno]=$w;
               $ValType[$tno]='P';
            } elsif($class eq 'c' && $Pythonizer::PassNo == &Pythonizer::PASS_1 && ($w eq 'if' || $w eq 'unless') &&          # SNOOPYJC
                    defined $nesting_last && $nesting_last->{type} eq 'do') {
                # We can't do our normal trick to handle STMT if COND; for a do{...} if COND; because 
                # it's more than one statement, so instead we use another trick and rememeber a regex in the
                # first pass that we apply to the 'do' statement to change it into an if/unless statement
                $source =~ /^(\w+)(.*?);/;    # Grab everything up to but not including the ';'
                my $condition_expr = $2;
                my $condition = $1 . $condition_expr;
                $condition = $1 . '(' . $condition_expr . ')' if(substr($condition_expr,-1,0) ne ')');
                $do_lno = $nesting_last->{lno};
                $line_substitutions{$do_lno}{'\bdo\b'} = $condition;
                $line_substitutions{$.}{'}\s*'.$w.'.*?;'} = '}';
            } elsif($class eq 'C' && $Pythonizer::PassNo == &Pythonizer::PASS_1 && $w eq 'continue') {        # SNOOPYJC
                track_continue($tno);
            } elsif($class eq 'k' && $Pythonizer::PassNo == &Pythonizer::PASS_1 && $w eq 'next') {            # SNOOPYJC
                flag_next_in_continue($tno);
#           } elsif( $class eq 'k' && $w eq 'sub' && $tno > 0 && $Pythonizer::PassNo ){	# issue 81: anonymous sub
#               $ValClass[$tno] = 'i';
#               $ValPy[$tno] = $ValPerl[$tno] = "$ANONYMOUS_SUB$.";
#               #$Pythonizer::LocalSub{$ValPerl[$tno]} = 1;
#               @BufferValClass=@ValClass; @BufferValCom=@ValCom; @BufferValPerl=@ValPerl; @BufferValPy=@ValPy;
#	       @BufferValType=@ValType;	# issue 37
#               @ValClass=@ValCom=@ValPerl=@ValPy=();
#	       @ValType=();	# issue 37
#               $tno=0;
#               $ValClass[$tno]=$class;
#               $TokenStr = $class;      # issue 37
#               $ValPy[$tno]=$w;
#               $ValPerl[$tno]=$w;
#               $tno++;
#               $ValClass[$tno] = 'i';
#               $ValPy[$tno] = $ValPerl[$tno] = "$ANONYMOUS_SUB$.";
#               #$ValType[$tno]='P';
            }elsif ( $class eq 'o' ){	# and/or   # issue 93
                  $balance=(join('',@ValClass)=~tr/()//);
                  # issue 93 if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && join('',@ValClass) !~ /^t?[ahs]=/ ){
                  if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && bash_style_or_and_fix($cut)){             # issue 93
                     # postfix conditional statement, like ($debug>0) && ( line eq ''); Aug 10, 2020,Oct 12, 2020 --NNB
                     # issue 93 bash_style_or_and_fix($cut);
                     # issue 93 last;
                     last;              # issue 93
                  }
            }elsif ( $class eq 't'  ){
               if( $tno>0 && $w eq 'my' && $Pythonizer::PassNo == &Pythonizer::PASS_2){        # SNOOPYJC: In the first pass, we need to see the 'my' so we don't make $i global!
                  $source=substr($source,2); # cut my in constucts like for(my $i=0...)
                  next;
               }
            }elsif( $class eq 'q' ){
               # q can be translated into """", but qw actually is an expression
               # issue 69 $delim=substr($source,length($w),1);
               if(($delim=substr($source,length($w),1)) =~ /\s/) {     # issue 69 - handle whitespace after the initial q
                   substr($source,length($w),1) = '';                   # issue 69 - eat whitespace
                   next;                                                # issue 69 - start over
               }
               if($delim eq '' || ($delim eq ';' && length($source)==length($w)+1)) {       # SNOOPYJC: Ran out of road - not a 'q' - make it an 'i' instead
                   $ValClass[$tno]='i';
                   $ValPerl[$tno]=$ValPy[$tno]=$w;
                   $cut = length($w);
               } elsif( $w eq 'q' ){
                  $cut=single_quoted_literal($delim,2);
                  if( $cut== -1 ){
                     $Pythonizer::TrStatus=-255;
                     last;
                  }
                  # issue 51 $ValPerl[$tno]=substr($source,length($w)+1,$cut-length($w)-2);
                  #say STDERR "after single_quoted_literal, cut=$cut, length(\$w)=".length($w).", length(\$source)=".length($source);
                  $ValPerl[$tno]=remove_escaped_delimiters($delim, substr($source,length($w)+1,$cut-length($w)-2));      # issue 51
                  $w=escape_backslash($ValPerl[$tno], $delim);  # SNOOPYJC: pass the delim
                  $ValPy[$tno]=escape_quotes(escape_non_printables($w,0),2);      # SNOOPYJC
                  $ValClass[$tno]='"';
                  $ValPy[$tno] = replace_usage($ValPy[$tno]) if($::replace_usage);
               }elsif( $w eq 'qq' ){
                  # decompose doublke quote populate $ValPy[$tno] as a side effect
                  $cut=double_quoted_literal($delim,length($w)+1); # side affect populates $ValPy[$tno] and $ValPerl[$tno]
                  $ValClass[$tno]='"';
	 	  if(index($ValPy[$tno], "\n") >= 0 && substr($ValPy[$tno],0,1) eq 'f' && $ValPy[$tno] !~ /^f"""/) { # issue 39 - multi-line string
            	      $ValPy[$tno] =~ s/^f"/f"""/;		# issue 39
	    	      $ValPy[$tno] .= '""';			# issue 39
		   }						# issue 39
                   $ValPy[$tno] = replace_usage($ValPy[$tno]) if($::replace_usage);
               }elsif( $w eq 'qx' ){
                  #executable, needs interpolation
                  $cut=double_quoted_literal($delim,length($w)+1);
                  $ValPy[$tno]=$ValPy[$tno];
                  $ValClass[$tno]='x';
               }elsif( $w eq 'm' || $w eq 'qr' || $w eq 's' ){  # issue bootstrap - change to "||"
                  $source=substr($source,length($w)+1); # cut the word and delimiter
                  $cut=single_quoted_literal($delim,0); # regex always ends before the delimiter
                  # issue 51 $arg1=substr($source,0,$cut-1);
                  $original_regex = substr($source,0,$cut-1);                            # issue 111
                  $arg1=remove_escaped_delimiters($delim, $original_regex);     # issue 51, issue 111
                  $source=substr($source,$cut); #cut to symbol after the delimiter
                  $cut=0;
                  if( $w eq 'm' || ($w eq 'qr' &&  $ValClass[$tno-1] eq '~') ){
                     $ValClass[$tno]='q';
                     $ValPy[$tno]=perl_match($arg1, $delim, $original_regex); # it calls is_regex internally, issue 111
                  }elsif( $w eq 'qr' && $tno>=2 && $ValClass[$tno-1] eq '(' && $ValPerl[$tno-2] eq 'split' ){
                      # in split regex should be  plain vanilla -- no re.match is needed.
                      $ValPy[$tno]='r'.$quoted_regex; #  double quotes neeed to be escaped just in case
                  }elsif( $w eq 's' ){
                     $ValPerl[$tno]='re';
                     $ValClass[$tno]='f';
                     # processing second part of 's'
                     # issue 113 if( $delim=~tr/{([<'/{([<'/ ){
                     if( $delim=~tr/{([</{([</ ){               # issue 113
                        # case tr[abc][cde]
                        $delim=substr($source,0,1); # new delimiter can be different from the old, althouth this is raraly used in Perl.
                        # SNOOPYJC $source=substr($source,1,0); # remove delimiter
                        if($delim eq '') {
	                    # issue 39: if we get here, we ran out of road - grab the next line and keep going!
                            my @tmpBuffer = @BufferValClass;	# SNOOPYJC: Must get a real line even if we're buffering stuff
                            @BufferValClass = ();		        # SNOOPYJC
	                    $line = Pythonizer::getline();		# issue 39
                            @BufferValClass = @tmpBuffer;	# SNOOPYJC
                            $line =~ s/^\s*//;                  # SNOOPYJC
                            $source .= $line;
                            $delim=substr($source,0,1);
                        }
                        substr($source,0,1) = ''; # SNOOPYJC: remove delimiter
                     }
                     # now string is  /def/d or [def]
                     $cut=single_quoted_literal($delim,0);
                     # issue 51 $arg2=substr($source,0,$cut-1);
                     $original_regex2 = substr($source,0,$cut-1);                            # issue 111
                     $arg2=remove_escaped_delimiters($delim, $original_regex2);          # issue 51, issue 111
                     $source=substr($source,$cut);
                     $cut=0;
                     ($modifier,undef)=is_regex($arg2); # modifies $source as a side effect
                     if( length($modifier) > 1 ){
                        #regex with modifiers
                         $quoted_regex='re.compile('.put_regex_in_quotes($arg1, $delim, $original_regex)."$modifier)";   # issue 111
                     }else{
                        # No modifier
                        $quoted_regex=put_regex_in_quotes($arg1, $delim, $original_regex);       # issue 111
                     }
                     if( length($modifier)>0 ){
                        #this is regex
                        if( $tno>=1 && $ValClass[$tno-1] eq '~'   ){
                           # explisit s
                            if(index($modifier, 're.E') >= 0) {
                                $ValPy[$tno]='re.sub('.$quoted_regex.",e'''".$arg2."''',";
                            } else {
                                # $arg2 = escape_re_sub($arg2);                   # issue bootstrap
                                $ValPy[$tno]='re.sub('.$quoted_regex.','.put_regex_in_quotes($arg2, $delim, $original_regex2, 1).','; #  double quotes neeed to be escaped just in case; issue 111
                            }
                        }else{
                            if(index($modifier, 're.E') >= 0) {
                                $ValPy[$tno]="re.sub($quoted_regex".",e'''".$arg2."''',$DEFAULT_VAR)";
                            } else {
                                # $arg2 = escape_re_sub($arg2);                   # issue bootstrap
                                $ValPy[$tno]="re.sub($quoted_regex".','.put_regex_in_quotes($arg2, $delim, $original_regex2, 1).",$CONVERTER_MAP{S}($DEFAULT_VAR))";	# issue 32, issue 78, issue 111, issue s8
                            }
                        }
                     }else{
                        # this is string replace operation coded in Perl as regex substitution
                        $ValPy[$tno]='str.replace('.$quoted_regex.','.$quoted_regex.',1)';
                     }
                  } elsif( $w eq 'qr' ) {               # SNOOPYJC: qr in other context
                     ($modifier,$groups_are_present)=is_regex($arg1);                           # SNOOPYJC
                     $modifier='' if($modifier eq 'r');                                         # SNOOPYJC
                     ($arg1, $modifier) = build_in_qr_flags($arg1, $modifier);          # issue s3
                     $ValPy[$tno]='re.compile('.put_regex_in_quotes($arg1, $delim, $original_regex).$modifier.')';       # SNOOPYJC, issue 111
                     my $cs = cur_sub();                # issue bootstrap
                     $SpecialVarsUsed{qr}{$cs} = 1;     # issue bootstrap
                  }else{
                     abend("Internal error while analysing $w in line $. : $_[0]");
                  }
               }elsif( $w eq 'tr' || $w eq 'y'  ){
                  # tr function has two parts; also can be named y
                  $source=substr($source,length($w)+1); # cut the word and delimiter
                  $cut=single_quoted_literal($delim,0);
                  # issue 51 $arg1=substr($source,0,$cut-1); # regex always ends before the delimiter
                  $original_regex1 = substr($source,0,$cut-1);                            # issue 111
                  $arg1=remove_escaped_delimiters($delim, $original_regex1); # regex always ends before the delimiter # issue 51, issue 111
                  $arg1 = expand_ranges($arg1, $delim);         # issue 121
                  $source=substr($source,$cut); # remove first part of substitution exclufing including the delimeter
                  if( index('{([<',$delim) > -1 ){
                     # case tr[abc][cde]
                     $delim=substr($source,0,1); # new delimiter can be different from the old, althouth this is raraly used in Perl.
                     # SNOOPYJC $source=substr($source,1,0); # remove delimiter
                     $source=substr($source,1); # SNOOPYJC: remove delimiter
                  }
                  # now string is  /def/d or [def]
                  $cut=single_quoted_literal($delim,0);
                  # issue 51 $arg2=substr($source,0,$cut-1);
                  $original_regex2 = substr($source,0,$cut-1);                            # issue 111
                  $arg2=remove_escaped_delimiters($delim, $original_regex2);     # issue 51, issue 111
                  $arg2 = expand_ranges($arg2, $delim);         # issue 121
                  $source=substr($source,$cut);
                  if( $source=~/^(\w+)/ ){
                     $tr_modifier=$1;
                     $source=substr($source,length($1));
                  }else{
                     $tr_modifier='';
                  }
                  $cut=0;

                  $ValClass[$tno]='f';
                  $ValPerl[$tno]='tr';
                  if($tr_modifier !~ /[cd]/) {                     # issue 121
                      $arg2 = make_same_length($arg1, $arg2);
                      ($arg1, $arg2) = first_map_wins($arg1, $arg2);
                  }
                  # SNOOPYJC if( $tr_modifier eq 'd' ){
                  if($tr_modifier =~ /c/) {             # issue 125
                      $::Pyf{_maketrans_c} = 1; 
                      my $mtc = '_maketrans_c';
                      $mtc = "$PERLLIB.maketrans_c" if($::import_perllib);
                      $ValPy[$tno] = "$mtc(".escape_quotes($arg1).','.escape_quotes($arg2);
                      if($tr_modifier =~ /d/) {         # Only pass the delete flag to this call
                          $ValPy[$tno] .= ',delete=True';
                      }
                      $ValPy[$tno] .= ')';
                      $tr_modifier =~ s/d//;        # SNOOPYJC
                      $ValPy[$tno] .= ",flags=$tr_modifier";    # pass the flags to the next-level call
                  } elsif( $tr_modifier =~ /d/ ){            # SNOOPYJC
                      $tr_modifier =~ s/d//;        # SNOOPYJC
                      if($arg2 eq '') {                 # issue 122
                        $ValPy[$tno]="str.maketrans('','',".escape_quotes($arg1).')';          # issue 123
                        $ValPy[$tno] .= ",flags=$tr_modifier" if($tr_modifier);
                      } else {                          # issue 122
                          if(length($arg2) > length($arg1)) {
                              $arg2 = substr($arg2,0,length($arg1));
                          }
                          if(length($arg2) == length($arg1)) {   # the 'd' flag is worthless in this case
                             $ValPy[$tno]='str.maketrans('.escape_quotes($arg1).','.escape_quotes($arg2).')'; # issue 123
                             $ValPy[$tno] .= ",flags=$tr_modifier" if($tr_modifier);
                          } else {
                             my $to_map = substr($arg1, 0, length($arg2));
                             my $to_delete = substr($arg1, length($to_map));
                             my $regex = '[' . quotemeta($to_map) . ']';
                             $to_delete =~ s/$regex//g;
                             ($to_map, $arg2) = first_map_wins($to_map, $arg2);
                             $ValPy[$tno]='str.maketrans('.escape_quotes($to_map).','.escape_quotes($arg2).','.escape_quotes($to_delete).')'; # issue 123
                             $ValPy[$tno] .= ",flags=$tr_modifier" if($tr_modifier);
                          }
                      }
                  # SNOOPYJC }elsif( $tr_modifier eq 's' ){
                  }elsif( $tr_modifier eq 's' && ($arg2 eq '' || $arg1 eq $arg2)){         # SNOOPYJC
                       # squeeze In Python can be done via Regular expressions in this special case
                         $tr_modifier =~ s/s//;        # SNOOPYJC
                         $ValPerl[$tno]='re';
                         if( $tno>=1 && $ValClass[$tno-1] eq '~' ){
                            $ValPy[$tno]='re.sub(re.compile('.'r'.escape_quotes("([$arg1])(\\1+)").",re.G),r'\\1',"; # issue 123
                         } else {
                            $ValPy[$tno]='re.sub(re.compile('.'r'.escape_quotes("([$arg1])(\\1+)").",re.G),r'\\1',$CONVERTER_MAP{S}($DEFAULT_VAR))"; # issue 123, issue s8
                         }
#                         }else{
#                            $ValPerl[$tno]='re';
#                            if( $ValClass[$tno-2] eq 's' ){
#                                $ValPy[$tno]="$ValPy[$tno-2].translate($ValPy[$tno-2].maketrans(".put_regex_in_quotes($arg1,$delim,$original_regex1).','.put_regex_in_quotes($arg2,$delim,$original_regex2).')); ';       # issue 111: Add $delim
#                                $ValPy[$tno].='re.sub('.put_regex_in_quotes("([$arg2])(\\1+)", $delim, $original_regex2).",r'\\1'),"; # needs to be translated into  two statements, issue 111: Add $delim
#                            }else{
#                                $::TrStatus=-255;
#                                $ValPy[$tno].='re.sub('.put_regex_in_quotes("([$arg2])(\\1+)", $delim, $original_regex2).",r'\\1'),";     # issue 111
#                                logme('W',"The modifier $tr_modifier for tr function with non empty second arg ($arg2) requires preliminary invocation of translate. Please insert it manually ");
#                            }
#                         }
                  # SNOOPYJC }elsif( $tr_modifier eq '' ){
                  } else {              # SNOOPYJC
                      #one typical case is usage of array element on the left side $main::tail[$a_end]=~tr/\n/ /;
                      $ValPy[$tno]='str.maketrans('.escape_quotes($arg1).','.escape_quotes($arg2).')'; # issue 123
                      $ValPy[$tno] .= ",flags=$tr_modifier" if($tr_modifier);
                      # SNOOPYJC if($tr_modifier =~ /[a-qs-z]/) {  # 'r' is handled
                      # SNOOPYJC     logme('W',"The modifier $tr_modifier for tr function currently is not translatable. Manual translation requred ");
                      # SNOOPYJC }
                  # SNOOPYJC }else{
                      # FIXME: 
                      # Ref: https://stackoverflow.com/questions/70603255/complement-maketrans-in-python-for-translate
                      # SNOOPYJC $::TrStatus=-255;
                      # SNOOPYJC logme('W',"The modifier $tr_modifier for tr function currently is not translatable. Manual translation requred ");
                  }

               }elsif( $w eq 'qw' ){
                  # we can emulate it with split function, althouth wq is mainly compile time.
                   $cut=single_quoted_literal($delim,length($w)+1);
                   # issue 51 $ValPerl[$tno]=substr($source,length($w)+1,$cut-length($w)-2);
                   $ValPerl[$tno]=remove_escaped_delimiters($delim, substr($source,length($w)+1,$cut-length($w)-2));
                   if( $ValPerl[0] eq 'use' && $ValPerl[1] ne 'constant' ){     # SNOOPYJC
                      $ValPy[$tno]=$ValPerl[$tno];
                   }else{
		      # issue 44 $ValPy[$tno]='"'.$ValPerl[$tno].'".split(r"\s+")';
                      my $python = $ValPerl[$tno];           # SNOOPYJC
                      $python =~ s/\s+/ /g;             # SNOOPYJC: Change newlines or multiple spaces to single spaces
                      $python =~ s/^\s+//;              # SNOOPYJC: Remove leading spaces
                      $python =~ s/\s+$//;              # SNOOPYJC: Remove trailing spaces
                      # issue 44 $ValPy[$tno]='"'.$python.'".split()';	# issue 44: python split doesn't take a regex!
                      $ValPy[$tno]=escape_quotes($python) . '.split()'; # issue 44
                   }
               }
            } elsif($w eq 'autoflush' && $tno-2 > 0 && $ValClass[$tno-1] eq 'D' &&
                ($ValPerl[$tno-2] eq 'STDOUT' || $ValPerl[$tno-2] eq 'STDERR')) {       # SNOOPYJC
               # Pretend they use $| so we define the autoflush functions for these standard outputs
               my $cs = cur_sub();
               $SpecialVarsUsed{'$|'}{$cs} = 1;                                              # SNOOPYJC
            }

	 } elsif( ($tno>1 && $ValPerl[$tno-1] eq '<<' && index('sd)', $ValClass[$tno-2]) < 0) || # issue 39 - bare HereIs (and not a shift)
	          ( $tno>2 && $ValPerl[$tno-1] eq '~' && $ValPerl[$tno-2] eq '<<' && index('sd)', $ValClass[$tno-3]) < 0)) {	# issue 39 - bare HereIs (and not a shift)
            $has_squiggle = ($ValPerl[$tno-1] eq '~');
            $tno--; # overwrite previous token; Dec 20, 2019 --NNB
            $tno-- if($has_squiggle);           # overwrite that one too!
            $ValClass[$tno]='"';		# issue 39
            $ValPerl[$tno]=substr($source,0,$cut);
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);	# issue 39
            my $quote = substr($ValPy[$tno],3,length($ValPy[$tno])-6);  # issue 39: remove the """ and """
            interpolate_strings($quote, $quote, 0, 0, 0);     # issue 39
	    popup();                                                                            # issue 39
	    popup() if($has_squiggle);
         } elsif($tno == 1 && $ValClass[0] eq 't') {    # issue ddts: TYPE of my/our etc  (my TYPE VARLIST)
             popup();           # Just eat it
             $tno--;
         }
         if($Pythonizer::PassNo!=&Pythonizer::PASS_0 && $ValClass[$tno] eq 'i') {     # issue 94
             track_potential_sub_call($ValPerl[$tno]);  # issue 94
         }                                              # issue 94
      }elsif( $s eq '$'  ){
         if( substr($source,0,length('$DB::single')) eq '$DB::single' ){
            # special case: $DB::single = 1;
            $ValPy[$tno]='pdb.set_trace';
            $ValClass[$tno]='f';
            $cut=index($source,';');
            substr($source,0,$cut)='perl_trace()'; # remove non-tranlatable part.
            $cut=length('perl_trace');
         }else{
            $end_br = 0;                                # issue 43
            #if(substr($source,1,1) eq '{') {		# issue 43: ${...}
            #$end_br = matching_curly_br($source, 1); # issue 43
            #$source = '$'.substr($source,2);	# issue 43: eat the '{'. At this point, $end_br points after the '}'
            #}
            my $s2=substr($source,1,1);                  # issue ws after sigil
            if($s2 eq '' || $s2 =~ /\s/) {               # issue ws after sigil
                $source = get_rest_of_variable_name($source, 0);
            }
            decode_scalar($source,1);
	    if($tno!=0 &&                               # issue 50, issue 92
               (($ValClass[$tno-1] eq 's' && $ValPerl[$tno-1] eq '$') || # issue 50
                $ValClass[$tno-1] eq '@' || 
                ($ValClass[$tno-1] eq '%' && !$had_space))) {	# issue 50
               # Change $$xxx to $xxx, @$xxx to $xxx and %$yyy to $yyy but NOT % $yyy as that's a MOD operator!
               my $was = $ValClass[$tno-1];
               $TokenStr = join('',@ValClass);             # issue 50: replace doesn't work w/o $TokenStr
               replace($tno-1, $ValClass[$tno], $ValPerl[$tno], $ValPy[$tno]);  # issue 50
               popup();                         # issue 50
	       $tno--;				# issue 50 - no need to change hashref to hash or arrayref to array in python
               $ate_dollar = $tno;              # issue 50: remember where we did this
               if($was eq '@' && &Pythonizer::in_sub_call($tno)) {      # issue bootstrap
                   $ValPy[$tno] = '*' . $ValPy[$tno];                   # Splat it
               }
               #$ValPerl[$tno]=$ValPy[$tno]=$s;	# issue 50
	    }
            if( $ValPy[$tno] eq 'SIG' ) {              # issue 81 - implement signals
               $ValClass[$tno] = 'f';
               if($::debug >= 3 && $Pythonizer::PassNo!=&Pythonizer::PASS_0) {
                  say STDERR "decode_scalar SIG source=$source";
               }
               if($tno == 0 || ($tno == 1 && $ValClass[0] eq 't')) {   # at start of line like $SIG{ALRM} = sub { die "timeout"; };
                   $source =~ s/\{['"](\w+)['"]\}/{$1}/;        # Change $SIG{'ALRM'} to $SIG{ALRM}
                   # Special case for __DIE__ - just set a flag
                   $ValPerl[$tno] = '%SIG';
                   if($source =~ /\{\s*__DIE__/) {
                       $ValClass[$tno] = 's';
                       if($source =~ /(?:Carp::)?confess/) {
                           $ValPy[$tno] = $DIE_TRACEBACK;
                           $ValPy[$tno] = "$PERLLIB.$DIE_TRACEBACK" if($::import_perllib);
                           $source =~ s/\{\s*__DIE__\s*\}\s*=.*$/=1;/;
                       } else {
                           $ValPy[$tno] = $DIE_TRACEBACK;
                           $ValPy[$tno] = "$PERLLIB.$DIE_TRACEBACK" if($::import_perllib);
                           $source =~ s/\{\s*__DIE__\s*\}\s*=.*$/=0;/;
                           $source =~ s/\{\s*__DIE__\s*\}\s*;/=0;/;  # issue ddts: Handle "local $SIG{__DIE__};"
                       }
                       $ValPerl[$tno] = '$' . $ValPy[$tno];          # issue ddts: add '$' so we don't get 'erllib.TRACEBACK'
                       $ValPerl[$tno] =~ s/[.]/::/g;                 # issue ddts
                   } elsif($source =~ /\{\s*__WARN__/) {
                       $ValClass[$tno] = 's';
                       $ValPerl[$tno] = $ValPy[$tno] = 'warnings.showwarning';
                       $source =~ s/\{\s*__WARN__\s*\}\s*=/=/;
                   } else {
                       # Change to signal.signal(SIG, RHS);
                       $ValPy[$tno] = 'signal.signal';
                       $source =~ s/=\s*['"]DEFAULT['"]/=_DFL/;
                       $source =~ s/=\s*['"]IGNORE['"]/=_IGN/;
                       $source =~ s/\{\s*([A-Z_]+)\s*\}\s*=\s*(.*);/($1, $2);/;
                       $source =~ s/\{\s*([A-Z_]+)\s*\}\s*;/($1, _IGN);/;       # issue ddts: Handle "local $SIG{CHLD};"
                       # SNOOPYJC: No longer needed since we implemented Carp: $source =~ s/(?:Carp::)?confess\(\s*\@_\s*\)/traceback::print_stack(\$_[1])/;
                   }
                } else {
                   #$ValPy[$tno] = '_getsignal';        # Not sure to use this or that based on what the user's gonna do!
                   $ValPy[$tno] = 'signal.getsignal';   # This choice allows the user to save/restore the value but not compare it to 'DEFAULT' or 'IGNORE'
                   $source =~ tr/{}/()/;
                }
                if($::debug >= 3 && $Pythonizer::PassNo!=&Pythonizer::PASS_0) {
                   say STDERR "decode_scalar SIG source=$source";
                }
            }
            if($end_br) {                               # issue 43
                $cut = $end_br;                         # issue 43
                # NOT NEEDED!  $ValPerl[$tno] = '{'.$ValPerl[$tno].'}'; # issue 43: remember we had ${var} for where we care (like <${var}>)
            }
         }
      }elsif( $s eq '@'  ){
         # SNOOPYJC if( substr($source,1)=~/^(\:?\:?\w+(\:\:\w+)*)/ ){
         my $s2=substr($source,1,1);
         if($s2 eq '' || $s2 =~ /\s/) {               # issue ws after sigil
            $source = get_rest_of_variable_name($source,0);
         }
         if( substr($source,1)=~/^(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)/ ){       # SNOOPYJC: Allow ' from old perl
            $arg1=$1;
            my $cs = cur_sub();
            if( $arg1 eq '_' ){
               $ValPy[$tno]="$PERL_ARG_ARRAY";	# issue 32
               $ValType[$tno]="X";
               $SpecialVarsUsed{'@_'}{$cs} = 1;                       # SNOOPYJC
            }elsif( $arg1 eq 'INC'  ){		# SNOOPYJC
                  $ValPy[$tno]='sys.path';
                  $ValType[$tno]="X";
                  $SpecialVarsUsed{'@INC'}{$cs} = 1;                       # SNOOPYJC
            }elsif( $arg1 eq 'ARGV'  ){
		    # issue 49 $ValPy[$tno]='sys.argv';
                  $ValPy[$tno]='sys.argv[1:]';	# issue 49
                  $ValType[$tno]="X";
                  $SpecialVarsUsed{'@ARGV'}{$cs} = 1;                       # SNOOPYJC
            }else{
               my $arg2 = $arg1;
               $arg2=~tr/:/./s;
               $arg2=~tr/'/./s;          # SNOOPYJC
               $arg2 = remap_conflicting_names($arg2, '@', substr($source,length($arg1)+1,1));      # issue 92
	       $arg2 = escape_keywords($arg2);		# issue 41
               if( $tno>=2 && $ValClass[$tno-2] =~ /[sd'"q]/  && $ValClass[$tno-1] eq '>'  ){
                  $ValPy[$tno]='len('.$arg2.')'; # scalar context   # issue 41
                  $ValType[$tno]="X";
                }else{
                  $ValPy[$tno]=$arg2;            # issue 41
               }
               #$ValPy[$tno]=~tr/:/./s;
               #$ValPy[$tno]=~tr/'/./s;          # SNOOPYJC
               if( substr($ValPy[$tno],0,1) eq '.' ){
                  $ValPy[$tno]="$MAIN_MODULE$ValPy[$tno]";
                  $ValType[$tno]="X";
               }
            }
            $cut=length($arg1)+1;
            # SNOOPYJC $ValPerl[$tno]=substr($source,$cut);
            $ValPerl[$tno]=substr($source,0,$cut);      # SNOOPYC
            $ValClass[$tno]='a'; #array
         }else{
            $cut=1;
         }
      }elsif( $s eq '%' ){
         # the problem here is that %2 can be in i=k%2, so we need to excude digits from regex  -- NNB Sept 3, 2020
         my $s2=substr($source,1,1);
         if($s2 eq '' || $s2 =~ /\s/) {               # issue ws after sigil
            $source = get_rest_of_variable_name($source,0);
         }
         # SNOOPYJC if( substr($source,1)=~/^(\:?\:?[_a-zA-Z]\w*(\:\:[_a-zA-Z]\w*)*)/ ){
         if( substr($source,1)=~/^(\:?\:?\'?[_a-zA-Z]\w*((?:(?:\:\:)|\')[_a-zA-Z]\w*)*)/ ){     # old perl used ' for ::
            $cut=length($1)+1;
            $ValClass[$tno]='h'; #hash
            $ValPerl[$tno]=substr($source,0,1).$1;      # SNOOPYJC
            $ValPy[$tno]=$1;
            $ValPy[$tno]=~tr/:/./s;
            $ValPy[$tno]=~tr/'/./s;             # SNOOPYJC
            if(substr($source,$cut,2) eq '::') {        # SNOOPYJC: Symbol Table reference coming up next!
                $ValPy[$tno] = 'builtins.' . $ValPy[$tno];
                $ValType[$tno]="X";
            } else {
                $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '%', '');      # issue 92
	        $ValPy[$tno] = escape_keywords($ValPy[$tno]);
            }
            if( substr($ValPy[$tno],0,1) eq '.' ){
               $ValCom[$tno]='X';
               $ValPy[$tno]="$MAIN_MODULE$ValPy[$tno]";
            } elsif($ValPy[$tno] eq 'ENV') {                # issue 103
               $ValType[$tno]="X";
               $ValPy[$tno]='os.environ';
               my $cs = cur_sub();
               $SpecialVarsUsed{'%ENV'}{$cs} = 1;                # SNOOPYJC
            }
         } elsif(substr($source,1,1) eq '=') {            # SNOOPYJC: handle %=
             $ValClass[$tno] = '=';
             $ValPy[$tno] = $ValPerl[$tno] = '%=';
             $cut = 2;
         }else{
           $cut=1;
         }
      }elsif( $s eq '&' && ($ch = substr($source,1,1)) ne '&' && $ch ne '='){  # old perl for a sub name, not && or &=
         # the problem here is that &2 can be in i=k&2, so we need to exclude digits from regex  -- NNB Sept 3, 2020
         # if( substr($source,1)=~/^(\:?\:?[_a-zA-Z]\w*(\:\:[_a-zA-Z]\w*)*)/ ){
         if( substr($source,1)=~/^(\:?\:?\'?[_a-zA-Z]\w*((?:(?:\:\:)|\')[_a-zA-Z]\w*)*)/ ){
            $cut=length($1)+1;
            $ValClass[$tno]='i'; # bareword
            $ValPerl[$tno]=$1;
            $ValPy[$tno]=$1;
            $ValPy[$tno]=~tr/:/./s;
            $ValPy[$tno]=~tr/'/./s;             # SNOOPYJC
            $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '&', '');      # issue 92
	    $ValPy[$tno] = escape_keywords($ValPy[$tno]);
            if( substr($ValPy[$tno],0,1) eq '.' ){
               $ValCom[$tno]='X';
               $ValPy[$tno]="$MAIN_MODULE$ValPy[$tno]";
            }
	    # We set a bit so LocalSub is True (and we don't change it to a string) but we can 
	    # still check if it's actually defined locally in add_package_name_sub
            $Pythonizer::LocalSub{$ValPy[$tno]} |= 8;	
            $Pythonizer::LocalSub{cur_package() . '.' . $ValPy[$tno]} |= 8;          # issue s3
	    # issue 117 - if this is "&sub" with no parens, then pass along @_ (but not if it's a reference to the sub, and not in main)
	    if(cur_sub() ne '__main__' && ($tno == 0 || ($ValClass[$tno-1] ne "\\" && $ValPerl[$tno-1] ne 'defined')) && 
               !($tno-2 >= 0 && $ValClass[$tno-1] eq '(' && $ValPerl[$tno-2] eq 'defined') &&
               substr($source,$cut) !~ /^\s*\(/) {	# issue 117
                if( $::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0 ){
                    say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
                }
	        $tno++;
		$ValClass[$tno]=$ValPerl[$tno]=$ValPy[$tno]='(';
                if( $::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0 ){
                    say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
                }
		$tno++;
		$ValClass[$tno]='a';
		$ValPerl[$tno]='@_';
                $ValType[$tno]="X";
                $ValPy[$tno]="$PERL_ARG_ARRAY";
                if( $::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0 ){
                    say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
                }
	        $tno++;
		$ValClass[$tno]=$ValPerl[$tno]=$ValPy[$tno]=')';
	    }
         }else{
           $cut=1;
         }
      }elsif( $s eq '*' && ($ch = substr($source,1,1)) ne '*' && $ch ne '=' &&                    # issue 108: typeglob
              ($tno == 0 || $ValClass[$tno-1] !~ /[sdfi)]/)){                              # issue s11
         # the problem here is that *2 can be in i=k*2, so we need to exclude digits from regex
         # if( substr($source,1)=~/^(\:?\:?[_a-zA-Z]\w*(\:\:[_a-zA-Z]\w*)*)/ ){
         if( substr($source,1)=~/^(\:?\:?\'?[_a-zA-Z]\w*((?:(?:\:\:)|\')[_a-zA-Z]\w*)*)/ ){
            $cut=length($1)+1;
            $ValClass[$tno]='G'; # typeglob
            $ValPerl[$tno]='*'.$1;
            $ValPy[$tno]=$1;
            $ValPy[$tno]=~tr/:/./s;
            $ValPy[$tno]=~tr/'/./s;             # SNOOPYJC
	    $ValPy[$tno] = escape_keywords($ValPy[$tno]);
            if( substr($ValPy[$tno],0,1) eq '.' ){
               $ValCom[$tno]='X';
               $ValPy[$tno]="$MAIN_MODULE$ValPy[$tno]";
            }
         }else{
           $cut=1;
         }
      }elsif( $s eq '[' || $s eq '(' ){
         if($tno != 0 && $ValClass[$tno-1] eq 'D') {	# issue 50, issue 93
	    popup();                            # issue 50
	    $tno--;				# issue 50 - no need to keep arrow operator in python
      	    $ValPerl[$tno]=$ValPy[$tno]=$s;	# issue 50
            $ValClass[$tno]='('; # we treat anything inside curvy backets as expression
            $cut=1;
         }elsif($s eq '(' && $tno == 2 && $ValClass[0] eq 'k' && $ValPerl[0] eq 'sub' && $ValClass[1] eq 'i') {      
            # SNOOPYJC: Eat sub arg prototype because we can't currently handle it and it lexes wrong too!
            $cut=1;
            my $close = matching_paren($source, 0);
            if($close != -1) {
                $cut = $close+1;
                popup();
                $tno--;
            }
	 } else {
            $ValClass[$tno]='('; # we treat anything inside curvy backets as expression
            $cut=1;
        }
      }elsif( $s eq ']' || $s eq ')' ){
         $ValClass[$tno]=')'; # we treat anything inside curvy backets as expression
         $cut=1;
      }elsif( $s=~/\W/  ){
         #This is delimiter
         $quadgram=substr($source,0,4);         # issue 66
         $trigram=substr($source,0,3);          # issue 66
         $digram=substr($source,0,2);
         $digram = '' if($quadgram eq '<<>>');  # issue 66
         if($trigram eq '<=>') {                # issue 66
             $ValClass[$tno] = '>';             # issue 66: comparison
             $ValPerl[$tno] = $trigram;         # issue 66
             $ValPy[$tno] = '_spaceship';       # issue 66
             $cut=3;                            # issue 66
         } elsif($trigram eq '**=' || $trigram eq '>>=' || $trigram eq '<<=' || $trigram eq '||=' || $trigram eq '&&=') { # SNOOPYJC, issue s3
             $ValClass[$tno] = '=';
             $ValPy[$tno] = $ValPerl[$tno] = $trigram;
             $cut=3;
         } elsif( exists($digram_tokens{$digram})  ){
            $ValClass[$tno]=$digram_tokens{$digram};
            $ValPy[$tno]=$digram_map{$digram};
            #next unless($ValPy[$tno]); # =~ does not need to be tranlated to token
            $ValPerl[$tno]=$digram;
            if($ValClass[$tno] eq '0'){		# && or ||
               $balance=(join('',@ValClass)=~tr/()//);
               # issue 93 if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && join('',@ValClass) !~ /^t?[ahs]=/ )  # SNOOPYJC
               if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && bash_style_or_and_fix(3)){  # issue 93
                  # postfix conditional statement, like ($debug>0) && ( line eq ''); Aug 10, 2020,Oct 12, 2020 --NNB
                  # issue 93 bash_style_or_and_fix(3);
                  last;
               }else{
                  $cut=2
               }
            }else{
               if( exists($digram_map{$digram})  ){
                  $ValPy[$tno]=$digram_map{$digram}; # changes for Python
               }else{
                  $ValPy[$tno]=$ValPerl[$tno]; # same as in Perl
               }
               $cut=2;
            }
            if($digram eq '=>' && $tno != 0) {
               if($ValClass[$tno-1] eq 'f' && $ValPerl[$tno-1] eq 'delete') {    # issue delete
                    $ValClass[$tno-1] = '"';        # delete => '...' - make it into 'delete' => '...'
                    $ValPy[$tno-1] = "'delete'";
               } elsif($ValClass[$tno-1] eq 'd') {      # Hash keys are strings in perl
                   $ValClass[$tno-1] = '"';
                   $ValPy[$tno-1] = "'" . $ValPy[$tno-1] . "'";
               } elsif($tno >= 3 && $ValClass[0] eq 'k' && $ValPerl[0] eq 'use' && $ValClass[1] eq 'i' && $ValPerl[1] eq 'constant' && $ValClass[$tno-1] eq 'i') {
                   remap_conflicting_names($ValPerl[$tno-1], '', '');   # Could remap other names, not us
               }

            }
         }elsif( $s eq '='  ){
            $TokenStr = join('',@ValClass);             # issue 93
            if( index($TokenStr,'c')>-1 ||
                index($TokenStr,'o')>-1 ||              # issue 93
                index($TokenStr,'0')>-1){               # issue 93: handle "$i = exp1 or $j = exp2;"
               $ValPy[$tno]=':=';
            }
            $cut=1;
         }elsif( $s eq '\\'  ){
            $ValPy[$tno]='';
            $cut=1;
         }elsif( $s eq '!'  ){
             # SNOOPYJC $ValPy[$tno]=' not ';
            $ValPy[$tno]='not';
            $cut=1;
         }elsif( $s eq '-'  ){
           $s2=substr($source,1,1);
           # SNOOPYJC if( ($k=index('fdlzesACMrwxoRWXO',$s2))>-1 && substr($source,2,1)=~/\s/  ){
           if( exists $DASH_X{$s2} && substr($source,2,1)=~/\s/  ){
              $ValClass[$tno]='f';
              $ValPerl[$tno]=$digram;
              # SNOOPYJC $ValPy[$tno]=('os.path.isfile','os.path.isdir','os.path.islink','not os.path.getsize','os.path.exists','os.path.getsize','_getA', '_getC', '_getM', '_is_r', '_is_w', '_is_x', '_is_o', '_ir_r', '_ir_w', '_ir_x', '_ir_o')[$k];
              $ValPy[$tno]=$DASH_X{$s2};                # SNOOPYJC
              $cut=2;
           #SNOOPYC: had to remove this fix because t-timelocal(...) was being changed to t'-timelocal' !!!
           #NG           }elsif($source =~ /^(-[A-Za-z_]\w*)/) {       # issue 88: -bareword
           #NG$w=$1;
           #NG$cut=length($w);
           #NG$ValClass[$tno]='"';      # String
           #NG$ValPerl[$tno]=$w;
           #NG$ValPy[$tno]="'$w'";
           }else{
              $cut=1; # regular minus operator
           }
         }elsif( $s eq '<'  ){
            # diamond operator
            my $safe_mode = 0;                  # issue 66: FIXME: Not implemented (to implement, use openhook and perl_open)
            my $fh = '';
            # issue bootstrap if( $source=~/^<(\w*)>/ || $quadgram eq '<<>>'){    # issue 66
            if( $source=~/^<(\:?\:?\'?\w*((?:(?:\:\:)|\')\w+)*)>/ || $quadgram eq '<<>>'){    # issue 66
               # SNOOPYJC $ValClass[$tno]='i';
               $ValClass[$tno]='j';             # SNOOPYJC
               if($quadgram eq '<<>>') {        # issue 66
                   $cut = 4;                    # issue 66
                   $safe_mode = 1;              # issue 66
               } else {                         # issue 66
                   $cut=length($1)+2;
                   $ValPerl[$tno]="<$1>";
                   $fh = $1;
                   $fh=~tr/:/./s;          # issue bootstrap
                   $fh=~tr/'/./s;          # SNOOPYJC
		   $FileHandles{$fh} = $. unless($fh eq '' || exists $keyword_tr{$fh} || exists $FileHandles{$fh});	# SNOOPYJC
               }                                # issue 66
               #
               # Let's try to determine the context
               #
	       # issue 62 if( $tno==2 && $ValClass[0] eq 'a' && $ValClass[1] eq '='){
               if( $tno>=2 && $ValClass[$tno-2] eq 'a' && $ValClass[$tno-1] eq '='){	# issue 62: handle "my @a=<FH>;" and "chomp(my @a=<FH>);"
                   if(length($fh)==0){         # issue 66: Pure diamond
                     insert(0, 'W', "<>", "with fileinput.input() as $DIAMOND:");    # issue 66
                     $tno++;
                     $ValPy[$tno]="list($DIAMOND)";     # issue 66
                   } elsif($fh eq 'STDIN' ){            # issue 66
                     $ValPy[$tno]='sys.stdin.readlines()';
                  }else{
                     $ValPy[$tno]="$fh.readlines()";
                  }
               }elsif($ValClass[0] eq 'c' and $ValPerl[0] eq 'while') { # issue 66
                   if(length($fh)==0){         # issue 66
                       insert(0, 'W', "<$fh>", "with fileinput.input() as $DIAMOND:");    # issue 66
                       $tno++;
                       $ValPy[$tno]="next($DIAMOND, None)";        # issue 66: Allows for $.
                   }elsif($fh eq 'STDIN' ){     # issue 66
                       insert(0, 'W', "<$fh>", "with fileinput.input('-') as $DIAMOND:");    # issue 66
                       $tno++;
                       $ValPy[$tno]="next($DIAMOND, None)";        # issue 66: Allows for $.
                   }else{
                       # issue 66: use a context manager so it's automatically closed
                       # issue 66 insert(0, 'W', "<$fh>", qq{with fileinput.input("<$fh>",openhook=lambda _,__:$fh) as $DIAMOND:});    # issue 66
                       # issue 66 $tno++;                                     # issue 66
                       # issue 66 $ValPy[$tno]="next($DIAMOND, None)";        # issue 66: Allows for $.
                       my $rl = select_readline();                      # issue 66
                       $ValPy[$tno]="$rl($fh)";                         # issue 66
                   }
               }else{           # we're just reading one line so we can't use the context manager as it closes the file handle
                   if(length($fh)==0){         # issue 66
		       # issue bootstrap $ValPy[$tno]="next(fileinput.input(), None)";        # issue 66: Allows for $.
		       $::Pyf{_fileinput_next} = 1;		# issue bootstrap
		       $::Pyf{'_fileinput_next()'} = 1;		# issue bootstrap - this line is so that _fileinput_next() is replaced with perllib.fileinput_next()
                       $ValPy[$tno]="_fileinput_next()";        # issue bootstrap, issue 66: Allows for $.
                   }elsif($fh eq 'STDIN' ){     # issue 66
                       # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                       # issue 66 $ValPy[$tno]='sys.stdin().readline()';
                       my $rl = select_readline();                      # issue 66
                       $ValPy[$tno]="$rl(sys.stdin())";                 # issue 66: support $/
                       # $ValPy[$tno]="next(with fileinput.input('-'), None)";        # issue 66: Allows for $.
                   }else{
                       # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                       # issue 66 $ValPy[$tno]="$fh.readline()";
                       my $rl = select_readline();                      # issue 66
                       $ValPy[$tno]="$rl($fh)";           # issue 66: support $/
                       #insert(0, 'W', "<$fh>", qq{with fileinput.input("<$fh>",openhook=lambda _,__:$fh) as $DIAMOND:});    # issue 66
                       #$tno++;                                     # issue 66
                       #$ValPy[$tno]=qq{next(with fileinput.input("<$fh>",openhook=lambda _,__:$fh), None)};        # issue 66: Allows for $.
                   }
               }
            }elsif($source =~ /^<\$(\w*)>/ ) {          # issue 66: <$fh>
               # SNOOPYJC $ValClass[$tno]='i';
               $ValClass[$tno]='j';             # SNOOPYJC
               $cut=length($1)+3;
               $ValPerl[$tno]="<\$$1>";
               #
               # Let's try to determine the context
               #
	       # issue 62 if( $tno==2 && $ValClass[0] eq 'a' && $ValClass[1] eq '='){
               if( $tno>=2 && $ValClass[$tno-2] eq 'a' && $ValClass[$tno-1] eq '='){	# issue 62: handle "my @a=<FH>;" and "chomp(my @a=<FH>);"
                   $ValPy[$tno]="$1.readlines()";
               }elsif($ValClass[0] eq 'c' and $ValPerl[0] eq 'while') { # issue 66
                   # issue 66 insert(0, 'W', "<$1>", qq{with fileinput.input("<$1>",openhook=lambda _,__:$1) as $DIAMOND:});    # issue 66
                   # issue 66 $tno++;                                     # issue 66
                   # issue 66 $ValPy[$tno]="next($DIAMOND, None)";        # issue 66: Allows for $.
                   my $rl = select_readline();                      # issue 66
                   $ValPy[$tno]="$rl($1)";                # issue 66: Support $/, $.
               }else{
                   # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                   # issue 66 $ValPy[$tno]="$1.readline()";
                   my $rl = select_readline();                      # issue 66
                   $ValPy[$tno]="$rl($1)";                # issue 66: Support $/, $.
                   # issue 66: use a context manager so it's automatically closed
                   #insert(0, 'W', "<$1>", qq{with fileinput.input("<$1>",openhook=lambda _,__:$1) as $DIAMOND:});    # issue 66
                   #$tno++;                                     # issue 66
                   #$ValPy[$tno]=qq{next(with fileinput.input("<$1>",openhook=lambda _,__:$1), None)};        # issue 66: Allows for $.
               }
            }elsif($tno > 0 && index("(.=", $ValClass[$tno-1]) >= 0 && $source =~ /^<[^>]+>/) {    # issue 66 <glob>
                $ValClass[$tno] = 'g';
                $cut=double_quoted_literal('<',1);
                $ValPy[$tno] = $keyword_tr{glob}.'('.join('",f"', split ' ', $ValPy[$tno]).')';
                $ValPy[$tno] =~ s/,f""\)/)/;    # For the <$pat > case, remove the extra space
            }else{
              $ValClass[$tno]='>'; # regular < operator
              $cut=1;
            }
         }else{
            $ValClass[$tno]=$ValPerl[$tno]=$ValPy[$tno]=$s;
            if( $s eq '.'  ){   # Could be string concat, float constant, range operator, or elipsis
               $ValPy[$tno]=' + ';
	       if( $source=~/(^[.]\d+(?:[_]\d+)*(?:[Ee][+-]?\d+(?:[_]\d+)*)?)/ && !is_concat() ){ # issue 23: float constant starting with '.', issue s15
	          $ValClass[$tno] = 'd';			# issue 23
		  $ValPy[$tno] = $ValPerl[$tno] = $1;		# issue 23
		  $cut=length($1);				# issue 23
                  # SNOOPYJC: If this is the second string of digits, merge it with the first
                  if($tno != 0 && $ValClass[$tno-1] eq 'd' && $ValPy[$tno-1] =~ /^(\d+)\.(\d+)$/) { # e.g. 102.111 .112
                      $ValClass[$tno-1] = '"';
                      $ValPerl[$tno-1] .= $ValPerl[$tno];
                      $ValPy[$tno-1] = interpolate_string_hex_escapes(sprintf('\'\\x{%x}\\x{%x}', int($1), int($2)));
                      $ValPy[$tno-1] .= interpolate_string_hex_escapes(sprintf('\\x{%x}\'', int(substr($ValPy[$tno],1))));
                      popup();
                      $tno--;
                  } elsif($tno != 0 && $ValClass[$tno-1] eq '"') {      # e.g. v1 .20
                      $ValPy[$tno-1] = substr($ValPy[$tno-1],0,length($ValPy[$tno-1])-1) . 
                        interpolate_string_hex_escapes(sprintf('\\x{%x}\'', int(substr($ValPy[$tno],1))));
                      $ValPerl[$tno-1] .= $ValPerl[$tno];
                      popup();
                      $tno--;
                  }
               } elsif( $source =~ /^[.][.][.]/ ) {             # issue elipsis
                   $ValClass[$tno] = 'k';
                   $ValPerl[$tno] = '...';
                   $ValPy[$tno] = "raise NotImplementedError('Unimplemented')";
                   $cut = 3;
	       } elsif( $source =~ /^[.][.]/ ) {		# issue range
		  $ValClass[$tno] = 'r';			# issue range
		  $ValPerl[$tno] = '..';			# issue range
		  $ValPy[$tno] = '..';				# issue range - not quite right but we have to handle specially
		  $cut = 2;
	       } else {						# issue 23
		  $cut=1;					# issue 23
	       }						# issue 23
            }elsif( $s eq '<'  ){
               $ValClass[$tno]='>';
	       $cut=1;						# issue 23
            }elsif($s eq ':' && $tno == 1 && $ValClass[0] eq 'i') {     # issue 94: Labeled statement
                def_label($ValPerl[0]);                         # issue 94
                if( length($source)>1  ){                       # issue 94
                   Pythonizer::getline(substr($source,1)); # save tail
                }
                last; # artificially truncating the line making it two-symbol line
                $cut=1;
            }elsif($s eq ',' && $tno != 0 && $ValClass[$tno-1] eq ',') {        # issue ddts: extra comma is ignored by perl
                popup();
                $tno--;
                $cut=1;
            }else{
	       $cut=1;						# issue 23
	    }
	    # issue 23 $cut=1;
         }
      }
      if($ValClass[$tno] =~ /[ahsG]/) {         # SNOOPYJC: Handle globals in packages
          if($Pythonizer::PassNo == &Pythonizer::PASS_2) {
              add_package_name(get_perl_name($ValPerl[$tno], substr($source,$cut,1),
                  ($ate_dollar == $tno  ? '$' : ''))) unless($::implicit_global_my);
          } elsif($Pythonizer::PassNo == &Pythonizer::PASS_1) {
              capture_varclass();                # SNOOPYJC
          }
      } elsif($ValClass[$tno] eq 'j') {		# SNOOPYJC
          if($Pythonizer::PassNo == &Pythonizer::PASS_2) {
              add_package_name_j() unless ($::implicit_global_my);
          } elsif($Pythonizer::PassNo == &Pythonizer::PASS_1) {
              capture_varclass_j();
          }
      }
      finish(); # subroutine that prepeares the next cycle
   } # while
   if($tno > 0) {                                       # issue 94
        if($ValClass[0] eq 'k' && ($ValPerl[0] eq 'last' || $ValPerl[0] eq 'next')) {    # issue 94
            handle_last_next(0);                              # issue 94
        } elsif($ValClass[0] eq 'k' && $Pythonizer::PassNo == &Pythonizer::PASS_1 && $ValPerl[0] eq 'redo') {            # SNOOPYJC
            track_redo(0);
        } elsif($ValClass[0] eq 't' && $ValPerl[0] eq 'local' && $Pythonizer::PassNo == &Pythonizer::PASS_1) {        # issue 108
            handle_local();                                     # issue 108
        } elsif($ValClass[0] eq 's' && ($ValPerl[0] eq '$-' || $ValPerl[0] eq '$+') && $ValClass[1] eq '(') {
            my $match = &Pythonizer::matching_br(1);
            $ValPy[1] = '(';           # Change subscript to function call
            $ValPy[$match] = ')' if($match != -1);
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] =~ /^(?:no|use)$/ && $ValPerl[1] eq 'warnings') {
            my $orig_stmt = $ValPerl[0];
            replace(0, 't', 'local', '');
            my $w = $SPECIAL_VAR2{W};
            replace(1, 's', '$^W', $w);
            destroy(2, scalar(@ValClass)-2) if(scalar(@ValClass) > 2);
            append('=','=','=');
            if($orig_stmt eq 'no') {
                append('d','0','0');
            } else {
                append('d','1','1');
            }
            handle_local() if($Pythonizer::PassNo == &Pythonizer::PASS_1); 
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'use' && $ValPerl[1] eq 'lib') {
            handle_use_lib();
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'use' && $ValPerl[1] eq 'overload') {     # issue s3
            handle_use_overload();
        } elsif($ValClass[0] eq 'k' && ($ValPerl[0] eq 'use' || $ValPerl[0] eq 'require')) {    # issue names
            handle_use_require(0);                                                              # issue names
        } elsif($#ValClass == 3 && $ValClass[0] eq 't' && $ValClass[1] eq 'a' && $ValPerl[1] eq '@ISA' && $ValClass[2] eq '=' && $ValClass[3] eq 'q' && cur_sub() eq '__main__') { # issue s3
            $SpecialVarsUsed{'@ISA'}{__main__} = $ValPy[3];             # issue s3
        }
        for(my $i=1; $i <= $#ValClass; $i++) {
            if($ValClass[$i] eq 'k') {
                if($ValPerl[$i] eq 'last' || $ValPerl[$i] eq 'next') {
                    handle_last_next($i);
                } elsif($ValPerl[$i] eq 'return') {
                    handle_return_in_expression($i);
                } elsif($ValPerl[$i] eq 'use' || $ValPerl[$i] eq 'require') {   # issue names
                    handle_use_require($i);                                     # issue names
                }
            } elsif($ValClass[$i] eq 's') {
                if(($ValPerl[$i] eq '$-' || $ValPerl[$i] eq '$+') && ($i+1 <= $#ValClass && $ValClass[$i+1] eq '(')) {
                    $TokenStr=join('',@ValClass);
                    my $match = &Pythonizer::matching_br($i+1);
                    $ValPy[$i+1] = '(';           # Change subscript to function call
                    $ValPerl[$i+1] = '(';
                    if($match != -1) {
                        $ValPy[$match] = ')';
                        $ValPerl[$match] = ')';
                    }
                } elsif(($ValClass[$i-1] eq 'f' && $ValPerl[$i-1] eq 'pos') ||
                        ($ValClass[$i-1] eq '(' && $ValClass[$i-2] eq 'f' && $ValPerl[$i-2] eq 'pos')) {
                    handle_pos_ref($i);
                }
            } elsif($ValClass[$i] eq 'f' && $ValPy[$i] eq '_last_ndx' && $i+1 < $#ValClass && $ValClass[$i+1] eq '(') { # issue 119
                # We have a $#{expr} which we changed into  _last_ndx{expr} - change it to _last_ndx(expr)
                $ValPerl[$i+1] = $ValPy[$i+1] = '(';
                my $match = &Pythonizer::matching_br($i+1);
                $ValPerl[$match] = $ValPy[$match] = ')' if($match > 0);
            }
        }
        $TokenStr=join('',@ValClass);
        my $pgx = index($TokenStr, 's~q');      # SNOOPYJC: Possible 'pos' generator
        if($pgx >= 0) {
            $scalar_pos_gen_line{$ValPerl[$pgx]} = $.;
        }
   }

   $TokenStr=join('',@ValClass);
   if( $::debug>=2 && $Pythonizer::PassNo == &Pythonizer::PASS_2){
      #$num=($Pythonizer::passno) ? sprintf('%4u',$lineno) : sprintf('%4u',$Pythonizer::InLineNo);
      say STDERR "\nLine: " . sprintf('%4u',$.) . " TokenStr: =|",$TokenStr, "|= \@ValPy: ",join(' ',@ValPy);
   }

} #tokenize
#
# subroutine that prepeares the next cycle
#
sub finish
{
my $original;
   if( $cut>length($source)){
      logme('S',"The value of cut ($cut) exceeded the length (".length($source).") of the string: $source ");
      $source='';
   }elsif( $cut>0 ){
       #say STDERR "finish: source=$source, cut=$cut";
      substr($source,0,$cut)='';
      #say STDERR "finish: source=$source (after cut)";
   }
   if( length($source)==0  || $source =~ /^\s+$/){        # SNOOPYJC
       # the current line ended but ; or ){ } were not reached
       $original=$Pythonizer::IntactLine;
       my @tmpBuffer = @BufferValClass;	# Issue 7
       @BufferValClass = ();		# Issue 7
       $source=Pythonizer::getline();
       @BufferValClass = @tmpBuffer;	# Issue 7
       my $st_source = '';              # issue s6
       $st_source = $source =~ s/^\s*//r if(defined $source);    # issue s6
       while($Pythonizer::IntactEndLno < $.) {         # issue s6
          if($Pythonizer::IntactLine) {
              $Pythonizer::IntactLine .= "\n";
          } else {
              $Pythonizer::IntactLine = ' ';
          }
          $Pythonizer::IntactEndLno++;
       }
       if( length($Pythonizer::IntactLine)>0 ){
          # issue s6 $original.="\n".$Pythonizer::IntactLine;
          $original.="\n".$st_source;      # issue s6
          $Pythonizer::IntactEndLno = $.;  # issue s6
          $Pythonizer::IntactLine=$original;
       }else{
         # issue s6 $Pythonizer::IntactLine=$original;
         $Pythonizer::IntactLine=$st_source;       # issue s6
         $Pythonizer::IntactEndLno = $.;   # issue s6
       }
       say STDERR "$Pythonizer::IntactLno $Pythonizer::IntactLine (EndLno=$Pythonizer::IntactEndLno)" if($Pythonizer::TraceIntactLine);
   }
   if($ExtractingTokensFromDoubleQuotedStringEnd > 0 && $ValClass[$tno] eq '"' && substr($ValPy[$tno],0,4) eq 'f"""') {  # SNOOPYJC
       # Correct the ValPerl because we unfortunately get it wrong, exp if $cut-2 is negative!
       $ValPerl[$tno] = substr($ValPy[$tno], 4, length($ValPy[$tno])-7);
   }
   $ValType[$tno]='' unless defined $ValType[$tno];           # issue bootstrap segv
   if( $::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0 ){
     say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
   }
   $tno++;
   if($ExtractingTokensFromDoubleQuotedStringEnd > 0) {               # SNOOPYJC
       $ExtractingTokensFromDoubleQuotedTokensEnd -= $cut;
       $ExtractingTokensFromDoubleQuotedStringEnd -= $cut;
       #say STDERR "finish2: ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd" if($::debug>=5);
       if($ExtractingTokensFromDoubleQuotedTokensEnd <= 0) {
           $ValClass[$tno] = '"';
           if(defined $source) {
                my $quote=substr($source,0,$ExtractingTokensFromDoubleQuotedStringEnd);
                $cut = extract_tokens_from_double_quoted_string($quote, 0);
                #say STDERR "finish2: source=$source, cut=$cut";
                substr($source,0,$cut)='';
                #say STDERR "finish2: source=$source (after cut)";
                $ExtractingTokensFromDoubleQuotedStringEnd -= $cut;
                #say STDERR "finish2: ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd (after cut)" if($::debug>=5);
            } else {
                $cut = extract_tokens_from_double_quoted_string('', 0);
            }
        }
    }

}

sub select_readline
# Select either the simple or the full version of readline depending on if $. and $/ are used or not
{
    my $rl = "_readline";
    $rl = "_readline_full" if(exists $SpecialVarsUsed{'$/'} || exists $SpecialVarsUsed{'$.'});
    $::Pyf{$rl} = 1; 
    if($::import_perllib) {
        $rl = $PERLLIB . '.' . substr($rl, 1);
    }
    return $rl;
}

sub bash_style_or_and_fix
# On level zero those are used instead of if statement
{
my $split=$_[0];
   return 0 if($Pythonizer::PassNo!=&Pythonizer::PASS_2); # SNOOPYJC
   # bash-style conditional statement, like ($debug>0) && ( line eq ''); Aug 10, 2020 --NNB
   $is_or = ($ValPy[-1] =~ /or/);	# issue 12
   $is_low_prec = ($ValPerl[-1] =~ /^[a-z]+$/);         # issue 93: is this low precedence like and/or instead of &&/||
   $balance=0;                                          # issue 93: compute paren balance to see if we're in parens
   for ($i=0;$i<@ValClass;$i++ ){
      if( $ValClass[$i] eq '(' ){
         $balance++;
      }elsif( $ValClass[$i] eq ')' ){
         $balance--;
      }
   }
   $is_low_prec = 0 if($balance > 0);                   # issue 93: eg: "$i = (this or ...", parens make the 'or' act like '||'

   if($::debug >= 3) {
       say STDERR "bash_style_or_and_fix($split) is_or=$is_or, source=$source, is_low_prec=$is_low_prec";
   }
   if($split > $#ValClass) {              # issue ddts: no code before the || (was an eval)
       say STDERR "bash_style_or_and_fix($split) returning 0 - split is past the end!" if($::debug>=3);
       return 0;
   }

   if($line_contains_stmt_modifier{$statement_starting_lno}) {          # issue 116
       say STDERR "bash_style_or_and_fix($split) returning 0 - stmt contains modifier" if($::debug>=3);
       return 0;
   }
   # issue 93: if this is an assignment, only transform it if it contains a control statement afterwards or if it's a low precedence op
   my $tstr = join('',@ValClass);
   if(($tstr =~ /^t?[ahs](?:\(.*\))*=/ || 
       $tstr =~ /^t?\(.*,.*\)=/ ||                      # issue s7 - handle ($x,$y)= style assignment
      ($tstr =~ /^kiiA/ && $ValPerl[0] eq 'use' && ($ValPerl[1] eq 'constant' || $ValPerl[1] eq 'overload'))) &&        # issue s3
      !$is_low_prec && ($split >= length($source) ||
      substr($source,$split) !~ /^\s*(?:return|next|last|assert|delete|require|die)\b/)) {       # issue 93
      say STDERR "bash_style_or_and_fix($split) returning 0 - does not need transforming" if($::debug>=3);
      return 0;
   } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'return') {            # issue 110
      say STDERR "bash_style_or_and_fix($split) returning 0 - return does not need transforming" if($::debug>=3);
      return 0;
   }

   Pythonizer::getline('{');
   # issue 86 $delayed_block_closure=1;
   $delayed_block_closure++;            # issue 86
   if( $split<length($source) ){
      Pythonizer::getline(substr($source,$split)); # at this point processing contines untill th eend of the statement
   }
   $source='';
   $TokenStr=join('',@ValClass); # replace will not work without $TokenStr
   if( $ValClass[0] eq '(' && $ValClass[-2] ){
      destroy(-1);
   }else{
      replace($#ValClass,')',')',')'); # we need to do this befor insert as insert changes size of array and makes $tno invalid
      insert(0,'(','(','(');
   }
   if($is_or) {				# issue 12
      insert(0,'n','not','not');	# issue 12, issue 93
      insert(0,'(','(','(');		# issue 12
      append(')',')',')');		# issue 12
   }					# issue 12
   insert(0,'c','if','if');
   if($::debug >= 3) {
       say STDERR "After bash_style_or_and_fix($split): =|$TokenStr|=";
   }
   $cut=0;
   return 1;                            # issue 93
}
sub decode_scalar
# Returns codes via variable $rc.-1 -special variable; 1 -regular variable
# NOTE: currently return value is not used. Aug 28, 2020 --NNB
# Has two modes of operation
#    update=1 -- set ValClass and ValPerl
#    update=0 -- set only ValPy
#    in_string=1 - we are decoding in a string and $xxx [0] is different than $xxx[0], but $ xxx is still like $xxx
#    in_regex=1 - we are decoding in a string in a regex, and $func[:)] is not a reference to @func
{
my $source=$_[0];
my $update=$_[1]; # if update is zero then only ValPy is updated
my $in_string=(scalar(@_) >= 3 ? $_[2] : 0);
my $in_regex=(scalar(@_) >= 4 ? $_[3] : 0);		# issue bootstrap
my $rc=-1;
   if ( $update  ){
      $ValClass[$tno]='s'; # we do not need to set it if we are analysing double wuoted literal
   }
   my $s2=substr($source,1,1);
   my $specials = q(!?<>()!;]&`'+-"@$|/,\\%=~^:);             # issue 50, SNOOPYJC
   if(($s2 eq '$' || $s2 eq '%') && substr($source,2,1) =~ /[\w:']/) {   # issue 50: $$ is a special var, but not $$a or $$: or $$'
       $specials = '!';
   }
   if( $s2 eq '.'  ){
      # file line number
      # issue 66 $ValPy[$tno]='fileinput.filelineno()';
      # issue 66 $ValPy[$tno]='fileinput.lineno()';       # issue 66: Mimic the perl behavior
       $::Pyf{_nr} = 1;              # issue 66
       if($::import_perllib) {
           $ValPy[$tno]="$PERLLIB.nr()";         # issue 66: Mimic the perl behavior, no matter if we're using fileinput or not
           $SpecialVarR2L{$ValPy[$tno]} = "$PERLLIB.INPUT_LINE_NUMBER";      # Name if used on LHS
       } else {
           $ValPy[$tno]='_nr()';         # issue 66: Mimic the perl behavior, no matter if we're using fileinput or not
           $SpecialVarR2L{$ValPy[$tno]} = 'INPUT_LINE_NUMBER';      # Name if used on LHS
       }
       $ValType[$tno]="X";
       my $vn = substr($source,0,2);                    # SNOOPYJC
       my $cs = cur_sub();
       $SpecialVarsUsed{$vn}{$cs} = 1;                       # SNOOPYJC
       $ValPerl[$tno]=$vn if($update);                  # SNOOPYJC
       $cut=2
   }elsif( $s2 eq '^'  && substr($source,2,1) =~ /[A-Z]/ ){     # SNOOPYJC
       $s3=substr($source,2,1);
       $cut=3;
       $ValType[$tno]="X";
       my $vn = substr($source,0,3);                    # SNOOPYJC
       my $cs = cur_sub();
       $SpecialVarsUsed{$vn}{$cs} = 1;                       # SNOOPYJC
       $ValPerl[$tno]=$vn if($update);                  # SNOOPYJC
       if( $s3=~/\w/  ){
          if( exists($SPECIAL_VAR2{$s3}) ){
            $ValPy[$tno]=$SPECIAL_VAR2{$s3};
            if(substr($SPECIAL_VAR2{$s3},0,1) eq '_') { # SNOOPYJC
                $::Pyf{$SPECIAL_VAR2{$s3}} = 1;
                if($::import_perllib) {
                    $ValPy[$tno]="$PERLLIB.".substr($ValPy[$tno],1);
                }
                $ValPy[$tno] .= '()';   # call it
            }
          }else{
            $ValPy[$tno]='unknown_perl_special_var'.$s3;
         }
       }
   # issue 46 }elsif( index(q(!?<>()!;]&`'+"),$s2) > -1  ){
   }elsif( index($specials,$s2) > -1 && substr($source,1,2) ne '::' ){	# issue 46, issue 50, SNOOPYJC ($:: is not $:)
      $ValPy[$tno]=$SPECIAL_VAR{$s2};
      $cut=2;
      $ValType[$tno]="X";
      my $vn = substr($source,0,2);                     # SNOOPYJC
      my $svar = $vn;                                   # SNOOPYJC
      my $nxc = substr($source,2,1);                    # SNOOPYJC
      $svar = '@' . substr($svar,1) if($nxc eq '[');    # SNOOPYJC
      $svar = '%' . substr($svar,1) if($nxc eq '{');    # SNOOPYJC
      if($svar eq '%+') {          # issue s16
          $ValPy[$tno] = "$DEFAULT_MATCH.group";        # issue s16: %+ is different than @+
      }
      my $cs = cur_sub();
      $SpecialVarsUsed{$svar}{$cs} = 1;                      # SNOOPYJC: Capture the actual var referenced, e.g. $-[0] => @-
      $ValPerl[$tno]=$vn if($update);                   # SNOOPYJC
   }elsif( $s2 =~ /\d/ ){
       $source=~/^.(\d+)/;
       my $vn=substr($source,0,1).$1;                   # SNOOPYJC
       my $cs = cur_sub();
       $SpecialVarsUsed{$vn}{$cs} = 1;                       # SNOOPYJC
       if( $update ){
          $ValPerl[$tno]=$vn;                          # SNOOPYJC
          $ValType[$tno]="X";
       }
       if( $s2 eq '0' ){
         $ValType[$tno]="X";
         # SNOOPYJC - it's now the AbsPath!!  $ValPy[$tno]="__file__";
         $ValPy[$tno]="sys.argv[0]";
       }else{
          $ValType[$tno]="X";
          $ValPy[$tno]="$DEFAULT_MATCH.group($1)";		# issue 32
       }
       $cut=length($1)+1;
   } elsif( $s2 eq '#' ){
      #$source=~/^..(\w+)/;
      # issue s14 $source=~/^..\{(\w+)\}/ or $source=~/^..\$?(\w+)/ or $source=~/^..\{\$(\w+)\}/;  # Handle $#{var} $#var $#$var $#{$var}
      $source=~/^..\{(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)\}/ or           # issue s14: Handle $#Package::var
          $source=~/^..\$?(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)/ or        # issue s14
          $source=~/^..\{\$(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)\}/;  # Handle $#{var} $#var $#$var $#{$var}, issue s14
      #say STDERR "decode_scalar: source='$source', \$1=$1";
      # issue 14 $ValType[$tno]="X";
      if(!defined $1 && substr($source,2,1) eq '{') {         # issue 119: $#{expr}
          $ValClass[$tno]='f' if($update);
          $ValPerl[$tno]=substr($source,0,2) if($update);
          $ValPy[$tno] = '_last_ndx';
          $cut=2;
      } elsif(!defined $1 && substr($source,2,1) eq '+') {      # issue s16: $#+ gives the number of matching groups
          $ValPerl[$tno]=substr($source,0,2) if($update);
          $ValPy[$tno] = "len($DEFAULT_MATCH.groups())";
          $cut=3;
      } else {
          if( $update ){
             $ValPerl[$tno]=substr($source,0,2).$1; # SNOOPYJC
          }
          if( $1 eq 'ARGV'  ){                      # SNOOPYJC: Generate proper code for $#ARGV
              $ValType[$tno]="X";                   # issue 14
              $ValPy[$tno] ='(len(sys.argv)-2)';    # SNOOPYJC
          } elsif( $1 eq 'INC'  ){                  # SNOOPYJC
              $ValType[$tno]="X";
              $ValPy[$tno] ='(len(sys.path)-1)';
          } elsif($1 eq '_') {                      # issue 107
              $ValType[$tno]="X";                   # issue 14
              $ValPy[$tno] ="(len($PERL_ARG_ARRAY)-1)";    # issue 107
          } else {                                  # SNOOPYJC
              $name = $1;                       # issue s14
              substr($name,0,2) = "$MAIN_MODULE." if substr($name,0,2) eq '::';         # issue s14
              substr($name,0,1) = "$MAIN_MODULE." if substr($name,0,1) eq "'";          # issue s14
              substr($name,0,6) = "$MAIN_MODULE." if substr($name,0,6) eq 'main::';     # issue s14
              substr($name,0,5) = "$MAIN_MODULE." if substr($name,0,5) eq "main'";      # issue s14
              $name=~tr/:/./s;            # issue s14
              $name=~tr/'/./s;            # issue s14
              my $mapped_name = remap_conflicting_names($name, '@', '');      # issue 92, issue s14
	      $mapped_name = escape_keywords($mapped_name);	# issue bootstrap
              $ValPy[$tno]='(len('.$mapped_name.')-1)';       # SNOOPYJC
          }
          # SNOOPYJC $cut=length($1)+2;
          $cut=length($&);                          # SNOOPYJC
      }
  # SNOOPYJC }elsif( $source=~/^.(\w*(\:\:\w+)*)/ ){
  }elsif( $source=~/^.(\w*((?:(?:\:\:)|\')\w+)*)/ ){    # SNOOPYJC: old perl uses ' for ::
      $cut=length($1)+1;
      $name=$1;
      if(!$name) {                      # SNOOPYJC: Handle ${'name'} or ${"stuff"}
          if($::implicit_global_my) {
              $name = 'globals()';
          } else {
              $name = cur_package() . '.__dict__';
          }
          $ValType[$tno] = "X";
      }
      $ValPy[$tno]=$name;

      if( $update ){
         $ValPerl[$tno]=substr($source,0,$cut);
      }
      my $next_c = '';
      if($ate_dollar == $tno || ($tno!=0 &&                               # issue 50, issue 92
	       ($ValClass[$tno-1] eq '@' ||				  # issue bootstrap: handle @$arrref[0]
               ($ValClass[$tno-1] eq 's' && $ValPerl[$tno-1] eq '$')))) {
          ;             # Do nothing if this is like $$h_ref{key}
      } else {
          $next_c = substr($source,$cut,1);
          $next_c = substr($source,$cut+1,1) if($next_c =~ /\s/ && !$in_string);  # Handle $var {...} but not "$var {...}"
          if($in_regex && $next_c eq '[') {      # issue bootstrap: Try to distinguish between a regex character class and a subscript
             my $nnc = substr($source,$cut+1,1);
             if($nnc !~ m'[\d$]') {  # Only allow a digit or a $ sigil
                $next_c = '';
             }
         }
      }
      if( ($k=index($name,'::')) > -1 ){
          # SNOOPYJC $ValType[$tno]="X";
         if( $k==0 || substr($name,$k) eq 'main' ){
            substr($name,0,2)="$MAIN_MODULE.";
            $name=~tr/:/./s;            # SNOOPYJC
            $name=~tr/'/./s;            # SNOOPYJC
            $name = remap_conflicting_names($name, '$', $next_c);      # issue names
	    $name = escape_keywords($name);                            # issue names
            $ValPy[$tno]=$name;
            $rc=1 #regular var
         }else{
            # SNOOPYJC substr($name,$k,2)='.';
            $name=~tr/:/./s;            # SNOOPYJC
            $name=~tr/'/./s;            # SNOOPYJC
            $name = remap_conflicting_names($name, '$', $next_c);      # issue 92
	    $name = escape_keywords($name);
	    $ValPy[$tno]=$name;
            $rc=1 #regular var
         }
     } elsif( ($k=index($name,"'")) > -1 ){             # Old perl uses ' for ::
         # SNOOPYJC $ValType[$tno]="X";
         if( $k==0 || substr($name,$k) eq 'main' ){
            substr($name,0,1)="$MAIN_MODULE.";
            $name=~tr/:/./s;            # SNOOPYJC
            $name=~tr/'/./s;            # SNOOPYJC
            $name = remap_conflicting_names($name, '$', $next_c);      # issue names
	    $name = escape_keywords($name);                            # issue names
            $ValPy[$tno]=$name;
            $rc=1 #regular var
         }else{
            # SNOOPYJC substr($name,$k,1)='.';
            $name=~tr/:/./s;            # SNOOPYJC
            $name=~tr/'/./s;            # SNOOPYJC
            $name = remap_conflicting_names($name, '$', $next_c);      # issue 92
	    $name = escape_keywords($name);
	    $ValPy[$tno]=$name;
            $rc=1 #regular var
         }
      }elsif( length($name) ==1 ){
         $s2=$1;
         if( $s2 eq '_' ){
            $ValType[$tno]="X";
            my $cs = cur_sub();
            if( $source=~/^(._\s*\[\s*(\d+)\s*\])/  ){
               $ValPy[$tno]="$PERL_ARG_ARRAY".'['.$2.']';	# issue 32
               $cut=length($1);
               $SpecialVarsUsed{'@_'}{$cs} = 1;                      # SNOOPYJC
            }elsif(substr($source,2,1) eq '[' && (!$in_regex || substr($source,3,1) =~ m'[\d$]')) { # issue 107: Vararg, issue bootstrap
               $ValPy[$tno]=$PERL_ARG_ARRAY;                    # issue 107
               $cut=2;                                          # issue 107
               $SpecialVarsUsed{'@_'}{$cs} = 1;                      # issue 107
            }else{
               $ValPy[$tno]="$DEFAULT_VAR";			# issue 32
               $cut=2;
               $SpecialVarsUsed{'$_'}{$cs} = 1;                      # SNOOPYJC
            }
         }elsif( $s2 eq 'a' || $s2 eq 'b' ){
            # SNOOPYJC $ValType[$tno]="X";
	    # issue 32 $ValPy[$tno]='perl_sort_'.$s2;
            $ValPy[$tno]="$PERL_SORT_$s2";	# issue 32
            $cut=2;
         }else{
            $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '$', $next_c);      # issue 92
            $rc=1 #regular var
         }
      }else{
        # this is a "regular" name with the length greater then one
        # $cut points to the next symbol after the scanned part of the scapar
           # check for Perl system variables
           my $cs = cur_sub();
           if( $1 eq 'ENV'  ){
              $ValType[$tno]="X";
              $ValPy[$tno]='os.environ';
              $SpecialVarsUsed{'%ENV'}{$cs} = 1;                       # SNOOPYJC
	   }elsif( $1 eq 'INC' ) {				  # SNOOPYJC
              $ValType[$tno]="X";
              $SpecialVarsUsed{'@INC'}{$cs} = 1;                       # SNOOPYJC
	      $ValPy[$tno]='sys.path';
           }elsif( $1 eq 'ARGV'  ){
              $ValType[$tno]="X";
              if($cut < length($source) && substr($source,$cut,1) eq '[') {    # $ARGV[...] is a reference to @ARGV
                  $SpecialVarsUsed{'@ARGV'}{$cs} = 1;                       # SNOOPYJC
	          $ValPy[$tno]='sys.argv[1:]';
              } else {
                  $SpecialVarsUsed{'$ARGV'}{$cs} = 1;                       # SNOOPYJC
                  $ValPy[$tno]='fileinput.filename()';	# issue 49: Differentiate @ARGV from $ARGV, issue 66
              }
           }else{
             $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '$', $next_c);      # issue 92
	     $ValPy[$tno] = escape_keywords($ValPy[$tno]);	# issue 41
             $rc=1; # regular variable
           }
      }
   } else {     # SNOOPYJC: We have a '$' with nothing we recognize following it
       $cut = 1;
       $ValPy[$tno] = '$';
       $rc=0;   # Not anything good
   }
   return $rc;
}

sub is_regex
# is_regex -- Detemine if this is regex and if yes what are modifers (extract them from $source and encode in Python re.compline faschion
# the dsicvered situation is determinged by length of the return
#if there is modier then return modifier tranlated in re.complile notation (the string length is more then one)
#if this is regex but there is no modifier return 'r'
#if this is string and there is no modifier return '';
{
my $myregex=$_[0];
my (@temp,$sym,$prev_sym,$i,$modifier,$meta_no);
   $modifier='r';
   if( $source=~/^(\w+)/ ){
     $source=substr($source,length($1)); # cut modifier
     $modifier='';
     @temp=split(//,$1);
      for( $i=0; $i<@temp; $i++ ){
         # issue 11 $modifier.=',re.'.uc($temp[$i]);
         next if($temp[$i] eq 'o');             # issue s3 - ignore the 'o' flag (compile once)
         $modifier.='|re.'.uc($temp[$i]);	# issue 11
     }#for
     if( $modifier ne '' ) { $modifier =~ s/^\|/,/; } # issue 11
     $regex=1;
     $cut=0;
   }
   @temp=split(//,$myregex);
   $prev_sym='';
   $meta_no=0;
   my $cs = cur_sub();          # issue s3
   for( $i=0; $i<@temp; $i++ ){
      $sym=$temp[$i];
      if( $prev_sym ne '\\' && $sym eq '(' ){
         return($modifier,1);
      }elsif($prev_sym eq '$' && substr($myregex,$i) =~ /^(\w+)/ && exists $Pythonizer::VarType{$1} &&  # issue s3 - if this contains a variable ref, and that is a regex var, then assume it has groups
                ((exists $Pythonizer::VarType{$1}{$cs} &&  $Pythonizer::VarType{$1}{$cs} eq 'R') ||
                (exists $Pythonizer::VarType{$1}{__main__} &&  $Pythonizer::VarType{$1}{__main__} eq 'R'))) { 
         return($modifier,1);           # issue s3
      }elsif( $prev_sym ne '\\' && index('.*+()[]?^$|',$sym)>=-1 ){
        $meta_no++;
      }elsif(  $prev_sym eq '\\' && lc($sym)=~/[bsdwSDW]/){
         $meta_no++;
      }
      $prev_sym=$sym;
   }#for
   $cut=0;
   if( $meta_no>0 ){
      #regular expression without groups
      # issue 11 return ('r', 0);
      if ($modifier eq '') { $modifier = 'r'; }	# Issue 10
      return ($modifier, 0);	# issue 11
   }
   # issue 11 return('',0);
   return($modifier,0);		# issue 11
}
# Parse regex in case the opeartion is search
# ATTEMTION: this sub modifies $source curring regex modifier from it.
# At the point of invocation the regex is removed from $source (it is passed as the first parameter) so that modifier can be analysed
# if(/regex/) -- .re.match(default_var, r'regex')
# if( $line=~/regex/ )
# ($head,$tail)=split(/s/,$line)
# used from '/', 'm' and 'qr'
sub perl_match
{
my $myregex=$_[0];
my $delim=$_[1];                # issue 111
my $original_regex=$_[2];       # issue 111

my  ($modifier, $i,$sym,$prev_sym,@temp);
my  $is_regex=0;
my  $groups_are_present;
#
# Is this regex or a reguar string used in regex for search
#
   ($modifier,$groups_are_present)=is_regex($myregex);          # Returns 'r' for modifier for regex with no flags
   my $cs = cur_sub();
   if((exists $SpecialVarsUsed{'@-'} && exists $SpecialVarsUsed{'@-'}{$cs}) ||
      (exists $SpecialVarsUsed{'@+'} && exists $SpecialVarsUsed{'@-'}{$cs})) {  # SNOOPYJC
       $groups_are_present = 1          # SNOOPYJC: Enable so we set _m:=...  We don't want to set it if it's not needed because
                                        # there could be a prior search with it set, and a reference to like $1 below THIS search.
   }
   if($::debug > 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
       say STDERR "perl_match($myregex, $delim, $original_regex): modifier=$modifier, groups_are_present=$groups_are_present";
   }
   if( length($modifier) > 1 ){
      #regex with modifiers
      $quoted_regex='re.compile('.put_regex_in_quotes($myregex, $delim, $original_regex).$modifier.')';  # issue 111
   }else{
      # No modifier
      $quoted_regex=put_regex_in_quotes($myregex, $delim, $original_regex);      # issue 111
   }
   if( length($modifier)>0 ){
      #this is regex
      if( $tno>=1 && $ValClass[$tno-1] eq '~' ){
         # explisit or implisit '~m' can't be at position 0; you need the left part
         if( $groups_are_present ){
            return "($DEFAULT_MATCH:=re.search(".$quoted_regex.','; #  we need to have the result of match to extract groups.	# issue 32, 75
         }else{
           return '(re.search('.$quoted_regex.','; #  we do not need the result of match as no groups is present. # issue 75
         }
      # issue 93 }elsif( $ValClass[$tno-1] eq '0'  ||  $ValClass[$tno-1] eq '(' ){
      # issue 124 }elsif( $tno>=1 && ($ValClass[$tno-1] =~ /[0o]/  ||  $ValClass[$tno-1] eq '(' || $ValClass[$tno-1] eq '=') ){      # issue 93, SNOOPYJC: Handle assignment of regex with default var and groups
      } else {          # issue 124
            # this is calse like || /text/ or while(/#/)
         if( $groups_are_present ){
                return "($DEFAULT_MATCH:=re.search(".$quoted_regex.",$CONVERTER_MAP{S}($DEFAULT_VAR)))"; #  we need to have the result of match to extract groups. # issue 32, issue s8
         }else{
           return 're.search('.$quoted_regex.",$CONVERTER_MAP{S}($DEFAULT_VAR))"; #  we do not need the result of match as no groups is present.	# issue 32, 75, issue s8
         }
      # issue 124 }else{
         # issue 124 return 're.search('.$quoted_regex.",$DEFAULT_VAR)"; #  we do not need the result of match as no groups is present.	# issue 32, 75
      }
   }else{
      # this is a string
      $ValClass[$tno]="'";
      return '.find('.escape_quotes(escape_non_printables($myregex,0)).')';
   }

} # perl_match

sub popup
#
# Remove the last item from stack
#
{
    #say STDERR "popup ValClass=@ValClass";
   return unless ($#ValClass>0);
   pop(@ValClass);
   pop(@ValPerl);
   pop(@ValPy);
   pop(@ValCom);
   if($#ValType > $#ValClass) {     # issue 37
       pop(@ValType);	# issue 37
   }
}

sub single_quoted_literal
# ATTENTION: returns position after closing bracket
# A backslash represents a backslash unless followed by the delimiter or another backslash,
# in which case the delimiter or backslash is interpolated.
{
# issue 39 ($closing_delim,$offset)=@_;
my ($closing_delim,$offset)=@_;		# issue 39
my ($m,$sym);
# The problem is decomposting single quotes string is that for brackets closing delimiter is different from opening
# The second problem is that \n in single quoted string in Perl means two symbols and in Python a single symbol (newline)
      return -1 if ($offset>length($source));
      if(index('{[(<',$closing_delim)>-1){
         $closing_delim=~tr/{[(</}])>/;
      }
      $opening_delim = undef;                   # issue 83
      if(index('}])>',$closing_delim)>-1) {     # issue 83
        $opening_delim = $closing_delim;        # issue 83
        $opening_delim =~ tr/}])>/{[(</;        # issue 83
      }                                         # issue 83
      my $nest = 0;                             # issue 83: Need to count nested brackets if they match the delim
      $start_line = $.;			# issue 39
      while (1) {			# issue 39
      	# only backlashes are allowed
        #say STDERR "single_quoted_literal($source, $closing_delim, $offset), opening_delim=$opening_delim, nest=$nest";
      	for($m=$offset; $m<=length($source); $m++ ){
            #say STDERR "sym = $sym";
           $sym=substr($source,$m,1);
	   # issue 39 last if( $sym eq $closing_delim && substr($source,$m-1,1) ne '\\' );
           if( $sym eq "\\") {              # issue 39: Properly skip escaped things like \\ and \'
               $m++;
               next;
           }
           if( defined $opening_delim && $sym eq $opening_delim ) {   # issue 83
               $nest++;                         # issue 83
               next;                            # issue 83
           }                                    # issue 83
           if( $sym eq $closing_delim ) {			# issue 39, issue 83
               if($nest <= 0) {                 # issue 83
                   return $m+1; # this is first symbol after closing quote		# issue 39
               }                                # issue 83
               $nest--;                         # issue 83
	   }										# issue 39
      	}
	# issue 39: if we get here, we ran out of road - grab the next line and keep going!
        my @tmpBuffer = @BufferValClass;	# SNOOPYJC: Must get a real line even if we're buffering stuff
        @BufferValClass = ();		        # SNOOPYJC
	$line = Pythonizer::getline();		# issue 39
        @BufferValClass = @tmpBuffer;	        # SNOOPYJC
	if(!$line) {				# issue 39
	    logme('S', "Unterminated string starting at line $start_line");		# issue 39
	    return $m+1;			# issue 39
	}					# issue 39
	$source .= "\n" . $line;		# issue 39
	$offset = $m;				# issue 39
      }						# issue 39
}#sub single_quoted_literal

#::double_quoted_literal -- decompile double quted literal
# parcial implementation; full implementation requires two pass scheme
# Returns cut
# As a side efecct populates $ValPerl[$tno] $ValPy[$tno]
#
sub double_quoted_literal
{
($closing_delim,$offset)=@_;
my ($k,$quote,$close_pos,$ind,$result,$prefix);
   if( $closing_delim=~tr/{[>// ){
      $closing_delim=~tr/{[(</}])>/;
   }
   $close_pos=single_quoted_literal($closing_delim,$offset); # first position after quote
   $quote=substr($source,$offset,$close_pos-1-$offset); # extract literal
   my $pre_escaped_quote = $quote;                               # SNOOPYJC
   $quote=remove_escaped_delimiters($closing_delim, $quote);     # issue 51
   $ValPerl[$tno]=$quote; # also will serve as original
   if (length($quote) == 1 ){
      $ValPy[$tno]=escape_quotes(escape_non_printables($quote,0),2);
      return $close_pos;
   }
   return interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, 0);     # issue 39
}

sub interpolate_strings                                         # issue 39
# Interpolate variable references in strings
{
# Args:
   my $quote = shift;                   # The value WITHOUT the quotes
   my $pre_escaped_quote = shift;       # Same but with any \" inside not escaped
   my $close_pos = shift;               # First position AFTER the closing quotes
   my $offset = shift;                  # How long the opening is, e.g. 1 for ", 3 for qq/
   my $in_regex = shift;                # 1 if we're in a regex and \$ needs to remain as \$
# Result = normally $close_pos, but can point earlier in the string if we need to tokenize part of it
# in order to check for references (in the first pass only).
#
# Also $ValPy[$tno] is set to the code to be generated for this string

   if($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
       say STDERR ">interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)";
   }
   my ($l, $k, $ind, $result, $pc, $prev);
   local $cut;                  # Save the global version of this!
   $prev = '';
   $quote = interpolate_string_hex_escapes(escape_non_printables($quote,0));                     # SNOOPYJC: Replace \x{ddd...} with python equiv
   #
   # decompose all scalar variables, if any, Array and hashes are left "as is"
   #
   $k=index($quote,'$');
   if( $Pythonizer::PassNo == &Pythonizer::PASS_0 || (($k==-1 || $k == length($quote)-1) && index($quote, '@') == -1)){             # issue 47, SNOOPYJC: Skip if first '$' is the last char, like in a regex
      # case when double quotes are used for a simple literal that does not reaure interpolation
      # Python equvalence between single and doble quotes alows some flexibility
      $ValPy[$tno]=escape_quotes(remove_perl_escapes($quote,$in_regex),2); # always generate with quotes --same for Python 2 and 3
      if($Pythonizer::PassNo != &Pythonizer::PASS_0) {
         say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)=$close_pos, ValPy[$tno]=$ValPy[$tno]" if($::debug >=3);
      }
      return $close_pos;
   }
   # SNOOPYJC: In the first pass, extract all variable references and return them as separate tokens
   # so we can mark their references, and add things like initialization.
   # If we're handling a here_is document, or a regex, we don't do this (but we probably should: $close_pos == 0)
   if($Pythonizer::PassNo == &Pythonizer::PASS_1 && $close_pos != 0) {                       # SNOOPYJC
       my $pos = extract_tokens_from_double_quoted_string($pre_escaped_quote,1)+$offset;
       if($ExtractingTokensFromDoubleQuotedStringEnd > 0) {
          $ExtractingTokensFromDoubleQuotedStringEnd += $offset;
          say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)=$pos (begin extract mode)" if($::debug >=3);
          return $pos;
       }
    } elsif($Pythonizer::PassNo==&Pythonizer::PASS_1 && $last_varclass_lno != $. && $last_varclass_lno) {
	# We don't capture regex's or here_is documents so just grab the last line_varclasses and propagate it down here
        # If we don't do this and there ARE variable references in the string, we won't properly map them if
        # they need the package name added.
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
        $last_varclass_lno = $.;
    }

   #	# issue bootstrap
   #decode each part. Double quote literals in Perl are ver difficult to decode
   # This is a parcial implementation of the most common cases
   # Full implementation is possible only in two pass scheme
my  $outer_delim;
    $quote = escape_curly_braces($quote);        # issue 51
    # issue 47 $k=index($quote,'$');                        # issue 51 - recompute in case it moved
    $k = -1;                            # issue 47
    if($quote =~ m'[$@]') {             # issue 47
        $k = $-[0];                     # issue 47: Match pos
    }

    if (index($quote,'"')==-1 && index($quote, "\n")==-1){      # issue multi-line here
       $outer_delim='"'
    # issue 53: we use single quotes in our 'bareword' so we can't use them here if we have {...}
    }elsif(index($quote,"'")==-1 && index($quote,'{')==-1 && index($quote,"\n")==-1){     # issue 53, multi-line here
      $outer_delim="'";
    }else{
      $outer_delim='"""';
    }
   $result='f'.$outer_delim; #For python 3 we need special opening quote
   $prev = '';
   my ($sig, $dot);                     # issue 47
   while( $k > -1  ){
      $sig = substr($quote,$k,1);       # issue 47
      if( $k > 0 ){
         $pc = substr($quote,$k-1,1);   # issue 47
         if(is_escaped($quote,$k)) {    # issue 47
            # escaped $ or @
            # issue 51 $k=index($quote,'$',$k+1);
            if($in_regex && $sig eq '$') {                     # issue 111: \$ remains \$ in regex, but \@ changes to @
                if(substr($quote,$k+1) =~ m'[$@]') {           # issue 47
                    $k += 1+$-[0];                             # issue 47: Match pos
                } else {                            # issue 47
                    $k = -1;                        # issue 47
                }                                   # issue 47
            } else {
                substr($quote,$k-1,1) = '';         # issue 51 - eat the escape
                # issue 47 $k=index($quote,'$',$k);            # issue 51
                if(substr($quote,$k) =~ m'[$@]') {             # issue 47
                    $k += $-[0];                               # issue 47: Match pos
                } else {                            # issue 47
                    $k = -1;                        # issue 47
                }                                   # issue 47
            }
            next;
         }else{
            if( $sig eq '@' && $pc =~ /\w/ && ($dot=index($quote,'.'))!=-1) { # Probable email address xyz@abc.com
                logme('W',"Possible unintended interpolation of " . substr($quote,$k,$dot-$k) . " in string");
            }
            # we have the first literal string  before varible
            $result.=remove_perl_escapes(substr($quote,0,$k),$in_regex); # issue bootstrap
         }
      }
      $quote=substr($quote,$k);
      if($quote eq $sig || (substr($quote,0,1) eq $sig && substr($quote,1) =~ /^\s+$/)) {   # issue 111: Handle "...$"
          $result.=$quote;
          $quote = '';
          last;
      }
      $result.='{';  # we always need '{' for f-strings
      #say STDERR "quote1=$quote\n";
      my $end_br = -1;				# issue 43
      if(substr($quote,1,1) eq '{') {		# issue 43: ${...}
         $end_br = matching_curly_br($quote, 1); # issue 43
         if(substr($quote,2,2) eq "\\(" && $end_br != -1) {
             $result .= handle_expr_in_string($quote, 3);        # ${\(expr_in_scalar_context)}
             $cut = $end_br;
             $end_br++;
             $sig = '';
         } else {
            $quote = $sig . substr($quote,2);	# issue 43: eat the '{'. At this point, $end_br points after the '}', issue 47
         }
         #say STDERR "quote1a=$quote, end_br=$end_br\n";
      }
      if($sig eq '$') {                 # issue 47
         my $s2=substr($quote,1,1);                   # issue ws after sigil
         if($s2 eq '' || $s2 =~ /\s/) {               # issue ws after sigil
            my $q2 = get_rest_of_variable_name($quote, 1);
            if($q2 ne $quote) {
               my $adjust = length($quote) - length($q2);
               #$close_pos -= $adjust;
               if($end_br > 0) {
                   $end_br -= $adjust;
               }
            }
            $quote = $q2;
         }
         decode_scalar($quote,0,1,$in_regex); #get's us scalar or system var, 0=don't update, 1=in_string
         if($cut == 1) {     # Just a '$' with no variable
            substr($result,-1,1) = '';      # Remove the '{'
            substr($quote,$end_br-1,1) = '' if($end_br >= 0);
            $quote=substr($quote,$cut);
            $k = -1;                            # issue 47
            if($quote =~ m'[$@]') {             # issue 47
                $k = $-[0];                     # issue 47: Match pos
            }
            if($k == 0) {
                $prev = '$';
                $ate_dollar = $tno;
            } else {
                $result .= '$';         # SNOOPYJC: If we have $$, then just eat the first one
            }
            next;
         } elsif($in_regex && $cut == 2 && substr($quote,0,2) eq '$)') {        # '$' at the end of a capture group!
            substr($result,-1,1) = '';      # Remove the '{'
            substr($quote,$end_br-1,1) = '' if($end_br >= 0);
            $quote=substr($quote,$cut);
            $k = -1;                            # issue 47
            if($quote =~ m'[$@]') {             # issue 47
                $k = $-[0];                     # issue 47: Match pos
            }
            $result .= '$)';
            next;
         }

         #does not matter what type of variable this is: regular or special variable
         #my $next_c = substr($quote,$cut,1);
         #if($next_c eq '[') {
         #substr($ValPerl[$tno],0,1) = '@';
         #} elsif($next_c eq '{') {
         #substr($ValPerl[$tno],0,1) = '%';
         #}
         my $next_c = substr($quote,$cut,1);    # SNOOPYJC
         if($in_regex && $next_c eq '[') {      # SNOOPYJC: Try to distinguish between a regex character class and a subscript
             my $nnc = substr($quote,$cut+1,1);
             if($nnc !~ m'[\d$]') {  # Only allow a digit or a $ sigil
                $next_c = '';
		#if($ValPy[$tno] eq $PERL_ARG_ARRAY) {   # We goofed in decode_scalar - fix it
		#$ValPy[$tno]="$DEFAULT_VAR";
		#my $cs = cur_sub();
		#$SpecialVarsUsed{'$_'}{$cs} = 1;
		#}
             }
         }
         add_package_name(get_perl_name(substr($quote,0,$cut), $next_c, $prev));        # SNOOPYJC
         if($prev eq '@') {     # this was like @$var or @{$var}
            my $ls = 'LIST_SEPARATOR';
            $ls = $PERLLIB . '.' . $ls if($::import_perllib);
            $result.="$ls.join(map(_str,$ValPy[$tno]"; # Note - the parens are closed below by checking if $prev eq '@' again
         } else {
            $result.=$ValPy[$tno]; # copy string provided by decode_scalar. ValPy[$tno] changes if Perl contained :: like in $::debug
            my $cs = cur_sub();          # issue s3
            if($in_regex && exists $Pythonizer::VarType{$ValPy[$tno]} && 
                ((exists $Pythonizer::VarType{$ValPy[$tno]}{$cs} &&  $Pythonizer::VarType{$ValPy[$tno]}{$cs} eq 'R') ||
                (exists $Pythonizer::VarType{$ValPy[$tno]}{__main__} &&  $Pythonizer::VarType{$ValPy[$tno]}{__main__} eq 'R'))) {       # issue s3
                $result.= '.pattern';           # issue s3: decompile an embedded regex
            }
         }
         #$prev = '';
      } elsif($sig eq '@') {                          # issue 47: '@'
          #say STDERR "end_br=$end_br, quote=$quote";
         if($end_br > 0 && substr($quote,0,3) eq '@[%' && substr($quote,3,1) =~ /[\w:]/) {  # @{[%hash]}
            $quote = substr($quote, 2);
            decode_hash($quote);
            add_package_name(substr($quote,0,$cut));            # SNOOPYJC
            # SNOOPYJC $ValPy[$tno] = 'functools.reduce(lambda x,y:x+y,'.$ValPy[$tno].'.items())';
            $ValPy[$tno] = "map(_str,itertools.chain.from_iterable($ValPy[$tno].items()))";     # SNOOPYJC
            $end_br -= 2;    # 2 to account for the 2 we ate
            #say STDERR "quote1b=$quote, end_br=$end_br\n";
         } elsif($end_br > 0 && substr($quote,0,2) eq '@[') {
             $ValPy[$tno] = handle_expr_in_string($quote, 1);        # @{[expr_in_list_context]} 
             $cut = $end_br;
         } elsif($end_br > 0 && substr($quote,0,3) eq '@ [') {
             $ValPy[$tno] = handle_expr_in_string($quote, 2);        # @{ [expr_in_list_context] } 
             $cut = $end_br;
         } else {
            decode_array($quote); #get's us array or system var
            if($cut == 1) {     # Just a '@' with no variable
                substr($result,-1,1) = '';      # Remove the '{'
                substr($quote,$end_br-1,1) = '' if($end_br >= 0);
                $quote=substr($quote,$cut);
                $k = -1;                            # issue 47
                if($quote =~ m'[$@]') {             # issue 47
                    $k = $-[0];                     # issue 47: Match pos
                }
                if($k == 0) {             # SNOOPYJC: If we have @$, then just eat the '@', but remember for the next round
                    $prev = '@';
                } else {
                    $result .= '@'
                }
                next;
            }
            add_package_name(substr($quote,0,$cut));            # SNOOPYJC
         }
         #does not matter what type of variable this is: regular or special variable
         my $ls = 'LIST_SEPARATOR';
         $ls = $PERLLIB . '.' . $ls if($::import_perllib);
         $result.="$ls.join(map(_str,$ValPy[$tno]))"; # copy string provided by decode_array. ValPy[$tno] changes if Perl contained :: like in $::debug
      }

      $quote=substr($quote,$cut); # cure the nesserary number of symbol determined by decode_scalar.
      $end_br -= $cut;			# issue 43
      if($sig eq '$') {                 # issue 47
          #say STDERR "quote2=$quote, result1=$result, end_br=$end_br";
          my $p_len = length($quote);                       # issue 13, 43
          {
             no warnings 'uninitialized';
             $quote =~ s/(?<![{\$])(->)?\{([A-Za-z_][A-Za-z0-9_]*)\}/$1\{\'$2\'\}/g;     # issue 13: Remove bare words in $hash{...}
          }
          my $n_len = length($quote);
          if($end_br >= 0 && $n_len > $p_len) {             # issue 13, 43  it grew so move the pointer over
              $end_br += ($n_len - $p_len);                 # issue 13, 43
          }                                                 # issue 13, 43
          #say STDERR "quote3=$quote";
          # issue 98 if( $quote=~/^\s*([\[\{].+?[\]\}])/  ){
          #if( $quote=~/^([\[\{].+?[\]\}])/  ){              # issue 98: Don't allow spaces before the [ or {
             #HACK element of the array of hash. Here we cut corners and do not process expressions as index.
             #$ind=$1;
          
          my $nx3 = substr($quote,0,3);
          if($nx3 eq '->[' || $nx3 eq '->{') {   # Move past any '->' that ends in a '[' or '{'
             $quote = substr($quote,2);
             $end_br -= 2;
             #say STDERR "Removing ->";  # TEMP
          }
          #$quote =~ s/->([\[{])/$1/g;           # Remove all '->' that ends in '[' or '{'
          #say STDERR "quote=$quote";    # TEMP
          my $next_c = substr($quote,0,1);    # SNOOPYJC
          if(($ValPy[$tno] eq "$DEFAULT_MATCH.start" || $ValPy[$tno] eq "$DEFAULT_MATCH.end" || $ValPy[$tno] eq "$DEFAULT_MATCH.group") &&
              index('{[', $next_c) >= 0) {          # issue s16: Change the brackets to parens for these special cases
              if($next_c eq '{') {
                 $l = matching_curly_br($quote, 0);
              } else {
                 $l = matching_square_br($quote, 0);
              }
              if($l >= 0) {
                 if($next_c eq '{') {   # we already doubled the '{' to '{{' so we have to undo that
                    $quote =~ s/\{([A-Za-z_][A-Za-z0-9_]*)\}/{'$1'}/;   # Quote bare words
                    $l = matching_curly_br($quote, 0);          # We may have shifted it over
                    substr($quote,$l-1,2) = ')';
                    substr($quote,0,2) = '(';
                    $l -= 2;
                 } else {
                    substr($quote,0,1) = '(';
                    substr($quote,$l,1) = ')';
                 }
                 $next_c = '';
                 $result .= substr($quote,0,$l+1);
                 $quote=substr($quote,$l+1);
              }
          }
          my $quote2 = $quote;
          if($in_regex && $next_c eq '[') {      # SNOOPYJC: Try to distinguish between a regex character class and a subscript
              my $nnc = substr($quote,1,1);
              $quote2 = '' if($nnc !~ m'[\d$]');  # Only allow a digit or a $ sigil
          }
          while($ind = extract_bracketed($quote2, '{}[]', '')) {        # issue 53, issue 98
             # issue 109 $cut=length($ind);
             my $ind_cut=length($ind);
             # issue 109 $ind =~ tr/$//d;               # We need to decode_scalar on each one!
             # issue 53 $ind =~ tr/{}/[]/;
             #say STDERR "looking for '{' in $ind";      # TEMP
             for(my $i = 0; $i < length($ind); $i++) {	# issue 53: change hash ref {...} to use .get(...) instead
                 my $c = substr($ind,$i,1);                 # issue 109
                 if($c eq '-' && substr($ind,$i+1,1) eq '>') {  # issue refs in strings
                     substr($ind,$i,2) = '';    # eat '->'
                     $c = substr($ind,$i,1);
                 }
                 if($c eq '{') {		# issue 53
                     $l = matching_curly_br($ind, $i);	# issue 53
                     #say "found '{' in $ind at $i, l=$l";
                     next if($l < 0);			# issue 53
                     $ind = substr($ind,0,$i).'.get('.substr($ind,$i+1,$l-($i+1)).",'')".substr($ind,$l+1);	# issue 53: splice in the call to get
                     #say "ind=$ind";
                     # issue 109 $i = $l+7;				# issue 53: 7 is length('.get') + length(",''")
                 } elsif($c eq '$') {                       # issue 109: decode special vars in subscripts/hash keys
                     my $var = substr($ind,$i);
                     #say STDERR "var=$var";     # TEMP
                     if(substr($var,1,1) eq '{') {      # SNOOPYJC: like ${i}
                         $l = matching_curly_br($var, 1);
                         if($l > 0) {                   # SNOOPYJC: Eat both the '{' and the '}'
                             substr($ind,$l+1,1) = '';
                             substr($ind,$i+1,1) = '';
                             $var = substr($ind,$i);
                         }
                         #say STDERR "var=$var, ind=$ind";
                     }
                     my $pr = '';
                     decode_scalar($var,0,1);     # issue 109
                     if($cut == 1) {     # Just a '$' with no variable
                        $pr = '$';
                        $var = substr($ind,$i+1);
                        substr($ind,$i,1) = '';
                        decode_scalar($var,0,1);          # Try again
                     }
                     add_package_name(get_perl_name(substr($var,0,$cut), substr($var,$cut,1), $pr));     # SNOOPYJC
                     substr($ind,$i,$cut) = $ValPy[$tno];   # issue 109
                     $i += (length($ValPy[$tno])-$cut);     # issue 109
                 }
             }						# issue 53
             $result.=$ind; # add string Variable part of the string
             # issue 109 $quote=substr($quote,$cut);
             $quote=substr($quote,$ind_cut);        # issue 109
             $nx3 = substr($quote,0,3);
             if($nx3 eq '->[' || $nx3 eq '->{') {   # Move past any '->' that ends in a '[' or '{'
                $quote = substr($quote,2);
                $end_br -= 2;
                #say STDERR "Removing ->";  # TEMP
             }
             $quote2 = $quote;
             $end_br -= $ind_cut;			# issue 43
             #say STDERR "quote4=$quote, end_br=$end_br";        # TEMP
          }
          if($prev eq '@') {
              $result.='))';     # Close the join/map operator inserted above
          }
          $prev = '';
      }
      #say STDERR "quote5=$quote, end_br=$end_br";
      $quote = substr($quote, $end_br) if($end_br > 0);	# issue 43
      $result.='}'; # end of variable
      # issue 47 $k=index($quote,'$'); #next scalar
      $k = -1;                            # issue 47
      if($quote =~ m'[$@]') {             # issue 47
          $k = $-[0];                     # issue 47: Match pos
      }
   }

   if( length($quote)>0  ){
       #the last part
       $result.=remove_perl_escapes($quote,$in_regex);	# issue bootstrap
   }
   if($outer_delim eq '"""') {
      if(substr($result,-1,1) eq '"' && !is_escaped($result, length($result)-1)) {  # SNOOPYJC: quote at end - we have to fix this!
          $result = substr($result,0,length($result)-1)."\\".'"';
      }
      $result = 'f"""' . escape_triple_doublequotes(substr($result,4));
   }
   $result.=$outer_delim;
   #say STDERR "double_quoted_literal: result=$result";
   $ValPy[$tno]=$result;
   say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)=$close_pos, ValPy[$tno]=$ValPy[$tno]" if($::debug >=3);
   return $close_pos;
}

sub handle_expr_in_string
# Handle some limited cases of expressions in strings
# where the user is using the syntax ${\(expr_in_scalar_context)} -or- @{[expr_in_list_context]}
{
    my $string = shift;
    my $start = shift;          # Points to the '(' or the '['

    return '' if $Pythonizer::PassNo != &Pythonizer::PASS_2;

    say STDERR ">handle_expr_in_string($string, $start)" if($::debug);
    my $save_tno = $tno;
    my $save_source = $source;
    my $set = $::saved_eval_tokens;
    $::saved_eval_tokens = 1;   # used to freeze getline

    my $d = substr($string, $start, 1);
    my $limit = -1;
    $limit = matching_paren($string, $start) if($d eq '(');
    $limit = matching_square_br($string,$start) if ($d eq '[');
    my $code = '';
    if($limit != -1) {
        $start++;               # point past the '(' or '['
        my $line = substr($string, $start, $limit-$start);
        my $saved_tokens = &::package_tokens();
        save_code();
        my $t_start = scalar(@ValClass);
        tokenize($line, 1);
        my $was_hash = 0;
        $was_hash = 1 if($ValClass[$t_start] eq '%');
        &::remove_dereferences();
        $::TrStatus = &::expression($t_start, $#ValClass, 0);
        &::unpackage_tokens($saved_tokens);
        $code = format_chunks();
        $code = remove_oddities($code);
        $code = "map(_str,itertools.chain.from_iterable($code.items()))" if($was_hash);
        restore_code();
    }

    $::saved_eval_tokens = $set;   # unfreeze
    $source = $save_source;
    $tno = $save_tno;
    say STDERR "<handle_expr_in_string($string, $start) = $code" if($::debug);
    return $code;
}

sub extract_tokens_from_double_quoted_string
# In the first pass, extract variable references from double-quoted strings as separate tokens
# so we can mark references to them, etc.
#
# arg1 = contents of the string
# arg2 = 1 if this is the initial call, else 0
#
# Adds the tokens directly to $ValXXX[$tno] and increments $tno.
# Surrounds the tokens with a " (string) token, even if empty so that
# the expression analyzer doesn't try to match neighboring operators.
# When we come in, $ValClass[$tno] is already set to "
{
    my $quote = shift;
    my $initial = shift;

    say STDERR ">extract_tokens_from_double_quoted_string($quote,$initial)" if($::debug>=3);
    $ExtractingTokensFromDoubleQuotedStringTnoStart = $tno if($initial);
    if(($pos = unescaped_match($quote, qr'[$@]')) >= 0) {
    #if($quote =~ m'[$@]' && !is_escaped($quote, $-[0])) {
        #my $pos = $-[0];
        $ValPy[$tno] = 'f"""' . substr($quote,0,$pos) . '"""';
        if($ExtractingTokensFromDoubleQuotedStringEnd <= 0) {
            # First time around, just get things ready for the next time
            $ExtractingTokensFromDoubleQuotedStringEnd = length($quote);
            say STDERR " ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd" if($::debug>=5);
            say STDERR "<extract_tokens_from_double_quoted_string($quote) result=$pos" if($::debug>=3);
            return $pos;
        } elsif($pos != 0) {
            # We have some stuff before the next sigil
            $ValPerl[$tno] = substr($quote,0,$pos);
            if( $::debug >= 3  ){
                say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
            }
            $tno++;
            say STDERR "<extract_tokens_from_double_quoted_string($quote) result=$pos" if($::debug>=3);
            return $pos;
        }
        my $sigil = substr($quote,$pos,1);
        my $end_br = -1;
        my $adjust = 0;
        if(substr($quote,$pos+1,1) eq '{') {    # issue 43: ${...}
            $end_br = matching_curly_br($quote, $pos+1); # issue 43
            $adjust = 1;
            if(substr($quote,$pos+2,2) eq '\\(') {      # ${\(...)}
                $sigil = '';
                $cut = 3;
                substr($quote,$end_br,1) = '';  # Eat the }
                $end_br = -1;
            } elsif(substr($quote,$pos+2,1) eq '[') {   # @{[...]}
                $sigil = '';
                $cut = 2;
                substr($quote,$end_br,1) = '';
                $end_br = -1;
            } elsif(substr($quote,$pos+2,2) eq ' [') {  # @{ [...] }
                $sigil = '';
                $cut = 3;
                substr($quote,$end_br,1) = '';
                $end_br = -1;
            } elsif(substr($quote,$pos+2,1) eq '$') {   # @{$...}
                $sigil = '';
                $cut = 2;
                $end_br--;
                substr($quote,$end_br,1) = '';
            } else {
                $adjust = 0;
                $quote = '$'.substr($quote,2);		# issue 43: eat the '{'. At this point, $end_br points after the '}'
            }
        }
        if($sigil eq '$') {
            my $s2=substr($quote,1,1);                   # issue ws after sigil
            if($s2 eq '' || $s2 =~ /\s/) {               # issue ws after sigil
               my $q2 = get_rest_of_variable_name($quote, 1);
               if($q2 ne $quote && $end_br > 0) {
                   $end_br -= length($quote) - length($q2);
               }
               $quote = $q2;
            }
            decode_scalar($quote, 1,1);
            #say STDERR "ValClass[$tno]=$ValClass[$tno], ValPy[$tno]=$ValPy[$tno]";      # TEMP
        } elsif($sigil eq '@') {
            decode_array($quote);
            $ValClass[$tno] = 'a' if $cut != 1; # issue ddts
        }
        $ValPerl[$tno] = substr($quote, 0, $cut);
        my $m;
        if($cut < length($quote) && $sigil ne '') {
            my $nx3 = substr($quote,$cut,3);
            if($nx3 eq '->[' || $nx3 eq '->{') {   # Move past any '->' that ends in a '[' or '{'
                $cut += 2;
            }
            my $d = substr($quote,$cut,1);
            while($d eq '[' || $d eq '{') {
                $m = matching_curly_br($quote,$cut) if ($d eq '{');
                $m = matching_square_br($quote,$cut) if ($d eq '[');
                last if($m < 0);        # Not a match
                $d = substr($quote,$m,1);
                $cut=$m+1;
            }
        }
        if($end_br != -1) {
            #$cut++;                     # Point past the extra '}'
            $ExtractingTokensFromDoubleQuotedTokensEnd = $cut-2;
            $cut = $end_br;
        } else {
            $ExtractingTokensFromDoubleQuotedTokensEnd = $cut;
        }
        $ExtractingTokensFromDoubleQuotedStringEnd = length($quote) + $adjust;
        say STDERR " ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd" if($::debug>=5);
        say STDERR "<extract_tokens_from_double_quoted_string($quote) end=$cut, result=$pos" if($::debug>=3);
        return $pos;
    } elsif($initial) {       # First time and we found nothing to do
        $ExtractingTokensFromDoubleQuotedStringEnd = 0;
        say STDERR " ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd" if($::debug>=5);
        $pos = -1;
        say STDERR "<extract_tokens_from_double_quoted_string($quote) result=$pos (nothing to do)" if($::debug>=3);
        return $pos;
    } else {
        my $balance = 0;                # We must generate a balance of brackets else the scanning gets messed up and doesn't stop on the ';'
        for(my $i = $tno-1; $i >= 0; $i--) {
            if($ValClass[$i] eq ')') {
                $balance--;
            } elsif($ValClass[$i] eq '(') {
                $balance++;
            }
            last if($i eq $ExtractingTokensFromDoubleQuotedStringTnoStart);
        }
        while($balance > 0) {
            $ValPerl[$tno] = $ValPy[$tno] = $ValClass[$tno] = ')';      # We don't care that it may not be the right kind of bracket
            $balance--;
            if( $::debug >= 3  ){
               say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy)," (extractClose)";
            }
            $tno++;
        }
        while($balance < 0) {
            $ValPerl[$tno] = $ValPy[$tno] = $ValClass[$tno] = '(';      # We don't care that they are not in the right order
            $balance++;
            if( $::debug >= 3  ){
               say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy), " (extractOpen)";
            }
            $tno++;
        }
        $ValClass[$tno] = '"';
        $ValPerl[$tno] = $quote;
        $ValPy[$tno] = 'f"""' . $ValPerl[$tno] . '"""';
        $ExtractingTokensFromDoubleQuotedTokensEnd = -1;
        $ExtractingTokensFromDoubleQuotedStringEnd = 0;
        if( $::debug >= 3  ){
           say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy), " (extract)";
        }
        $tno++;
        say STDERR " ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd" if($::debug>=5);
        say STDERR "<extract_tokens_from_double_quoted_string($quote) end=-1, result=".(length($quote)+1) if($::debug>=3);
        return length($quote)+1;
    }
}

sub unescaped_match
# Given a string and a regex to match, return the position of the next unescaped match
{
    my $string = shift;
    my $pat = shift;

    for(my $i = 0; $i < length($string); $i++) {
        my $ch = substr($string,$i,1);
        if($ch eq "\\") {       # Skipped escaped chars
            $i++;
            next;
        }
        return $i if($ch =~ $pat);
    }
    return -1;
}

sub escape_curly_braces                 # issue 51
# If the string already has {...} in it, replace them with {{...}} for f strings
# Make sure NOT to replace ${...} and @{...} as they have special meaning
# Also don't mess with $hash{...} or $arrhash[...]{...} or $hashhash{...}{...}
# And one more type not to mess with: $hashref->{...} or $arrayref->[...]
{
    my $str = shift;
    #say STDERR "escape_curly_braces($str)";

    my $in_id = 0;
    for(my $k = 0; $k < length($str); $k++) {
        my $c = substr($str,$k,1);
        if($c eq '$' && substr($str, $k+1) =~ /^(\:?\:?\w+(\:\:\w+)*)/) {
            $k += length($1);
            while($k+1 < length($str)) {
                my $nx3 = substr($str,$k+1,3);
                if($nx3 eq '->[' || $nx3 eq '->{') {   # Move past any '->' that ends in a '[' or '{'
                    $k += 2;
                }
                my $d = substr($str,$k+1,1);
                my $m = -1;
                $m = matching_curly_br($str,$k+1) if ($d eq '{');
                $m = matching_square_br($str,$k+1) if ($d eq '[');
                if($m >= 0) {
                    $k = $m 
                } else {
                    last;
                }
            }
        }
        if($c eq '{') {
            if($k == 0 || index('$@', substr($str,$k-1,1)) < 0) {
                substr($str,$k,0) = '{';
                $k++;
            } else {
                my $m = matching_curly_br($str, $k);
                $k = $m if($m >= 0);
            }
        } elsif($c eq '}') {
            substr($str,$k,0) = '}';
            $k++;
        }
    }

    #say STDERR "escape_curly_braces=$str";
    return $str;
}

sub remove_escaped_delimiters            # issue 51
# Given a string and a delimiter, remove all escaped instances of the given delimiter
{
    my $delim = shift;
    my $str = shift;

    if(index('{[(<',$delim)>-1){
         $delim=~tr/{[(</}])>/;         # Swap it!
    }

    for(my $k = index($str, "\\"); $k >= 0; $k = index($str, "\\", $k+1)) {
        if($k+1 < length($str) && substr($str, $k+1, 1) eq $delim) {
            substr($str, $k, 1) = '';           # change \' to '
        }
    }
    return $str;
}

sub decode_array                # issue 47
{
    my $source = shift;

     if( substr($source,1)=~/^(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)/ ){
        $arg1=$1;
        if($arg1 =~ /^\d/ && $Pythonizer::PassNo == &Pythonizer::PASS_2) {            # like @2017
            logme('W', "Numeric array variable \@$arg1 detected - please check this is what you want here!");
        }
        if( $arg1 eq '_' ){
           $ValPy[$tno]="$PERL_ARG_ARRAY";	# issue 32
           #$ValType[$tno]="X";
        }elsif( $arg1 eq 'INC'  ){		# SNOOPYJC
              $ValPy[$tno]='sys.path';
              my $cs = cur_sub();
              $SpecialVarsUsed{'@INC'}{$cs} = 1;                       # SNOOPYJC
              #$ValType[$tno]="X";
        }elsif( $arg1 eq 'ARGV'  ){
                # issue 49 $ValPy[$tno]='sys.argv';
              $ValPy[$tno]='sys.argv[1:]';	# issue 49
              my $cs = cur_sub();
              $SpecialVarsUsed{'@ARGV'}{$cs} = 1;                       # SNOOPYJC
              #$ValType[$tno]="X";
        }else{
           #if( $tno>=2 && $ValClass[$tno-2] =~ /[sd'"q]/  && $ValClass[$tno-1] eq '>'  ){
              #$ValPy[$tno]='len('.$arg1.')'; # scalar context
              #$ValType[$tno]="X";
              #}else{
           $ValPy[$tno]=$arg1;
              #}
           $ValPy[$tno]=~tr/:/./s;
           $ValPy[$tno]=~tr/'/./s;
           if( substr($ValPy[$tno],0,1) eq '.' ){
              $ValPy[$tno]="$MAIN_MODULE.$ValPy[$tno]";
              #$ValType[$tno]="X";
           }
           $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '@', '');     # issue 92
           $ValPy[$tno] = escape_keywords($ValPy[$tno]);		# issue 41
        }
        $cut=length($arg1)+1;
        #$ValPerl[$tno]=substr($source,$cut);
        #$ValClass[$tno]='a'; #array
     }else{
        $cut=1;
     }
}

sub decode_hash                 # issue 47
{
    my $source = shift;

     if( substr($source,1)=~/^(\:?\:?\'?[_a-zA-Z]\w*((?:(?:\:\:)|\')[_a-zA-Z]\w*)*)/ ){
        $cut=length($1)+1;
        #$ValClass[$tno]='h'; #hash
        #$ValPerl[$tno]=$1;
        $ValPy[$tno]=$1;
        $ValPy[$tno]=~tr/:/./s;
        $ValPy[$tno]=~tr/'/./s;
        if( substr($ValPy[$tno],0,1) eq '.' ){
            #$ValCom[$tno]='X';
           $ValPy[$tno]="$MAIN_MODULE.$ValPy[$tno]";
        }
        if($ValPy[$tno] eq 'ENV') {                # issue 103
           $ValType[$tno]="X";
           $ValPy[$tno]='os.environ';
           my $cs = cur_sub();
           $SpecialVarsUsed{'%ENV'}{$cs} = 1;                       # SNOOPYJC
        } else {
           $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '%', '');     # issue 92
           $ValPy[$tno] = escape_keywords($ValPy[$tno]);
        }
     }else{
       $cut=1;
     }
}

sub decode_bare         # issue 108
{
     my $w = shift;

     $ValPy[$tno]=$w;
     $cut = length($w);
     $ValPy[$tno]=~tr/:/./s;
     $ValPy[$tno]=~tr/'/./s;
     if( exists($keyword_tr{$w}) ){
        $ValPy[$tno]=$keyword_tr{$w};
     }
     if( exists($CONSTANT_MAP{$w}) ) {      # SNOOPYJC
         $ValPy[$tno] = $CONSTANT_MAP{$w};  # SNOOPYJC
     }                                      # SNOOPYJC
}

sub interpolate_string_hex_escapes
# For strings that contain perl hex escapes (\x{HHH...}), change them to python hex escapes (of 3 varieties)
# Also handles \c escapes and \o escapes
{
    my $str = shift;

    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\c(.)/sprintf "\\x{%x}", (ord(uc $1) ^ 64)/eg;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\o\{\s*([0-7]+)\s*\}/sprintf "\\x{%x}", oct($1)/eg;

    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\s*([A-Fa-f0-9])\s*\}/\\x0$1/g;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\s*([A-Fa-f0-9]{2})\s*\}/\\x$1/g;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{([A-Fa-f0-9]{3})\}/\\u0$1/g;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{([A-Fa-f0-9]{4})\}/\\u$1/g;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{([A-Fa-f0-9]{5})\}/\\U000$1/g;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{([A-Fa-f0-9]{6})\}/\\U00$1/g;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{([A-Fa-f0-9]{7})\}/\\U0$1/g;
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{([A-Fa-f0-9]{8})\}/\\U$1/g;

    return $str;
}

sub escape_non_printables               # SNOOPYJC: Escape non-printable chars
{
    my $string = shift;
    my $escape_all = shift;             # if 1, then escape them all

    my %backslash_map = (10=>'\n', 13=>'\r', 9=>'\t', 12=>'\f', 7=>'\a', 11=>'\v');     # We don't map \b because it means something different in regex's
    if($string =~ /[^[:print:]]/) {                      
       my $new = '';
       for(my $i = 0; $i < length($string); $i++) {
           my $ch = substr($string, $i, 1);
           if($ch !~ /[[:print:]]/ && ($escape_all || ($ch ne "\n" && $ch ne "\t"))) {    # enable newlines and tabs in multi-line strings to come thru but no other non-printable chars
               my $ord = ord $ch;
               if(exists $backslash_map{$ord}) {
                   $new .= $backslash_map{$ord};
               } else {
                   $new .= "\\x{" . sprintf('%x', ord $ch) . '}';
               }
           } else {
               $new .= $ch;
           }
       }
       $string = interpolate_string_hex_escapes($new);
   }
   return $string;
}


#
# Aug 20, 2020 -- we wilol use the hack -- if there are quotes in the string we will anclose it introple quotes.
#
sub escape_quotes
{
my $string=$_[0];
my $result;

   if(index($string,"\n") >= 0) {	# issue 39 - need to escape newlines
      if(substr($string,-1,1) eq '"') {    # SNOOPYJC: oops - we have to fix this!
          return qq(""").escape_triple_doublequotes(substr($string,0,length($string)-1)).qq(\"""");
      }
      return qq(""").escape_triple_doublequotes($string).qq(""") 
   }
   return qq(').$string.qq(') if(index($string,"'")==-1 ); # no need to escape any quotes.
   return q(").$string.qq(") if( index($string,'"')==-1 ); # no need to scape any quotes.
#
# We need to escape quotes at the end
#
   if(substr($string,-1,1) eq '"' && !is_escaped($string, length($string)-1)) {  # SNOOPYJC: quote at end - we have to fix this!
       #return q(""").substr($string,0,length($string)-1).q(\"""");
       return q(''').escape_triple_singlequotes($string).q(''');
   }
   return qq(""").escape_triple_doublequotes($string).qq(""");
}

# ref https://docs.python.org/3/reference/lexical_analysis.html?highlight=escape#string-and-bytes-literals
$allowed_escapes = "\n\\'\"abfnrtv01234567xNuU";
# ref https://docs.python.org/3/library/re.html
$allowed_escapes_in_regex = q/.^$*+?{}[]|()\\'"&ABdDsSwWZgabfnrtv0123456789xNuU/;

sub remove_perl_escapes         # issue bootstrap
# Remove any escape sequences allowed by perl but not allowed by python, e.g. \[ \{ \$ \@ etc
# otherwise the '\' gets sent thru to the output.
{
    my $string = shift;
    my $in_regex = shift;

    return $string if($string !~ /\\/);	# quickly scan for an escape char

    my $result = '';
    my $allowed = ($in_regex ? $allowed_escapes_in_regex : $allowed_escapes);

    for(my $i =0; $i < length($string); $i++) {
        my $ch = substr($string,$i,1);
        if($ch eq "\\") {
            my $ch2 = substr($string,$i+1,1);
            if(index($allowed, $ch2) >= 0) {
                $result .= $ch . $ch2;
            } else {
                $result .= $ch2;
            }
            $i++;
            next;
        }
        $result .= $ch;
    }
    return $result;
}

sub escape_triple_singlequotes          # SNOOPYJC
# We are making a '''...''' string, make sure we escape any ''' in it (rare but possible)!
{
    my $string = shift;

    $string =~ s/'''/''\\'/g;
    return $string;
}

sub escape_triple_doublequotes          # SNOOPYJC
# We are making a """...""" string, make sure we escape any """ in it (rare but possible)!
{
    my $string = shift;

    $string =~ s/"""/""\\"/g;
    return $string;
}

sub put_regex_in_quotes
{
my $string=$_[0];
my $delim=$_[1];        # issue 111
my $original_regex=$_[2]; # issue 111
my $s_rhs = (scalar(@_) > 3 ? $_[3] : 0);       # issue bootstrap: Is this on the RHS of a s/// ?
   if($::debug > 4 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
       say STDERR "put_regex_in_quotes($string, $delim, $original_regex)";
   }
   if($delim ne "'") {  # issue 111
       $string =~ s/\$\&/\\g<0>/g;	# issue 11
       $string =~ s/\$([1-9])/\\g<$1>/g; # issue 11, SNOOPYJC: Not for $0 !!!
       # SNOOPYJC if( $string =~/\$\w+/ ){
       # issue 111 if( $string =~/^\$\w+/ ){    # SNOOPYJC: We have to interpolate all $vars inside!! e.g. /DC_$year$month/ gen rf"..."
       # issue 111 return substr($string,1); # this case of /$regex/ we return the variable.
       # issue 111 }
       $string = perl_regex_to_python($string) unless($s_rhs);          # issue 111, issue bootstrap
       $ValPy[$tno] = $string;                           # issue 111
       interpolate_strings($string, $original_regex, 0, 0, 1);          # issue 111
       $ValPy[$tno] = escape_re_sub($ValPy[$tno],$delim) if($s_rhs);   # issue bootstrap
       return 'r'.$ValPy[$tno];                                         # issue 111
   }
   # SNOOPYJC return 'r'.escape_quotes($string);
   return 'r'.escape_quotes(escape_re_sub($string,$delim)) if($s_rhs);   # issue bootstrap
   return 'r'.escape_quotes(perl_regex_to_python($string));   # SNOOPYJC
}

sub perl_regex_to_python
# Convert a perl regex to a python regex
{
    #$DB::single = 1;
    my $regex = shift;

    $regex =~ s'\\Z'$'g;
    $regex =~ s'\\z'\\Z'g;
    $regex =~ s/\(\?<(\w)/(?P<$1/g;           # Named capture group
    $regex =~ s/\\[gk]\{([A-Za-z_]\w*)\}/(?P=$1)/g;           # Backreference to a named capture group
    $regex =~ s/\\k<([A-Za-z_]\w*)>/(?P=$1)/g;           # Backreference to a named capture group
    $regex =~ s/\\k'([A-Za-z_]\w*)'/(?P=$1)/g;           # Backreference to a named capture group
    # issue bootstrap: Add the POSIX brackets:
    $regex =~ s/\[:alnum:\]/a-zA-Z0-9/g;
    $regex =~ s/\[:alpha:\]/a-zA-Z/g;
    $regex =~ s'\[:ascii:\]'\x00-\x7f'g;
    $regex =~ s'\[:blank:\]' \t'g;
    $regex =~ s'\[:cntrl:\]'\x00-\x1f\x7f'g;
    $regex =~ s/\[:digit:\]/0-9/g;
    $regex =~ s'\[:graph:\]'\x21-\x7e'g;
    $regex =~ s/\[:lower:\]/a-z/g;
    $regex =~ s'\[:print:\]'\x20-\x7e'g;
    $regex =~ s'\[:punct:\]'!"\#%&\'()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$'g;
    $regex =~ s'\[:space:\]' \t\r\n\x0b\f'g;
    $regex =~ s/\[:upper:\]/A-Z/g;
    $regex =~ s/\[:word:\]/A-Za-z0-9_/g;
    $regex =~ s/\[:xdigit:\]/A-Fa-f0-9/g;
    
    # issue bootstrap - escape '{' and '}' unless a legit repeat specifier
    $regex =~ s/^\{/\\{/;
    $regex =~ s/\|\{/|\\{/g;
    $regex =~ s/\(\{/(\\{/g;
    $regex =~ s/\(\?:\{/(?:\\{/g;

    if($Pythonizer::PassNo==&Pythonizer::PASS_2) {
        if($regex =~ /(?:(?<=[\\][\\])|(?<![\\]))\\G/) {
            logme('S', "Sorry, the \\G regex assertion (match at pos) is not supported");
        } elsif($regex =~ /\(\?R\)/ || $regex =~ /\(\?[+-]\d+\)/) {
            logme('S', "Sorry, regex recursion '$&' is not supported");
        } elsif($regex =~ /\(\?&\w+\)/) {
            logme('S', "Sorry, regex subroutines '$&' are not supported");
        }
    }

    return $regex;
}

sub escape_backslash
# All special symbols different from the delimiter and \ should be escaped when translating Perl single quoted literal to Python
# For example \n \t \r  are not treated as special symbols in single quotes in Perl (which is probably a mistake)
#
# Perl: A backslash represents a backslash unless followed by the delimiter or another backslash, in which case the delimiter or backslash is interpolated.
#
# Python: all unrecognized escape sequences are left in the string unchanged, i.e., the backslash is left in the result.
# Recognized in Python:
# \newline Backslash and newline ignored
# \\ Backslash (\)
# \' Single quote (')
# \" Double quote (")
# \a ASCII Bell (BEL)
# \b ASCII Backspace (BS)
# \f ASCII Formfeed (FF)
# \n ASCII Linefeed (LF)
# \r ASCII Carriage Return (CR)
# \t ASCII Horizontal Tab (TAB)
# \v ASCII Vertical Tab (VT)
# \ooo Character with octal value ooo
# \xhh Character with hex value hh
# \N{name} Character named name in the Unicode database
# \uxxxx Character with 16-bit hex value xxxx
# \Uxxxxxxxx Character with 32-bit hex value xxxxxxxx 
{
    # SNOOPYJC: Rewrote this to generate the proper output in all cases
    my $string=$_[0];
    my $opening_delim=$_[1];

    my $closing_delim = $opening_delim;
    if(index('{[(<',$closing_delim)>-1){
        $closing_delim=~tr/{[(</}])>/;
    }
    my $result = '';
    for(my $i=0; $i < length($string); $i++) {
       my $ch = substr($string,$i,1);
       if($ch eq '\\') {
           my $ch2 = substr($string,$i+1,1);
           if($ch2 eq '') {
               $result .= $ch;
           } elsif($ch2 eq "'" && $opening_delim eq "'") {
               $result .= $ch;          # we are putting the final string in '...', so we need to escape this
           } elsif($ch2 eq $opening_delim || $ch2 eq $closing_delim) {
               ;        # eat the escape
           } elsif($ch2 eq '\\') {
               $result .= $ch;
           } elsif(index("nrtfbvae01234567xNuU\n\"'", $ch2) >= 0) {
               $result .= $ch . $ch;
           } else {
               $result .= $ch;
           }
           $result .= $ch2;
           $i++;
       } elsif($ch eq "'" && $opening_delim eq "'") {
           $result .= '\\' . $ch;       # we are putting the final string in '...', so we need to escape this
       } else {
           $result .= $ch;
       }
    }
#my $backslash='\\';
#my $result=$string;
## issue 51 for( my $i=length($string)-1; $i>=0; $i--  ){
#   for( my $i=length($string)-2; $i>=0; $i--  ){                # issue 51
#      if( substr($string,$i,1) eq $backslash ){
#         my $ch2 = substr($string,$i+1,1);
#         if(index("nrtfbvae01234567xNuU\n",substr($string,$i+1,1))>-1 ){  # SNOOPYJC: Extend the list
#            substr($result,$i,0)='\\'; # this is a really crazy nuance
#         }
#      }
#   } # for
   return $result;
}

sub remove_oddities
# Remove some oddities from the generated code to make it easier to read/understand
{
    my $line = shift;

    # Change "not X is not None" to "X is None"
    # $line =~ s/\bnot ([\w.]+(?:\[[\w\']+\])*) is not None\b/$1 is None/g;
    $line =~ s/\bnot ([\w.]+(?:[\[(][\w.\']*[\])])*) is not None\b/$1 is None/g;

    #  if not (childPid is not None):
    $line =~ s/\bnot \(([\w.]+(?:\[[\w\']+\])*) is not None\)/$1 is None/g;

    #  assert not (nesting_last) is not None:
    $line =~ s/\bnot \(([\w.]+(?:\[[\w\']+\])*)\) is not None/$1 is None/g;

    # Change "if not ( not X):" to "if X:"
    $line =~ s/\bif not \( not ([\w.]+)\):$/if $1:/;

    # Change "if not (X):" to "if not X:"
    $line =~ s/\bif not \(([\w.]+)\):$/if not $1:/;

    # if not ((main.host) is not None): to "if main.host is None:"
    $line =~ s/\bif not \(\(([\w.]+)\) is not None\):$/if $1 is None:/;

    # Change "if not (f(...)):" to "if not f(...):"
    $line =~ s/\bif not \(([\w.]+\([^)]*\))\):$/if not $1:/;

    # Change "perllib.Array([])" to "perllib.Array()"
    $line =~ s/\bperllib\.Array\(\[\]\)/perllib.Array()/g;

    # Change "( not " to "(not "
    $line =~ s/\( not /(not /g;

    # Change "perllib.Hash({})" to "perllib.hash()"
    $line =~ s/\bperllib\.Hash\(\{\}\)/perllib.Hash()/g;


    # Change rf"{pattern}" to pattern (helps us out if pattern is a qr/regex/), also change f"{var}" to var
    # issue s8: must convert it to a str unless it's a pattern (in case it's like an int or something!)
    if(exists $SpecialVarsUsed{qr}) {
        $line =~ s/\(r?f"\{([\w.]+)\}"/($1 if isinstance($1, re.Pattern) else _str($1)/;
    } else {
        $line =~ s/\(r?f"\{([\w.]+)\}"/(_str($1)/;
    }

    # Change "[v1,v2,v3] = perllib.list_of_n(perllib.Array(), N)" -to-
    #        v1 = v2 = v3 = None
    if($line =~ /^\s*\[([\w.]+(?:,[\w.]+)*)\] = perllib\.list_of_n\(perllib.Array\(\), \d+\)/) {
	    $line = ($1 =~ s/,/ = /gr) . " = None";
    }
    
    # FIXME: Change "_list_of_n((7, 7, 7), 3" to "(7, 7, 7)"
    # if($line =~ /\b_list_of_n\(\(.*\), (\d+)\)/) {

    # Change ((...)) to (...) unless there are ',' inside the "..."
    my $pos = -1;
    while(($pos = index($line, '((', $pos+1)) > 0) {
        next if(in_string($line, $pos));
        my $end_pos = python_matching_paren($line, $pos, 0, ',');
        my $end_pos1 = python_matching_paren($line, $pos+1);    # Make sure this isn't like "((...)...)"
        if($end_pos1+1 == $end_pos && $end_pos > $pos) {
            substr($line,$end_pos,1) = '';
            substr($line,$pos,1) = '';
        }
    }

    return $line;
}

sub in_string 
# Is pos inside a string?
{
    my $str = shift;
    my $pos = shift;

    for(my $i = 0; $i <= $pos; $i++) {
        return 0 if $i == $pos;
        my $s=substr($str,$i,1);
        if($s eq "\\") {
            $i++;
        } elsif($s eq "'" || $s eq '"') {       # start of string
            my $quote = $s;
            while(++$i <= length($str)) {
                return 1 if $i == $pos;
                $s=substr($str,$i,1);
                if($s eq "\\") {
                    $i++;
                }
                last if($s eq $quote);
            }
        }
    }
    return 1;
}

sub python_matching_paren
# Find matching paren in python code, if found.
# Arg1 - the string to scan
# Arg2 - starting position for scan
# Arg3 - (optional) -- balance from whichto start (allows to skip opening paren)
# Arg4 - (optional) -- return -1 if this char is found (not escaped and not in string)
{
my $str=$_[0];
my $scan_start=$_[1];
my $balance=(scalar(@_)>2) ? $_[2] : 0; # case where opening bracket is missing for some reason or was skipped.
my $bad_char=(scalar(@_)>3) ? $_[3] : "\0";

   for( my $k=$scan_start; $k<length($str); $k++ ){
     my $s=substr($str,$k,1);
     if( $s eq '(' ){
        $balance++;
     }elsif( $s eq ')' ){
        $balance--;
        if( $balance==0  ){
           return $k;
        }
     }elsif($s eq "\\") {               # Skip escape chars
         $k++;
     }elsif($s eq $bad_char) {
         return -1;
     }elsif($s eq "'" || $s eq '"') {   # start of string, parse to end
        my $quote = $s;
        while(++$k < length($str)) {
            $s=substr($str,$k,1);
            if($s eq "\\") {    # Skip escape chars
                $k++;
            }
            last if($s eq $quote);
        }
     }

  } # for
  return -1;
} # python_matching_paren

#
# Typically used without arguments as it openates on PythonCode array
# NOTE: Can have one or more argument and in this case each of the members of the list  will be passed to output_line.
sub gen_statement
{
my $i;
my $line='';
   if (scalar(@_)==0 && scalar(@PythonCode)==0){
      Pythonizer::correct_nest(); # equalize CurNest and NextNest;
      return; # nothing to do
   }
   if( scalar(@_)>0  ){
      #direct print of the statement. Added Aug 10, 2020 --NNB
      for($i=0; $i<@_;$i++ ){
         Pythonizer::output_line($_[$i]);
      }
      $PREV_HAD_COLON = (substr($_[-1], -1, 1) eq ':') ? 1 : 0;      # SNOOPYJC
   }elsif( defined($::TrStatus) && $::TrStatus<0 && scalar(@ValPy)>0 ){
      $line=$ValPy[0];
      for( $i=1; $i<@ValPy; $i++ ){
         next unless(defined($ValPy[$i]));
         next if( $ValPy[$i] eq '' );
         $s=substr($ValPy[$i],0,1);
         if( $ValPy[$i-1]=~/\w$/ ){
            if( index(q('"/),$s)>-1 || $s=~/\w/ ){
                # print "something" if /abc/
                $line.=' '.$ValPy[$i];
            }else{
                $line.=$ValPy[$i];
            }
         }else{
            $line.=$ValPy[$i];
         }
      }
      ($line) && Pythonizer::output_line($line,' #FAILTRAN');
   }elsif( scalar(@PythonCode)>0 ){

      $line = format_chunks();                          # SNOOPYJC
      $line = remove_oddities($line);                   # SNOOPYJC
      $PREV_HAD_COLON = (substr($line, -1, 1) eq ':') ? 1 : 0;      # SNOOPYJC
      if( defined $ValCom[-1]  && length($ValCom[-1]) > 1  ){
         # single symbol ValCom will be used as additional determinator of the token in pass 0 -- Sept 18, 200 -- NNB
         #that means that you need a new line. bezroun Feb 3, 2020
         Pythonizer::output_line($line,$ValCom[-1] );
      }else{
        Pythonizer::output_line($line);
      }
      for ($i=1; $i<$#ValCom; $i++ ){
          if( defined($ValCom[$i]) && length($ValCom[$i])>1  ){
             # NOTE: This is done because comment can be in a wrong position due to Python during generation and the correct placement  is problemtic
             Pythonizer::output_line('',$ValCom[$i] );
          }  # if defined
      }
   }elsif( $line ){
       Pythonizer::output_line('','#NOTRANS: '.$line);
   }
   if( $::debug>=4 ){
      out("\nTokens: $TokenStr ValPy: ".join(' '.@PythonCode));
   }
#
# Prepare for the next line generation
#
   Pythonizer::correct_nest(); # equalize CurNest and NextNest;
   @PythonCode=(); # initialize for the new line
   return;
}

sub format_chunks                                       # SNOOPYJC
# Format the generated code chunks into a line
{
      my $line=$PythonCode[0];
      if(defined $line && exists $PYTHON_KEYWORD_SET{$line}) {          # SNOOPYJC
          $line .= ' ';                                                 # SNOOPYJC: space after every keyword
      }                                                                 # SNOOPYJC
      for( my $i=1; $i<@PythonCode; $i++  ){
         next unless(defined($PythonCode[$i]));
         next if( $PythonCode[$i] eq '' );
         $s=substr($PythonCode[$i],0,1); # the first symbol
         if(exists $PYTHON_KEYWORD_SET{$PythonCode[$i]}) {         # SNOOPYJC: surround keywords with space
            if( defined($line) && substr($line,-1,1) ne ' ') {
                $line .= ' ';
            }
            $line .= $PythonCode[$i] . ' ';
        } elsif( defined($line) && substr($line,-1,1)=~/[\w'"]/ &&  $s =~/[\w'"]/ ){
            # space between identifiers and before quotes
            $line.=' '.$PythonCode[$i];
        #} elsif( exists $SpaceBefore{substr($PythonCode[$i],0,2)} && defined($line) && substr($line,-1,1) ne ' ' ) {        # SNOOPYJC
           #$line.=' '.$PythonCode[$i];                         # SNOOPYJC e.g. ...)or => ...) or
         } elsif( exists $SpaceBoth{$PythonCode[$i]} && defined($line) && substr($line,-1,1) ne ' ' ) {        # SNOOPYJC
            $line.=' '.$PythonCode[$i].' ';                     # SNOOPYJC e.g. a=b => a = b
         } elsif($PythonCode[$i] eq ',') {              # SNOOPYJC  Space after ','
             $line.=$PythonCode[$i].' ';
         }else{
            #no space befor delimiter
            $line.=$PythonCode[$i];
         }
      } # for
      return $line;
}

#
# Add generated chunk or multile chaunks of Python code checking for overflow
#
sub gen_chunk
{
my ($i,$k);
#
# Put generated chunk into array.
#
   for($i=0; $i<@_;$i++ ){
      if( scalar(@PythonCode) >$MAX_CHUNKS  ){
         $chunk=$PythonCode[$i];
         $k=$i;
         --$k while($PythonCode[$k] eq $chunk);
         logme('T',"The number of generated chunk exceeed $MAX_CHUNKS");
         logme('T',"First generated chunk is $PythonCode[0] . The last generated chunk before infinite loop is $PythonCode[$k]");
         abend("You might need to exclude or simplify the line. Please refer to the user guide as for how to troubleshoot this situation");
      }
      if($::import_perllib && exists $::Pyf{$_[$i]} && $::Pyf{$_[$i]} == 1 &&
         substr($_[$i],0,length($PERLLIB)+1) ne "$PERLLIB.") {      # SNOOPYJC: Handle perllib option
          my $chu = $_[$i];
          if(substr($chu,0,1) eq '_') {
              $chu = escape_keywords(substr($chu,1));       # SNOOPYJC: remove the initial '_' but change keywords like import to import_
          }
          push(@PythonCode, "$PERLLIB.$chu");
      } else {
          push(@PythonCode,$_[$i]);
      }
   } #for
   ($::debug>4) && say 'Generated partial line ',join('',@PythonCode);
}

sub save_code           # issue 74: save the generated python code so we can insert some new code before it
{
    say STDERR "save_code(@PythonCode)" if($::debug >= 3);
    @SavePythonCode = @PythonCode;      # copy the code
    @PythonCode = ();
}
sub restore_code        # issue 74
{
    @PythonCode = @SavePythonCode;
    say STDERR "restore_code() = @PythonCode" if($::debug >= 3);
}

sub append
{
   $TokenStr.=$_[0];
   $ValClass[scalar(@ValClass)]=$_[0];
   $ValPerl[scalar(@ValPerl)]=$_[1];
   $ValPy[scalar(@ValPy)]=$_[2];
   $ValType[scalar(@ValPy)]=( scalar(@_)>3 ) ? $_[3]:'';
}
sub replace
# replace before pos. Replace(0,'(','(','(') inserts the token at the bgiing like shift
{
my $pos=shift; # if pos is negative, count from the end of the string
   if ($pos<0){
      $pos=scalar(@ValClass)-$pos;      # SNOOPYJC
   }
   if(  $pos>$#ValClass ){
      abend('Replace position $pos is outside upper bound');
   }
   substr($TokenStr,$pos,1)=$ValClass[$pos]=$_[0];
   $ValPerl[$pos]=$_[1];
   $ValPy[$pos]=$_[2];
   $ValType[$pos]='';
}
sub insert
#inserts before the position $pos
#issue 74: If the $pos is at the end, it does an append
{
my $pos=shift;
   if($pos == scalar @ValClass) {               # issue 74
       append($_[0], $_[1], $_[2]);             # issue 74
       return;                                  # issue 74
   }                                            # issue 74
   if(  $pos>$#ValClass ){
      abend('Insert position $pos is outside upper bound');
   }
   substr($TokenStr,$pos,0)=$_[0];
   splice(@ValClass,$pos,0,$_[0]);
   splice(@ValPerl,$pos,0,$_[1]);
   splice(@ValPy,$pos,0,$_[2]);
   if($pos <= $#ValType) {		# issue 37 - sometimes it's not set
       # Troubleshooting the perl segv caused here
       #print STDERR "insert $pos into ValType. Before: ";
       #for(my $i=0; $i <= $#ValType; $i++) {
       #print STDERR "ValType[$i]=$ValType[$i] " if(defined $ValType[$i]);
       #}
       #print STDERR "\n";
   	splice(@ValType,$pos,0,'');
        #print STDERR "After: ";
        #for(my $i=0; $i <= $#ValType; $i++) {
        #print STDERR "ValType[$i]=$ValType[$i] " if(defined $ValType[$i]);
        #}
        #print STDERR "\n";
   } else {
       #SNOOPYJC: This causes a perl SEGV Fault while bootstrapping and is not needed!!  $ValType[$pos] = '';
   }
}
sub destroy
# accespt two parameters
# start of deletion
# number of tokens; if omiited to the end of the tokenstring.
{
($from,$howmany)=@_;
   # defaults and special cases
   if( $from == -1 ){
      $from=$#ValClass;
      $howmany=1;
   }elsif( scalar(@_)==1 ){
      $howmany=scalar(@ValClass)-$from; # is no length then up to the nd of arrays.
   }
    # sanity checks
   if ($from>$#ValClass) {
       cluck("Attempt to destroy element  $from in set containing $#ValClass elements. Request ignored");
       logme('E',"Attempt to destroy element  $from in set containing $#ValClass elements. Request ignored");
       return;
   }elsif($from+$howmany>scalar(@ValClass)){
      cluck("Attempt to destroy  $howmany from position $from exceeds the index of the last element $#ValClass. Request ignored");
      logme('E',"Attempt to delete  $howmany from position $from exceeds the index of the last element $#ValClass. Request ignored");
      return;
   }
    substr($TokenStr,$from,$howmany)='';
    splice(@ValClass,$from,$howmany);
    splice(@ValPerl,$from,$howmany);
    splice(@ValPy,$from,$howmany);
    if(scalar(@ValType) >= $from+$howmany) {	# issue 37
    	splice(@ValType,$from,$howmany);	# issue 37
    }
}
sub autoincrement_fix
#
# absence of autoincrament and autodecrament operators is a problem... May be even a wart.
#
{
my $wart_pos;
   return if(1);                # SNOOPYJC: we fixed this issue elsewhere
    #postincement
   if( length($TokenStr)>6 &&  substr($TokenStr,0,6) eq 's(s^)='){
      logme('E','Increment of array index found on the left side of assignement and replaced by append function. This guess might be wrong');
      destroy(2,4);
      replace( 0,'f','f',$ValPy[0].'.append' );
      replace(1,'(','(','(');
      append(')',')',')');
   }elsif(  ($wart_pos=index($TokenStr,'s^)')) >-1  && $ValPerl[$wart_pos+2] eq ']' ){
       logme('E',"Posfix operation $ValPerl[$wart_pos+1] might be translated incorrectly. Please verify and/or translate manually ");
       $ValPy[$wart_pos]='('.$ValPy[$wart_pos].':='.$ValPy[$wart_pos].'+1)';
       $ValPy[$wart_pos+1]='';
       #$ValClass[$wart_pos]='f';
   }elsif(  ($wart_pos=index($TokenStr, '(^s')) >-1 && $ValPerl[$wart_pos] eq '[' ){
       $ValPy[$wart_pos+2]='('.$ValPy[$wart_pos+2].':='.$ValPy[$wart_pos+2].'+1)';
       $ValPy[$wart_pos+1]='';
   }
} # preprocessing

sub matching_paren
# Find matching paren, if found.
# Arg1 - the string to scan
# Arg2 - starting position for scan
# Arg3 - (optional) -- balance from whichto start (allows to skip opening paren)
{
my $str=$_[0];
my $scan_start=$_[1];
my $balance=(scalar(@_)>2) ? $_[2] : 0; # case where opening bracket is missing for some reason or was skipped.
   for( my $k=$scan_start; $k<length($str); $k++ ){
     my $s=substr($str,$k,1);
     if( $s eq '(' ){
        $balance++;
     }elsif( $s eq ')' ){
        $balance--;
        if( $balance==0  ){
           return $k;
        }
     }
  } # for
  return -1;
} # matching_paren

sub matching_curly_br			# issue 43
# Find matching curly bracket, aka closing curly bracket, if found.
# Arg1 - the string to scan
# Arg2 - starting position for scan
# Arg3 - (optional) -- balance from whichto start (allows to skip opening brace)
{
my $str=$_[0];
my $scan_start=$_[1];
my $balance=(scalar(@_)>2) ? $_[2] : 0; # case where opening bracket is missing for some reason or was skipped.
   for( my $k=$scan_start; $k<length($str); $k++ ){
     my $s=substr($str,$k,1);
     if( $s eq '{' ){
        $balance++;
     }elsif( $s eq '}' ){
        $balance--;
        if( $balance==0  ){
           return $k;
        }
     }
  } # for
  return -1;
} # matching_curly_br

sub matching_square_br			# issue 43
# Find matching square bracket, aka closing square bracket, if found.
# Arg1 - the string to scan
# Arg2 - starting position for scan
# Arg3 - (optional) -- balance from whichto start (allows to skip opening brace)
{
my $str=$_[0];
my $scan_start=$_[1];
my $balance=(scalar(@_)>2) ? $_[2] : 0; # case where opening bracket is missing for some reason or was skipped.
   for( my $k=$scan_start; $k<length($str); $k++ ){
     my $s=substr($str,$k,1);
     if( $s eq '[' ){
        $balance++;
     }elsif( $s eq ']' ){
        $balance--;
        if( $balance==0  ){
           return $k;
        }
     }
  } # for
  return -1;
} # matching_square_br

sub escape_keywords		# issue 41
# Accepts a name and escapes any python keywords in it by appending underscores.  The name can
# be a period separated list of names.  Returns the escaped name.
# Note: We also escape the names of the built-in functions like len, etc
{
	my $name = $_[0];
        my $is_package_name = (scalar(@_) >= 2) ? 1 : 0;

	my @ids = split /[.]/, $name;
	my @result = ();
	for(my $i=0; $i<scalar(@ids); $i++) {
           $id = $ids[$i];
	   if(exists $PYTHON_RESERVED_SET{$id} || ($id eq $DEFAULT_PACKAGE && ($i != 0 || $id eq $name) && !$is_package_name && !$::implicit_global_my)) {
	       $id = $id.'_';
	   } elsif(substr($id,0,1) =~ /\d/) {   # issue ddts
               $id = '_'.$id;
           }
           push @result, $id;
	}
	return join('.', @result);
}

#sub name_map                    # issue 92
## Accepts a name, the sigil, and trailing char and produces the python name for it.  Modifies names only if need be.
## The name can also be a period separated list of names, in which case it only potentially modifies
## the last one.
#{
#    my $name = shift;
#    my $sigil = shift;          # @, %, $, & or '' for FH
#    my $trailer = shift;
#
#    my @ids = split/[.]/, $name;
#    my $id = $ids[-1];
#    $sigil = actual_sigil($sigil, $trailer);
#    if(exists $NameMap{$id} && exists $NameMap{$id}{$sigil}) {
#        $ids[-1] = $NameMap{$id}{$sigil};
#    }
#    return join('.', @ids);
#}

sub add_package_to_mapped_name          # issue import vars
# For supporting import (use statement) of variable names, add the package name to their remap so
# we generate that in the code that references them.
{
    my $perl_name = shift;
    my $package_name = shift;
    my $py_name = (scalar @_) ? shift : undef;

    my $sigil = substr($perl_name, 0, 1);
    my $name = substr($perl_name, 1);

    if(exists $NameMap{$name} && exists $NameMap{$name}{$sigil}) {
        $py_name = $NameMap{$name}{$sigil} unless defined $py_name;
    } elsif(!defined $py_name) {
        $py_name = escape_keywords($name);
    }
    $NameMap{$name}{$sigil} = escape_keywords($package_name, 1) . '.' . $py_name;
}

sub mapped_name                         # issue 92
# Returns our name mapping for conflicting names, e.g. name_v, name_a, name_h
{
    my $name = shift;
    my $sigil = shift;                  # @, %, $, & or '' for FH
    my $trailer = shift;                # [ or { or ''

    $sigil = actual_sigil($sigil, $trailer);
    if(substr($name,-1,1) eq '_') {             # if we have like 'in_' which used to be 'in', then get us 'in'
        my $without_escape = substr($name,0,length($name)-1);
        my $esc = escape_keywords($without_escape);
        $name = $without_escape if($esc eq $name);
    }
    return array_var_name($name) if($sigil eq '@');
    return hash_var_name($name) if($sigil eq '%');
    return scalar_var_name($name) if($sigil eq '$');
    return $name;
}

sub actual_sigil                        # issue 92
{
    my $sigil = shift;
    my $trailer = shift;

    return '@' if($trailer eq '[');
    return '%' if($trailer eq '{');
    return $sigil;
}

sub remap_conflicting_names                  # issue 92
# Call this when you see a new name - it looks at what names are already used and sees if this
# name must be remapped.  If so, it returns the new name.
{
    my $name = shift;                           # The ValPy
    my $sigil = shift;                          # @, %, $, & or '' for FH
    my $trailer = shift;                        # [ or { or ''
    my $force = scalar(@_) >= 1 ? $_[0] : 0;    # if present, force the remap operation

    return $name if($Pythonizer::PassNo==&Pythonizer::PASS_0);
    return $name if(!$name);
    return $name if(substr($name,-1,1) eq ')');         # e.g. "globals()"
    return $name if($name =~ /\.__dict__$/);            # package version of globals()
    return $name if(substr($name,0,3) eq 'os.');
    return $name if(substr($name,0,4) eq 'sys.');
    return $name if(substr($name,0,5) eq 'math.');
    return $name if(substr($name,0,8) eq 'perllib.');   # issue names
    return $name if($name eq '.');
    my @ids = split/[.]/, $name;
    my $id = $ids[-1];
    my $s = $sigil;
    $sigil = actual_sigil($sigil, $trailer);
    # If the name is already mapped, then skip it:
    my $i;
    return $name if($id =~ /_[avh]$/ && exists $NameMap{($i=substr($id,0,length($id)-2))} && $NameMap{$i}{$sigil} eq $id);

    # If a package name is present and it's not a package defined in this file, then attempt to find
    # the Python file containing that package, see how the names are mapped in there, and mirror that to the
    # variable reference here.
    my $mid = mapped_name($id, $sigil, $trailer);       # e.g. name_a, name_h, name_v if we need to remap it
    if(scalar(@ids) > 1) {              # we have a package
        if(exists $NameMap{$name} && exists $NameMap{$name}{$sigil}) {  # we have a mapping for the full name already
            my $mapping = $NameMap{$name}{$sigil};
            say STDERR "remap_conflicting_names($name,$s,$trailer) = $mapping (p0)" if($::debug >= 5);
            return $mapping;
        }
        # issue names: Just assume any name with a package is mapped
        $ids[-1] = $mid;
        my $mapping = join('.', @ids);
        $NameMap{$name}{$sigil} = $mapping;
        say STDERR "remap_conflicting_names($name,$s,$trailer) = $mapping (p1)" if($::debug >= 5);
        return $mapping;
=pod
        if($Pythonizer::PassNo==&Pythonizer::PASS_2) {
            my @pkg = @ids;
            $#pkg--;                # Lose the varname
            my $package_name = join('.', @pkg);
            my $perl_package_name = $package_name =~ s/[.]/::/gr;
            if(!exists $Pythonizer::Packages{$package_name} && !exists $PREDEFINED_PACKAGES{$perl_package_name}) {
                my $name_map = get_mapped_names_for_package($package_name);
                if(scalar(%$name_map)) {
                    %NameMap = (%NameMap, %{$name_map});    # Merge them
                    if(exists $NameMap{$name} && exists $NameMap{$name}{$sigil}) {  # check again now that we mapped the package
                        my $mapping = $NameMap{$name}{$sigil};
                        say STDERR "remap_conflicting_names($name,$s,$trailer) = $mapping (p0)" if($::debug >= 5);
                        return $mapping;
                    }
                # } elsif($fullpy) {
                # issue names: this causes a problem by remapping a name that's not actually remapped e.g. main.remap_requests in our bootstrap
                # issue names } else {
                # issue names say STDERR "remap_conflicting_names($name,$s,$trailer), fname=$Pythonizer::fname, fullpy=$fullpy" if($::debug);
                    #my $lockfile = &::_lock_file($fullpy);
                    
                    #my $lockfile = &::_lock_file($Pythonizer::fname);
                    #open(LOCKFILE, '>>', $lockfile);
                    #print LOCKFILE "$sigil$package_name.$id=>$mid\n";
                    #say STDERR "remap_conflicting_names($name,$s,$trailer): Writing '$sigil$package_name.$id=>$mid' to $lockfile" if($::debug);
                    #close(LOCKFILE);
                    # issue names $NameMap{$name}{$sigil} = escape_keywords($package_name, 1) . '.' . $mid;
                    # issue names my $mapping = $NameMap{$name}{$sigil};
                    # issue names say STDERR "remap_conflicting_names($name,$s,$trailer) = $mapping (p1)" if($::debug >= 5);
                    # issue names return $mapping;
                }
            }
        }
=cut
    }
    if(exists $NameMap{$id} && exists $NameMap{$id}{$sigil} && $NameMap{$id}{$sigil} ne $id) {
        $ids[-1] = $NameMap{$id}{$sigil};
        if(scalar(@ids) > 1 && index($ids[-1],'.') >= 0) {
            # We have a name we imported that we have referenced with the fully qualified name, 
            # remove the extra package name
            my $p_dot = rindex($ids[-1], '.');
            $ids[-1] = substr($ids[-1], $p_dot+1);
        }
        say STDERR "remap_conflicting_names($name,$s,$trailer) = " . join('.', @ids) . ' (1)' if($::debug >= 5);
        return (join('.', @ids));
    }
    if($sigil ne '' && $sigil ne '&') {
        if($::remap_all || $force || exists $::remap_requests{$sigil.$id} || exists $::remap_requests{$id} || exists $::remap_requests{'*'.$id}) {
            $ids[-1] = $mid;
            say STDERR "remap_conflicting_names($name,$s,$trailer): Remapping new $sigil$id to $mid due to -R option" if($::debug >= 3);
        } else {
            for $sig (('', '&', '@', '%', '$')) {
                next if($sig eq $sigil);
                last if(!exists $NameMap{$id});
                next if(!exists $NameMap{$id}{$sig});
                if($NameMap{$id}{$sig} eq $id) {    # If somebody's using the plain ID then we have to map ours
                    $ids[-1] = $mid;
                    say STDERR "remap_conflicting_names($name,$s,$trailer): Remapping new $sigil$id to $mid due to $sig$id" if($::debug >= 3);
                    last;
                }
            }
        }
        $NameMap{$id}{$sigil} = $ids[-1];
        if(scalar(@ids) > 1 && index($ids[-1],'.') >= 0) {
            # We have a name we imported that we have referenced with the fully qualified name, 
            # remove the extra package name
            my $p_dot = rindex($ids[-1], '.');
            $ids[-1] = substr($ids[-1], $p_dot+1);
        }
        say STDERR "remap_conflicting_names($name,$s,$trailer) = " . join('.', @ids) . ' (2)' if($::debug >= 5);
        return (join('.', @ids));
    }
    # We have a sub or a FH at this point - map other names and leave him alone
    $NameMap{$id}{$sigil} = $id;
    for $sig (('@', '%', '$')) {
        if($sig ne $sigil) {
            last if(!exists $NameMap{$id});
            next if(!exists $NameMap{$id}{$sig});
            if($NameMap{$id}{$sig} eq $id) {
                my $mn = mapped_name($id, $sig, '');
                say STDERR "remap_conflicting_names($name,$s,$trailer): Remapping old $sig$id to $mn due to $sigil$id" if($::debug >= 3);
                $NameMap{$id}{$sig} = $mn;
                @packages = ('', @Pythonizer::Packages);
                for my $pkg (@packages) {
                    my $nam = $id;
                    $nam = $pkg . '.' . $id if($pkg ne '');
                    my $mnp = $mn;
                    $mnp = $pkg . '.' . $mn if($pkg ne '');
                    say STDERR "checking $nam" if($::debug >= 5);
                    if(exists $Pythonizer::VarSubMap{$nam}) {
                        $Pythonizer::VarSubMap{$mnp} = $Pythonizer::VarSubMap{$nam};
                        delete $Pythonizer::VarSubMap{$nam};
                    }
                    if(exists $Pythonizer::VarType{$nam}) {
                        $Pythonizer::VarType{$mnp} = $Pythonizer::VarType{$nam};
                        delete $Pythonizer::VarType{$nam};
                    }
                    for $sub (keys %Pythonizer::NeedsInitializing) {
                        my $subh = $Pythonizer::NeedsInitializing{$sub};
                        if(exists $subh->{$nam}) {
                            $subh->{$mnp} = $subh->{$nam};
                            delete $Pythonizer::NeedsInitializing{$sub}{$nam};
                        }
                    }
                    for $sub (keys %Pythonizer::initialized) {
                        my $subh = $Pythonizer::initialized{$sub};
                        if(exists $subh->{$nam}) {
                            $subh->{$mnp} = $subh->{$nam};
                            delete $Pythonizer::initialized{$sub}{$nam};
                        }
                    }
                }
            }
        }
    }
    say STDERR "remap_conflicting_names($name,$s,$trailer) = $name (3)" if($::debug >= 5);
    return $name;
}

sub parens_are_balanced         # issue 85 - return 1 if the parens are balanced in the token stream
{
    my $balance = 0;
    for(my $i = 0; $i <= $#ValClass; $i++) {
        $balance++ if($ValClass[$i] eq '(');
        $balance-- if($ValClass[$i] eq ')');
    }
    return ($balance == 0);
}

sub is_escaped                          # SNOOPYJC
# Is this character escaped?
{
    my $string = shift;
    my $pos = shift;

    return 0 if($pos == 0);                             # x
    return 0 if(substr($string,$pos-1,1) ne "\\");      # .x
    return 1 if($pos == 1);                             # \x
    return 1 if(substr($string,$pos-2,1) ne "\\");      # .\x
    return 0 if($pos == 2);                             # \\x
    return 1 if(substr($string,$pos-3,1) eq "\\");      # \\\x
    return 0;                                           # .\\x
}

sub init_perllib                        # SNOOPYJC
# If we're using "import perllib;" then change up some variable names to prefix them with "perllib."
{
    foreach my $key (keys %SPECIAL_VAR) {
        my $value = $SPECIAL_VAR{$key};
        if(exists $GLOBALS{$value}) {
            $SPECIAL_VAR{$key} = "$PERLLIB.$value";
        }
    }
    foreach my $key (keys %SPECIAL_VAR2) {
        my $value = $SPECIAL_VAR2{$key};
        if(exists $GLOBALS{$value}) {
            $SPECIAL_VAR2{$key} = "$PERLLIB.$value";
        }
    }
    #my @GLOBALS = keys %GLOBALS;
}

sub get_rest_of_variable_name   # issue ws after sigil
# We were looking for a variable name after a sigil and hit the end of line or white space instead
{
    my $source = shift;         # contains the sigil followed by optional whitespace and a possible comment
    my $in_string = shift;      # 1 if we are decoding inside a string

    while(1) {
        return $source if($source =~ /^%\s*\$/);        # Don't mess up mod (%) operator
        $source =~ s/(.)\s*(?!#)/$1/;		# Allow whitespace but not $ # (see end of test_ws_after_sigil.pl for example)
        last if($in_string);                    # That's all you get!
        $source =~ s/(.)\s*#.*$/$1/;
        last if length($source) > 1;
        # if we get here, we ran out of road - grab the next line and keep going!
        my @tmpBuffer = @BufferValClass;	# Must get a real line even if we're buffering stuff
        @BufferValClass = ();
        my $line = Pythonizer::getline();
        @BufferValClass = @tmpBuffer;
        if(!$line) {
            logme('S', "Unexpected end of file in '$source' variable name");
            return $source;
        }
        if(substr($source,0,1) eq '%' && substr($line,0,1) eq '$') {    # Don't mess up mod (%) operator
            $source .= ' ' . $line;
        } else {
            $source .= $line;
        }
    }
    say STDERR "get_rest_of_variable_name(".substr($source,0,1).", $in_string), lno=$., source='$source'" if($::debug >= 3);
    return $source;
}

my %ch_escapes = (t=>"\t", n=>"\n", r=>"\r", f=>"\f", b=>"\b", a=>"\a", e=>"\e");

sub unescape_string             # SNOOPYJC
# Given a string remove all escapes in it, except for \-
{
    my $arg = shift;
    my $result = '';

    for(my $i = 0; $i < length($arg); $i++) {
        my $ch = substr($arg,$i,1);
        if($ch eq "\\") {
            my $ch2 = substr($arg,$i+1,1);
            if(exists $ch_escapes{$ch2}) {
                $ch = $ch_escapes{$ch2};
                $i++;
            } elsif($ch2 eq 'x') {
                my $ch3 = substr($arg,$i+2,1);
                if($ch3 eq '{') {
                    my $end_br = matching_curly_br($arg, $i+2);
                    $ch = chr(hex(substr($arg,$i+3,$end_br-($i+3))));
                    $i = $end_br;
                } else {
                    if(substr($arg,$i+2) =~ /([0-9a-fA-F]+)/) {
                        $ch = chr(hex($1));
                        $i += length($1)+1;
                    } else {
                        $ch = chr(0);
                        $i++;
                    }
                }
            } elsif($ch2 eq 'c') {
                my $ch3 = substr($arg,$i+2,1);
                $ch = chr(ord(uc $ch3) ^ 64);
                $i+=2;
            } elsif($ch2 eq 'o' && substr($arg,$i+2,1) eq '{') {
                my $end_br = matching_curly_br($arg, $i+2);
                $ch = chr(oct(substr($arg,$i+3,$end_br-($i+3))));
                $i = $end_br;
            } elsif($ch2 eq 'N' && substr($arg,$i+2,1) eq '{') {
                my $end_br = matching_curly_br($arg, $i+2);
                my $charname = substr($arg,$i+3,$end_br-($i+3));
                if(substr($charname,0,2) eq 'U+') {
                    $charname = charnames::viacode($charname);
                    if(!defined $charname) {
                        logme('W', substr($arg,$i,$end_br+1-$i) . " is not a valid charname");
                        $charname="NULL";
                    }
                }
                $ch = charnames::string_vianame($charname);
                if(!defined $ch) {
                    logme('W', "$charname is not a valid charname");
                    $ch="\0";
                }
                $i = $end_br;
            } elsif(substr($arg,$i+1) =~ /([0-7]+)/) {
                $ch = chr(oct($1));
                $i += length($1);
            } elsif($ch2 eq '-') {
                $ch = "\\-";
                $i++;
            } else {
                $ch = $ch2;
                $i++;
            }

        } 
        $result .= $ch;
    }
    return $result;
}

sub expand_ranges                       # SNOOPYJC
# For tr, expand ranges like 0-9 into 0123456789
{
    my $arg = shift;
    my $delim = shift;

    my $result = '';

    if($delim eq "'") {
        for(my $i = 0; $i < length($arg); $i++) {
            my $ch = substr($arg,$i,1);
            if($ch eq "\\") {
                $result .= $ch;
            }
            $result .= $ch;
        }
        return $result;
    }

    $arg = unescape_string($arg);

    for(my $i = 0; $i < length($arg); $i++) {
        my $ch = substr($arg,$i,1);
        if($ch eq "\\") {
            #$result .= $ch;
            $result .= substr($arg,$i+1,1);
            $i++;
        } elsif($ch eq '-' && $i > 0 && $i < (length($arg)-1)) {
            if(substr($arg,$i-1,1) eq substr($arg,$i+1,1)) {    # a-a
                $i++;
                next;
            } 
            for(my $j = ord(substr($arg,$i-1,1))+1; $j < ord(substr($arg,$i+1,1)); $j++) {
                $result .= chr($j);
            }
        } else {
            $result .= $ch;
        }
    }
    return escape_non_printables($result, 1);
}

sub make_same_length                    # SNOOPYJC
# For tr, make the second operand the same length as the first, repeating chars or truncating if need be.
# Returns an updated arg2.
{
    my ($arg1, $arg2) = @_;

    return $arg2 if(length($arg2) == length($arg1));
    return $arg1 if(length($arg2) == 0);
    return substr($arg2, 0, length($arg1)) if(length($arg2) > length($arg1));
    $last_c = substr($arg2, -1, 1);
    while(length($arg2) < length($arg1)) {
        $arg2 .= $last_c;
    }
    return $arg2;
}

sub first_map_wins                      # SNOOPYJC
# For tr, if multiple chars are mapped, only the first one is obeyed, so delete the rest
# At this point, arg1 and arg2 are the same length - we keep them that way.
{
    my ($arg1, $arg2) = @_;
    my %hash = ();

    for(my $i=0; $i < length($arg1); $i++) {
        if(exists $hash{substr($arg1,$i,1)}) {
            substr($arg1,$i,1) = '';
            substr($arg2,$i,1) = '';
            $i--;
        } else {
            $hash{substr($arg1,$i,1)} = 1;
        }
    }
    return ($arg1, $arg2);
}

sub replace_usage                       # SNOOPYJC
# For the -u flag, replace "Usage: FILENAME.pl ..." with "Usage: FILENAME.py ..."
{
    my $py = shift;

    my $fname = basename($Pythonizer::fname);
    my $pyname = $fname =~ s/\.pl$/.py/r;

    $py =~ s/^(f?(?:'''|"""|'|")Usage:) $fname/$1 $pyname/;

    return $py;
}

sub escape_re_sub               # SNOOPYJC
# For the RHS of an re.sub(), escape any non-allowed escape sequence such as \xNN with an extra '\'
# issue bootstrap: Also remove anything the user escaped that doesn't need escaping, unless they use a ' delimiter
{
    my $str = shift;
    my $delim = shift;

    my $result = '';

    for(my $i = 0; $i < length($str); $i++) {
        my $ch = substr($str, $i, 1);
        if($ch eq "\\") {
            my $ch2 = substr($str, $i+1, 1);
            if($ch2 eq '' || index("abfntrg0\\", $ch2) >= 0) {
               $result .= $ch;
            } elsif(index('xNuU', $ch2) >= 0 || $delim eq "'") {
               $result .= $ch;
               $result .= "\\";
            }
            $result .= $ch2;
            $i++;
        } else {
            $result .= $ch;
        }
    }
    say STDERR "escape_re_sub($str, $delim) = $result" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
    return $result;
}

sub handle_use_lib
# use lib LIST
{
    my $pos = 0;
    if($Pythonizer::PassNo!=&Pythonizer::PASS_1) {
        return;
    }
    my @libs = ();
    for(my $i=$pos+2; $i<=$#ValClass; $i++) {
        if($ValClass[$i] eq '"') {          # Plain String
            push @libs, $ValPy[$i];
        } elsif($ValClass[$i] eq 'q') {     # qw(...) or the like
            if(index(q('"), substr($ValPy[$i],0,1)) >= 0) {
                push @libs, $ValPy[$i];
            } else {
                push @libs, map {'"'.$_.'"'} split(' ', $ValPy[$i]);         # qw(...) on use stmt doesn't generate the split
            }
        } elsif($ValClass[$i] eq 'f') {     # Handle dirname($0) only
            if($ValPerl[$i] eq 'dirname' && $ValPerl[$i+1] eq '$0') {
                push @libs, '"' . dirname($Pythonizer::fname) . '"';
                $i++;
            } elsif($ValPerl[$i] eq 'dirname' && $ValPerl[$i+1] eq '(' && $ValPerl[$i+2] eq '$0') {
                push @libs, '"' . dirname($Pythonizer::fname) . '"';
                $i += 3;
            } else {
                logme('W', "use lib $ValPerl[$i]() not handled!");
            }
        }
    }
    say STDERR "For @ValPerl, using @libs (after stripping the '')" if($debug);
    unshift @UseLib, map {&::unquote_string($_)}  @libs;
}

sub handle_use_overload                         # issue s3
# use overload key => \&sub, ...
{
    my $pos = 0;
    for(my $i=$pos+2; $i<=$#ValClass; $i++) {
        if($ValClass[$i] eq 'i') {          # sub
            $Pythonizer::SubAttributes{$ValPy[$i]}{overloads} = 1;
        }
    }
}

sub get_mapped_names_for_package        # SNOOPYJC
# Given a package name, get the mapped names (e.g. name_a, name_h, name_v) for it by reading the python code
{
    my $pkg_name = shift;
    # FIXME: If we have processed a "require" that includes this package, then use the filename from that reference to find the code
    # instead of assuming it's name based on the package name.
    my $filepy = ($pkg_name =~ s([.])(/)gr) . '.py';
    $fullpy = undef;
    my @places = @UseLib;
    push @places, @INC;
    my $path = undef;
    for my $place (@places) {
        $fullpy = catfile($place, $filepy);
        if(-f $fullpy) {
            $path = $place;
            last;
        }
    }
    if(!$path) {
        logme('W',  "Can't find $filepy in @places to get mapped names - conflicting variable names may be mapped incorrectly");
        $fullpy = undef;
        return {};
    }
    my @lockfiles = glob(catfile(dirname($fullpy), "*.lock"));
    #say STDERR "Found @lockfiles";
    if(&::lock_it($fullpy)) {
        #say STDERR "Was able to lock $fullpy lockfile";
        &::unlock_it($fullpy);
    } else {
        # Here if it's already locked - which means it's not fully baked yet
        say STDERR "get_mapped_names_for_package($pkg_name) - was locked - returning empty hashref" if($::debug);
        return {};
    }
    say STDERR "Opening $fullpy" if($::debug);
    if(!open(PYTHON, '<', $fullpy)) {
        logme('W',  "Can't open $fullpy to get mapped names - conflicting variable names may be mapped incorrectly");
        return {};
    }
    local $.;
    %found_map = ();
    my $base_pattern = '[A-Za-z_][A-Za-z0-9_]*';
    #my $package_name_pattern = '\b(?:[A-Za-z][A-Za-z0-9_]*[.])+';
    my $package_name_pattern = '\b' . quotemeta ($pkg_name . '.');      # Only look for this one package
    my @sigil_patterns = ('$',$package_name_pattern.scalar_var_name($base_pattern).'\b',
                          '@',$package_name_pattern.array_var_name($base_pattern).'\b',
                          '%',$package_name_pattern.hash_var_name($base_pattern).'\b',
                          '',$package_name_pattern.$base_pattern.'\b');
    while(<PYTHON>) {
        my $line = &Pythonizer::eat_strings($_);
        # Skip assignments of sub names to their packages like "ExportVars.get_xvar = get_xvar":
        next if($line =~ /^(?:[A-Za-z][A-Za-z0-9_]*[.])+([A-Za-z][A-Za-z0-9_]*) = ([A-Za-z][A-Za-z0-9_]*)/ && $1 eq $2);
        next if($line =~ /^\s*#/);              # comment line
        for(my $j=0; $j < scalar(@sigil_patterns); $j+=2) {
            my $sig = $sigil_patterns[$j];
            my $pat = $sigil_patterns[$j+1];
            #say STDERR "Checking $line for $pat";
            if($line =~ /($pat)/) {
                #say STDERR "(matched)";
                my $full_name = $1;
                my $last_dot = rindex($full_name, '.');
                my $package_name = substr($full_name,0,$last_dot);
                my $python_name = substr($full_name,$last_dot+1);
                if($sig eq '') {
                    my $perl_basename = $python_name;
                    if(substr($python_name,-1,1) eq '_') {
                        my $without_escape = substr($python_name,0,length($python_name)-1);
                        my $esc = escape_keywords($without_escape);
                        $perl_basename = $without_escape if($esc eq $python_name);
                    }
                    for $sig ('$', '@', '%') {
                        #my $perl_name = $sig . $perl_basename;
                        $found_map{$package_name . '.' . $perl_basename}{$sig} = escape_keywords($package_name, 1) . '.' . $python_name;
                    }
                } else {
                    #my $perl_name = $sig . substr($python_name,0,length($python_name)-2);
                    my $perl_basename = substr($python_name,0,length($python_name)-2);
                    $found_map{$package_name . '.' . $perl_basename}{$sig} = escape_keywords($package_name, 1) . '.' . $python_name;
                }
            }
        }
    }
    close(PYTHON);
    if($::debug >= 5) {
       $Data::Dumper::Indent=1;
       $Data::Dumper::Terse = 1;
       print STDERR "get_mapped_names_for_package($pkg_name) = ";
       say STDERR Dumper(\%found_map);
    }
    return \%found_map;
}

sub handle_use_require          # issue names
# In pass 1, handle use/require statement keeping track of what global variables are used by each module we include
# in order to figure out if we need to remap them or not.
{
    if($Pythonizer::PassNo!=&Pythonizer::PASS_1) {
        return;
    }

    my $pos = shift;

    say STDERR "handle_use_require($pos): @ValPerl" if($::debug >= 3);

    # This is a VERY simplified version of do_use_require() from pythonizer main program used in pass 2

     # require VERSION
     # require EXPR
     # require  (uses $_ as EXPR)
     #
     # use Module VERSION LIST
     # use Module VERSION
     # use Module LIST
     # use Module
     # use VERSION

     # Get rid of the VERSION, use constant, use open, and predefined forms
     
     if($pos+1 <= $#ValClass &&                 # use v5.24.1 -or- use 5.24.1 -or- use 5.024_001 -or-
         ($ValClass[$pos+1] eq 'd' ||           # use Carp::Assert (something built-in)
         ($ValClass[$pos+1] eq '"' && substr($ValPy[$pos+1],0,3) eq "'\\x") || 
         ($ValClass[$pos+1] eq 'i' && exists $BUILTIN_LIBRARY_SET{$ValPerl[$pos+1]}))) {
         return;
     } elsif($pos+1 <= $#ValClass && $ValClass[$pos+1] eq 'i' && ($ValPerl[$pos+1] eq 'constant' || $ValPerl[$pos+1] eq 'open' || $ValPerl[$pos+1] eq 'overload')) {    # issue s3
         return;
     }

     return;             # issue names - had to map them all

     # Ok - now for the real ones

     my $limit = $#ValClass;
     $TokenStr = join('', @ValClass);   # Required to use the Pythonizer functions
     my $opp = &Pythonizer::next_lower_or_equal_precedent_token('F', $pos, $limit);
     $limit = $opp-1 if($opp >= $pos);
     my $close = &Pythonizer::next_same_level_token(')', $pos, $limit);
     $limit = $close-1 if($close >= $pos);
     if($pos == $limit) {        # require;
         ;
     } elsif($pos+1 == $limit && $ValClass[$pos+1] eq 's') {  # require $x or use $x
         ;
     } elsif($pos+1 == $limit && $ValClass[$pos+1] eq '"') {  # require "..."
         if(substr($ValPy[$pos+1],0,1) eq 'f') {      # dynamic 'f' string
             ;
         } else {                        # Static string
             handle_import($pos);
         }
     } elsif($pos+1 <= $limit && $ValClass[$pos+1] eq 'i') {
         handle_import($pos);
     }
}

sub handle_import               # issue names
# Process a use/require statement with a constant string or bare name operand
# This code is based on import_it from the pythonizer main program
# In pass 1, we want to look at everything imported to check for conflicting names, and remember this
# information for the potential re-translation of the included modules in pass 2.
{
    my $pos = shift;

    my $file;
    my $filepy;
    my @places = @UseLib;
    push @places, @INC;
    if($ValClass[$pos+1] eq '"') {           # require '...' - at this point this is at least a constant string!
        $file = &::unquote_string($ValPy[$pos+1]);
        say STDERR "handle_import($file)" if $::debug;
        return if($file !~ /[A-Za-z0-9_.-]/); # Not a good filename
        $filepy = $file;
        $filepy =~ s/\.pl$/.py/;
    } else {
        $file = $ValPy[$pos+1];
        say STDERR "handle_import($file)" if $::debug;
        return if($file !~ /[A-Za-z0-9_.]/); # Not a good filename
        $file =~ s([.])(/)g;
        $filepy = $file . '.py';
        $file .= '.pm';
    }

    my %found_map = ();

    my $path;
    my $fullfile = $file;
    my $fullpy = $filepy;
    if(file_name_is_absolute($file)) {
        $path = dirname($file);
    } else {
        for my $place (@places) {
            $fullfile = catfile($place, $file);
            if(-f $fullfile) {
                $path = $place;
                $fullpy = catfile($place, $filepy);
                last;
            } else {
                $fullfile = $file;
            }
        }
    }
    my $stat = 0;
    if(! -f $fullfile) {     # Can't find it
        say STDERR "handle_import($fullfile): file not found" if($::debug);
        return;
    }
    my $dir = dirname(__FILE__);
    #say STDERR "before: tell(STDIN)=" . tell(STDIN) . ", eof(STDIN)=" . eof(STDIN);
    say STDERR "\@export_info = `perl $dir/pythonizer_importer.pl $fullfile`;" if($::debug >= 3);
    @export_info = `perl $dir/pythonizer_importer.pl $fullfile`;
    #say STDERR "after:  tell(STDIN)=" . tell(STDIN) . ", eof(STDIN)=" . eof(STDIN);
    say STDERR "handle_import($fullfile): got @export_info" if($::debug>=3);
    if ($export_info[-1] !~ /\@global_vars=qw/) {
        logme('W', "Could not import $fullfile for $ValPerl[$pos] " . $ValPerl[$pos+1]);
        return;
    }
    chomp(my $pkg = $export_info[0]);
    chomp(my $vars = $export_info[-1]);
    say STDERR "handle_import($fullfile): Found $pkg $vars for Pass 1 $ValPerl[$pos] " . $ValPerl[$pos+1] if($::debug);
    $pkg =~ s'\$package=\''';
    $pkg =~ s/';//;
    $vars =~ s'@global_vars=qw/'';
    $vars =~ s'/;'';
    @vars = split ' ', $vars;
    $pkg .= '::';
    #    WHY IS THIS A SYNTAX ERROR???  %vars = map { "$pkg$_" => 1 } @vars;
    %vars = ();
    for my $var (@vars) {
        my $sigil = substr($var,0,1);
        if($sigil =~ /\w/) {
            $vars{"$pkg$var"} = 1;
        } else {
            my $nam = substr($var,1);
            $vars{"$sigil$pkg$nam"} = 1;
        }
    }

    $UseRequireVars{$fullfile} = (dclone \%vars);

    if(-f $fullpy) {            # If we previously pythonized it, get the options used
        my $opts = get_pythonizer_options_used($fullpy);
        if(defined $opts) {
            $UseRequireOptionsPassed{$fullfile} = $opts;
        }
    }
}

sub get_pythonizer_options_used
# Try to get the options used when pythonizing the given file
{
    local $.;

    my $pyfile = shift;

    my $python_file;

    if(!open(PYTHON, '<', $pyfile)) {
        return undef;
    }
    my $l1 = <PYTHON>;          #!/usr/bin/env python3
    my $l2 = <PYTHON>;          # Generated by "pythonizer ddts_archivalScript.pl" v0.964 run by JO2742 on Mon Mar 14 00:21:50 2022
                                # Generated by "pythonizer -M -v0 main.pl" v0.964 run by JO2742 on Sun Mar 13 22:55:12 2022
    close(PYTHON);
    my $result = '';
    if($l2 =~ /^# Generated by ".*? (-.*)? [A-Za-z0-9_\/\\.]+" v/) {
        $result = $1;
    }
    say STDERR "get_pythonizer_options_used($pyfile) = $result" if $::debug;
    return $result;
}

sub compute_desired_use_require_options
# For each lib that we use/require, compute the desired options needed to translate it properly, considering
# name mapping issues.  The '-R' flag options is what we are computing here.
{
    return if(scalar(%UseRequireVars) == 0);    # Don't do anything if we have no vars to take care of
    
    # start by looking at all names in our NameMap, and see which ones have multiple sigils at the "package" level, and add
    # them into another entry to UseRequireVars using '.' as the filename to represent the file being currently processed
    my %ournames = ();
    for my $name (keys %NameMap) {
        my @sigils = keys %{$NameMap{$name}};
        next if scalar(@sigils) == 1;
        my $found_package_var = 0;
    SIGILLOOP:
        for my $sigil (@sigils) {
            for my $sub (keys %sub_varclasses) {
                my $fullname = $sigil . $name;
                if(exists $sub_varclasses{$sub}->{$fullname} && $sub_varclasses{$sub}->{$fullname} eq 'package') {
                    $found_package_var = 1;
                    last SIGILLOOP;
                }
            }
        }
        if($found_package_var) {
            my $pkg = cur_package() . '::';
            for my $sigil (@sigils) {
                $ournames{$sigil . $pkg . $name} = 1;
            }
        }
    }
    $UseRequireVars{'.'} = \%ournames;

    # Now walk thru UseRequireVars and pick out the ones with multiple sigils, these have to have the -R option passed to the
    # modules that reference them
    
    my %names_to_sigils=();             # Map from names with packages but w/o sigils to the sigils referenced
    for my $file (keys %UseRequireVars) {
        for my $fullname (keys %{$UseRequireVars{$file}}) {
            my $sigil = substr($fullname,0,1);
            my $name = substr($fullname,1);
            if($sigil =~ /\w/) {        # No sigil
                $sigil = '';
                $name = $fullname;
            }
            $names_to_sigils{$name}{$sigil} = 1;
        }
    }

    # Now compute which files need which -R options based on which names they refer to

    for my $name (sort keys %names_to_sigils) {      # like $main::name - we sort them so we don't have to worry about matching -Rabc,def with -Rdef,abc
        my @sigils = keys %{$names_to_sigils{$name}};
        next if(scalar(@sigils) == 1);
        for my $file (keys %UseRequireVars) {
            $needs_R = 0;
            for my $sigil (@sigils) {
                if(exists $UseRequireVars{$file}{$sigil . $name}) {
                    $needs_R = 1;
                    last;
                }
            }
            if($needs_R) {
                my $basename = $name =~ s/[\w:]+::(\w+)$/$1/r;
                if(exists($UseRequireOptionsDesired{$file})) {
                    $UseRequireOptionsDesired{$file} .= ',' . $basename;
                } else {
                    $UseRequireOptionsDesired{$file} = '-R' . $basename;
                }
                if($file eq '.') {              # if we're setting for us, then handle that immediately here
                    remap_conflicting_names($basename, '', '');
                }
            }
        }
    }
}

my %regex_flag_map = (A=>'a', I=>'i', L=>'L', M=>'m', S=>'s', U=>'u', X=>'x');

sub build_in_qr_flags           # issue s3
# issue s3: for a qr not used directly in a regex, build the flags into the regex using (?flags:regex).  This is to allow
# the regex to be used later in a larger regex without losing the flags because we change /$regex/ to regex.pattern in
# the generated code.
# usage: ($regex, $modifier) = build_in_qr_flags($arg1, $modifier);
{
    my ($regex, $flags) = @_;

    return ($regex, $flags) unless $flags;

    $flags =~ s/[|]/,/g;        # change ,re.I|re.S to ,re.I,re.S
    $flags =~ s/re\.//g;        # remove the 're.', so now we have ,I,S
    my @flags = split /,/, $flags;
    my $mapped_flags = '';
    for $f (@flags) {
        next unless $f;
        if(exists $regex_flag_map{$f}) {
            $mapped_flags .= $regex_flag_map{$f};
        } elsif($Pythonizer::PassNo==&Pythonizer::PASS_2) {
            logme('W', "Regex flag '$f' is not supported here by python - ignored");
        }
    }
    return ("(?$mapped_flags:$regex)", '');
}

sub is_concat                   # issue s15
# Check the prior token to see if this what looks like a float constant is really a string concat
# e.g. "a".1234 $s.1234 $h{key}.1234, $a[ndx].1234 (expr).1234
{
    return 0 if($tno == 0);
    return 0 if $ValClass[$tno-1] eq '"' && $ValPerl[$tno-1] =~ /^v\d*/ && substr($ValPy[$tno-1],1,2) eq "\\x"; # version string
    return (index('"sahgjGx)', $ValClass[$tno-1]) >= 0);
}

1;

