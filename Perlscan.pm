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

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXPORT = qw(gen_statement tokenize gen_chunk append replace destroy insert destroy autoincrement_fix @ValClass  @ValPerl  @ValPy @ValCom @ValType $TokenStr escape_keywords %SPECIAL_FUNCTION_MAPPINGS save_code restore_code %token_precedence %SpecialVarsUsed @EndBlocks %SpecialVarR2L);	# issue 41, issue 65, issue 74, issue 92, issue 93
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
                '-'=>"$DEFAULT_MATCH.start",    # SNOOPYJC
                '+'=>"$DEFAULT_MATCH.end",      # SNOOPYJC
                '/'=>'INPUT_RECORD_SEPARATOR',','=>'OUTPUT_FIELD_SEPARATOR','\\'=>'OUTPUT_RECORD_SEPARATOR',
                '%'=>'FORMAT_PAGE_NUMBER', '='=>'FORMAT_LINES_PER_PAGE', '~'=>'FORMAT_NAME', '^'=>'FORMAT_TOP_NAME',    # SNOOPYJC
                ':'=>'FORMAT_LINE_BREAK_CHARACTERS',
                );
   %SPECIAL_VAR2=('O'=>'os.name','T'=>'OS_BASETIME', 'V'=>'sys.version[0]', 'X'=>'sys.executable()', # $^O and friends
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
   %SpecialArrayType=('ARGV'=>'a of S', '_'=>'a of m');
   %SpecialHashType=('ENV'=>'h of m');          # Not 'h of S' as when we pull a non-existant key we get None!

   # Map of functions to python where the mapping is different for scalar and list context
   %SPECIAL_FUNCTION_MAPPINGS=('localtime'=>{scalar=>'tm_py.ctime', list=>'_localtime'},        # issue times
                'gmtime'=>{scalar=>'_cgtime', list=>'_gmtime'},                                 # issue times
                'reverse'=>{list=>'[::-1]', scalar=>'_reverse_scalar'}  # issue 65
                );


   %keyword_tr=('eq'=>'==','ne'=>'!=','lt'=>'<','gt'=>'>','le'=>'<=','ge'=>'>=',
                'and'=>'and','or'=>'or','not'=>'not',
                'x'=>' * ',
                'abs'=>'abs',                           # SNOOPYJC
                'alarm'=>'signal.alarm',                # issue 81
		'assert'=>'assert',			# SNOOPYJC
		'atan2'=>'math.atan2',			# SNOOPYJC
		'basename'=>'_basename',		# SNOOPYJC
                'binmode'=>'_dup',                      # SNOOPYJC
                'bless'=>'NoTrans!','BEGIN'=>'if True:',        # SNOOPYJC
                # SNOOPYJC 'caller'=>q(['implementable_via_inspect',__file__,sys._getframe().f_lineno]),
		# issue 54 'chdir'=>'.os.chdir','chmod'=>'.os.chmod',
                'carp'=>'_carp', 'confess'=>'_confess', 'croak'=>'_croak', 'cluck'=>'_cluck',   # SNOOPYJC
                'longmess'=>'_longmess', 'shortmess'=>'_shortmess',                             # SNOOPYJC
		'chdir'=>'os.chdir','chmod'=>'os.chmod',	# issue 54
		'chomp'=>'.rstrip("\n")','chop'=>'[0:-1]','chr'=>'chr',
		# issue close 'close'=>'.f.close',
		'close'=>'.close()',	# issue close
                'cmp'=>'_cmp',                          # SNOOPYJC
                # issue 42 'die'=>'sys.exit', 
                'die'=>'raise Die',     # issue 42
                'dirname'=>'_dirname',          # SNOOPYJC
                'defined'=>'unknown', 'delete'=>'.pop(','defined'=>'perl_defined',
                'each'=>'_each',                        # SNOOPYJC
                'END'=>'_END_',                      # SNOOPYJC
                'for'=>'for','foreach'=>'for',          # SNOOPYJC: remove space from each
                'else'=>'else: ','elsif'=>'elif ',
                # issue 42 'eval'=>'NoTrans!', 
                'eval'=>'try',  # issue 42
                'exit'=>'sys.exit','exists'=> 'in', # if  key in dictionary 'exists'=>'.has_key'
                'fc'=>'.casefold()',                    # SNOOPYJC
		'flock'=>'_flock',			# issue flock
                'fileparse'=>'_fileparse',              # SNOOPYJC
                'fork'=>'os.fork',                      # SNOOPYJC
		'glob'=>'glob.glob',			# SNOOPYJC
                'if'=>'if ', 'index'=>'.find',
		'int'=>'int',				# issue int
		'GetOptions'=>'argparse',		# issue 48
		'gmtime'=>'_gmtime',    		# issue times
                'grep'=>'filter', 'goto'=>'goto', 'getcwd'=>'os.getcwd',
                'join'=>'.join(',
		# issue 33 'keys'=>'.keys',
                'keys'=>'.keys()',	# issue 33
                'kill'=>'os.kill',      # SNOOPYJC
                'last'=>'break', 'local'=>'', 'lc'=>'.lower()', 'length'=>'len', 
		# issue localtime 'localtime'=>'.localtime',
		'localtime'=>'_localtime',		# issue times
                'lstat'=>'_lstat',              # SNOOPYJC
                'map'=>'map', 'mkdir'=>'os.mkdir', 'my'=>'',
                'next'=>'continue', 'no'=>'NoTrans!',
                'own'=>'global', 'oct'=>'oct', 'ord'=>'ord',
                'our'=>'',                      # SNOOPYJC
                'package'=>'package', 'pop'=>'.pop()', 'push'=>'.extend(',
                'printf'=>'print',
                'quotemeta'=>'re.escape',       # SNOOPYJC
                'rename'=>'os.replace',         # SNOOPYJC
                'say'=>'print','scalar'=>'len', 'shift'=>'.pop(0)', 'split'=>'re.split', 
                'seek'=>'.seek',                # SNOOPYJC
		# issue 34 'sort'=>'sort', 
                'sleep'=>'tm_py.sleep',         # SNOOPYJC
		'sqrt'=>'math.sqrt',		# SNOOPYJC
		'sort'=>'sorted', 		# issue 34
		'state'=>'global',
                'rand'=>'_rand',                # SNOOPYJC
                'read'=>'.read',                # issue 10
                   'stat'=>'_stat','sysread'=>'.read',
                   'substr'=>'','sub'=>'def','STDERR'=>'sys.stderr','SYSIN'=>'sys.stdin','system'=>'os.system','sprintf'=>'',
		   'STDOUT'=>'sys.stdout',	# issue 10
                   'sysseek'=>'perl_sysseek',
                   'STDERR'=>'sys.stderr','STDIN'=>'sys.stdin', '__LINE__' =>'sys._getframe().f_lineno',
                'reverse'=>'[::-1]',            # issue 65
                'rindex'=>'.rfind', 
                # SNOOPYJC 'ref'=>'type', 
                'ref'=>'_ref',                  # SNOOPYJC
                # SNOOPYJC 'require'=>'NoTrans!', 
                'require'=>'__import__',        # SNOOPYJC
                'return'=>'return', 'rmdir'=>'os.rmdir',
                'tell'=>'.tell',                # SNOOPYJC
                'tie'=>'NoTrans!',
		'time'=>'_time',		# SNOOPYJC
		'timelocal'=>'_timelocal',	# issue times
                'timegm'=>'_timegm',            # issue times
                'uc'=>'.upper()', 'ucfirst'=>'.capitalize()', 'undef'=>'None', 'unless'=>'if not ', 'unlink'=>'os.unlink',
                'umask'=>'os.umask',            # SNOOPYJC
                   'unshift'=>'.insert(0,',
                   # SNOOPYJC 'use'=>'NoTrans!', 
                   'use'=>'import',
                   'until'=>'while not ','untie'=>'NoTrans!',
                'values'=>'.values()',	# SNOOPYJC
                 'warn'=>'print',
                 'wait'=>'_wait',       # SNOOPYJC
                 'waitpid'=>'_waitpid',         # SNOOPYJC
                 'wantarray'=>'True',           # SNOOPYJC
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
                  'caller'=>'f','chdir'=>'f','chomp'=>'f', 'chop'=>'f', 'chmod'=>'f','chr'=>'f','close'=>'f',
                  'carp'=>'f', 'confess'=>'f', 'croak'=>'f', 'cluck'=>'f',   # SNOOPYJC
                  'longmess'=>'f', 'shortmess'=>'f',                         # SNOOPYJC
                  'cmp'=>'>',           # SNOOPYJC: comparison
                  'delete'=>'f',        # issue delete
                  'default'=>'C','defined'=>'f','die'=>'f',
                  'dirname'=>'f',     # SNOOPYJC
                  'do'=>'C',            # SNOOPYJC
                  'each'=>'f',          # SNOOPYJC
                  'else'=>'C', 'elsif'=>'C', 'exists'=>'f', 'exit'=>'f', 'export'=>'f',
                  'eval'=>'C',          # issue 42
                  'fc'=>'f',            # SNOOPYJC
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
                  'join'=>'f',
                  'keys'=>'f',
                  'kill'=>'f',          # SNOOPYJC
                  'last'=>'k', 'lc'=>'f', 'length'=>'f', 'local'=>'t', 'localtime'=>'f',
                  'lstat'=>'f',
                  'my'=>'t', 'map'=>'f', 'mkdir'=>'f',
                  'next'=>'k','not'=>'!',
                  'our'=>'t',                   # SNOOPYJC
                  # issue 93 'or'=>'0', 
                  'or'=>'o',                    # issue 93
                  'own'=>'t', 'oct'=>'f', 'ord'=>'f', 'open'=>'f',
		  'opendir'=>'f', 'closedir'=>'f', 'readdir'=>'f', 'seekdir'=>'f', 'telldir'=>'f', 'rewinddir'=>'f',	# SNOOPYJC
                  'push'=>'f', 'pop'=>'f', 'print'=>'f', 'package'=>'c',
                  'printf'=>'f',                # SNOOPYJC
                  'quotemeta'=>'f',             # SNOOPYJC
                  'rand'=>'f',                  # SNOOPYJC
                  'require'=>'k',               # SNOOPYJC
                  'rindex'=>'f','read'=>'f', 
                  'rename'=>'f',                # SNOOPYJC
		  # issue 61 'return'=>'f', 
		  'return'=>'k', 		# issue 61
                  'reverse'=>'f',               # issue 65
		  'ref'=>'f',
                  'say'=>'f','scalar'=>'f','shift'=>'f', 'split'=>'f', 'sprintf'=>'f', 'sort'=>'f','system'=>'f', 'state'=>'t',
                  'seek'=>'f',          # SNOOPYJC
		  'sleep'=>'f',		# SNOOPYJC
		  'sqrt'=>'f',		# SNOOPYJC
                  'stat'=>'f','sub'=>'k','substr'=>'f','sysread'=>'f',  'sysseek'=>'f',
                  'tell'=>'f',          # SNOOPYJC
                  'tie'=>'f',
		  'time'=>'f', 'gmtime'=>'f', 'timelocal'=>'f',	'timegm'=> 'f', # SNOOPYJC
		  'unlink'=>'f',		# SNOOPYJC
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
                  );
                      # NB: Use ValPerl[$i] as the key here!
       %FuncType=(    # a=Array, h=Hash, s=Scalar, I=Integer, F=Float, N=Numeric, S=String, u=undef, f=function, H=FileHandle, ?=Optional, m=mixed
                  '_num'=>'m:N', '_int'=>'m:I', '_str'=>'m:S',
                  '_assign_global'=>'SSm:m',
		  'abs'=>'N:N', 'alarm'=>'N:N', 'atan2'=>'NN:F', 
                  'autoflush'=>'I?:I', 'basename'=>'S:S', 'binmode'=>'HS?:m',
                  'carp'=>'a:u', 'confess'=>'a:u', 'croak'=>'a:u', 'cluck'=>'a:u',   # SNOOPYJC
                  'longmess'=>'a:S', 'shortmess'=>'a:S',                             # SNOOPYJC
                  'chdir'=>'S:I','chomp'=>'S:m', 'chop'=>'S:m', 'chmod'=>'Ia:m','chr'=>'I?:S','close'=>'H:I',
                  'cmp'=>'SS:I', '<=>'=>'NN:I',
                  'delete'=>'u:a', 'defined'=>'u:I','die'=>'S:m', 'dirname'=>'S:S', 'each'=>'h:a', 'exists'=>'u:I', 
                  'exit'=>'I?:u', 'fc'=>'S:S', 'flock'=>'HI:I', 'fork'=>':m',
                  'fileparse'=>'SS?:a of S',
                  'glob'=>'S:a of S', 'index'=>'SSI?:I', 'int'=>'s:I', 'grep'=>'Sa:a of S', 'join'=>'Sa:S', 'keys'=>'h:a of S', 
                  'kill'=>'II:u', 'lc'=>'S:S', 'lstat'=>'S:a of I',
                  'length'=>'S:I', 'localtime'=>'I?:a of I', 'map'=>'fa:a', 'mkdir'=>'SI?:I', 'oct'=>'s:I', 'ord'=>'S:I', 'open'=>'HSS?:I',
		  'opendir'=>'HS:I', 'closedir'=>'H:I', 'readdir'=>'H:S', 'rename'=>'SS:I', 'seekdir'=>'HI:I', 'telldir'=>'H:I', 'rewinddir'=>'H:m',
                  'push'=>'aa:I', 'pop'=>'a:s', 'print'=>'H?a:I', 'printf'=>'H?Sa:I', 'quotemeta'=>'S:S', 'rand'=>'F?:F',
                  'rindex'=>'SSI?:I','read'=>'HsII?:I', 'reverse'=>'a:a', 'ref'=>'u:S', 
                  'say'=>'H?a:I','scalar'=>'a:I','seek'=>'HII:u', 'shift'=>'a?:s', 'sleep'=>'I:I', 'split'=>'SSI?:a of S', 'sprintf'=>'Sa:S', 'sort'=>'fa:a','system'=>'a:I',
                  'sqrt'=>'N:F', 'stat'=>'S:a of I', 'substr'=>'SII?S?:S','sysread'=>'HsII?:I',  'sysseek'=>'HII:I', 'tell'=>'H:I', 'time'=>':I', 'gmtime'=>'I?:a of I', 'timegm'=>'IIIIII:I',
                  'timelocal'=>'IIIIII:I', 'unlink'=>'a?:I', 'values'=>'h:a', 'warn'=>'a:I', 'undef'=>'a?:u', 'unshift'=>'aa:I', 'uc'=>'S:S',
                  'ucfirst'=>'S:S', 'umask'=>'I?:I'
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
sub TRY_BLOCK_EXCEPTION { 1 }
sub TRY_BLOCK_FINALLY { 2 }
%line_needs_try_block=();       # issue 94, issue 108: Map from line number to TRY_BLOCK_EXCEPTION|TRY_BLOCK_FINALLY if that line needs a try block
%line_locals=();                # issue 108: Map from line number to a list of locals
%line_locals_map=();            # issue 108: Map from line number to a map from perl name to python name
%line_sub=();                   # issue 108: Map from line number to sub name
%line_substitutions=();         # SNOOPYJC: Map from line number to a hash ref of pattern substitutions needed
%line_varclasses=();            # SNOOPYJC: Map from line number to var classes (e.g. 'my', 'our', etc)
%sub_varclasses=();             # SNOOPYJC: Map from sub to var classses
$last_varclass_lno = 0;         # SNOOPYJC: Last entry in the above
$ate_dollar = -1;               # issue 50: if we ate a '$', where was it?
sub initialize                  # issue 94
{
    $nesting_level = 0;
    @nesting_stack = ();
    $last_label = undef;
    $last_block_lno=0;
    $ate_dollar = -1;
}


sub add_package_name
# Add the package name to this var if it's a global and it doesn't already have a package name
# Arg = the real perl name of this var, e.g. $xxx{} => %xxx
{
    my $name = shift;
    my $py = $ValPy[$tno];

    return if($::implicit_global_my);
    return if(index($py, '.') >= 0);
    return unless(exists $line_varclasses{$.});
    if(substr($name,0,2) eq '$#') {
        $name = '@' . substr($name,2);
    }
    return unless(exists $line_varclasses{$.}{$name});
    return unless($line_varclasses{$.}{$name} =~ /global|local/);
    if($ValPy[$tno] =~ /^\(len\((.*)\)-1\)$/) {
        $ValPy[$tno] = '(len(' . cur_package() . '.' . $1 . ')-1)';
    } else {
        $ValPy[$tno] = cur_package() . '.' . $ValPy[$tno];         # Add the package name
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
    return if($tno != 0 && $ValPy[$tno-1] eq '.');
    return if($Pythonizer::LocalSub{$perl_name});
    $ValPy[$tno] = cur_package() . '.' . $ValPy[$tno];         # Add the package name
    say STDERR "Changed $py to $ValPy[$tno] for non-local sub" if($::debug >= 5);
}

sub add_package_name_j
# For <$fh>, add the package name if need be.  This is a little harder than the
# normal case, because $ValPy[$tno] could be either like fh.readlines() -or- 
# _readline(fh) -or- _readline_full(fh) and we need to find the filehandle and
# potentially replace it.
{
    my $name = substr($ValPerl[$tno],1,length($ValPerl[$tno])-2);    # <$fh> -> $fh
    return if($::implicit_global_my);
    return unless(exists $line_varclasses{$.});
    return unless(exists $line_varclasses{$.}{$name});
    return unless($line_varclasses{$.}{$name} =~ /global|local/);

    my $py = $ValPy[$tno];
    my $var = substr($name,1);          # fh
    if($py =~ /\b($var(?:_|_v)?)\b/) {
        my $start = $-[1];
        return if(substr($py,$start-1,1) eq '.');
        substr($ValPy[$tno], $start, 0) = cur_package() . '.';
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
    }
    say STDERR "get_perl_name($oname, $next, $prev) = $name" if($::debug >= 5);
    return $name;
}

sub cur_package
{
    my $result;
    if($Pythonizer::PassNo) {
        $result = $::CurPackage;
    } elsif(!@Pythonizer::Packages) {
        $result = $DEFAULT_PACKAGE;
    } else {
        $result = $Pythonizer::Packages[-1];
    }
    $Pythonizer::Packages{$result} = 1;
    return $result;
}

sub capture_varclass_j          # SNOOPYJC: Only called in the first pass
# We just lexed a <$fh>, Keep track of what class this is
{
    my $name = substr($ValPerl[$tno],1,length($ValPerl[$tno])-2);    # <$fh> -> $fh
    my $class = 'global';
    if($last_varclass_lno != $. && $last_varclass_lno) {
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
    }
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
    $TokenStr=join('',@ValClass);
    if($ValClass[0] eq 't' && index($TokenStr,'=') < 0) {           # We are declaring this var
        $class = $ValPerl[0];
        $class = 'myfile' if($class eq 'my' && !in_sub());
    } elsif($ValClass[0] eq 'c' && $ValClass[1] eq '(' && $ValClass[2] eq 't') {      # e.g. for(my $i
        $class = $ValPerl[2];
    } elsif($ValClass[0] eq 'f' && $ValPerl[0] eq 'open' && $ValClass[1] eq 't') {      # e.g. open my $fh
        $class = $ValPerl[1];
    } elsif($ValClass[0] eq 'f' && $ValPerl[0] eq 'open' && $ValClass[1] eq '(' && $ValClass[2] eq 't') {  # e.g. open(my $fh
        $class = $ValPerl[2];
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
    if(!exists $line_varclasses{$last_varclass_lno}{$name} || $class eq 'my' || $class eq 'local') {
        $line_varclasses{$last_varclass_lno}{$name} = $class;
        $sub_varclasses{cur_sub()}{$name} = $class;
    } elsif(exists $line_varclasses{$last_varclass_lno}{$name}) {
        $class = $line_varclasses{$last_varclass_lno}{$name};
    }
    add_package_name($name) if($class eq 'global' || $class eq 'local');
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

sub def_label                   # issue 94
{
    $label = shift;
    if($::debug >= 4) {
        say STDERR "def_label($label)";
    }
    $last_label = $label;
    $all_labels{$label} = 1;
}

sub in_sub                      # SNOOPYJC
{
    return 0 if(!@nesting_stack);
    $top = $nesting_stack[-1];
    return $top->{in_sub};
}

sub cur_sub                     # SNOOPYJC
{
    return 'main' if(!@nesting_stack);
    $top = $nesting_stack[-1];
    return (defined $top->{cur_sub} ? $top->{cur_sub} : 'main');
}

sub enter_block                 # issue 94
{
    # SNOOPYJC: Now we use a different character (^ all alone) to replace the '{' for the second round
    # SNOOPYJC return if($last_block_lno == $. && scalar(@ValPerl) <= 1);       # We see the '{' twice on like if(...) {
    if($::debug >= 4) {
        no warnings;
        say STDERR "enter_block at line $., prior nesting_level=$nesting_level, ValPerl=@ValPerl";
    }
    if(!$Pythonizer::PassNo) {          # Do this in the first pass only
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
    $nesting_info{lno} = $.;
    $nesting_info{varclasses} = dclone($line_varclasses{$last_block_lno}) if(!$Pythonizer::PassNo);
    $nesting_info{level} = $nesting_level;
    # Note a {...} block by itself is considered a loop
    $nesting_info{is_loop} = ($begin <= $#ValClass && ($ValPy[$begin] eq '{' || $ValPerl[$begin] eq 'for' || $ValPerl[$begin] eq 'foreach' ||
                                           $ValPerl[$begin] eq 'while' || $ValPerl[$begin] eq 'until'));
    $nesting_info{is_eval} = ($begin <= $#ValClass && $ValPerl[$begin] eq 'eval');
    $nesting_info{is_sub} = ($begin <= $#ValClass && $ValPerl[$begin] eq 'sub');
    $nesting_info{cur_sub} = (($begin+1 <= $#ValClass && $nesting_info{is_sub}) ? $ValPerl[$begin+1] : undef);

    $nesting_info{in_loop} = ($nesting_info{is_loop} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_loop}));
    $nesting_info{in_sub} = ($nesting_info{is_sub} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_sub}));
    if($nesting_info{in_sub} && !$nesting_info{is_sub}) {
        $nesting_info{cur_sub} = $nesting_stack[-1]{cur_sub};
    }
    if(defined $last_label) {
        $nesting_info{label} = $last_label;
        $last_label = undef;            # We used it up
    }
    push @nesting_stack, \%nesting_info;
    if($::debug >= 4) {
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
    if($::debug >= 4) {
        say STDERR "exit_block at line $., prior nesting_level=$nesting_level, nesting_last->{type} is now $nesting_last->{type}";
    }
    determine_varclass_keepers($nesting_last->{varclasses}, $nesting_last->{lno}) if(!$Pythonizer::PassNo);
    my $label = '';
    $label = $nesting_last->{label} if(exists $nesting_last->{label});
    if(exists $nesting_last->{can_call} && $Pythonizer::PassNo == 0) {
        for $sub (keys %{$nesting_last->{can_call}}) {
            if(exists $sub_external_last_nexts{$sub} && exists $sub_external_last_nexts{$sub}{$label}) {
                say STDERR "exit_block: setting line_needs_try_block{$nesting_last->{lno}} from call to $sub" if($::debug >= 5);
                $line_needs_try_block{$nesting_last->{lno}} |= TRY_BLOCK_EXCEPTION;
            }
        }
    }
    $nesting_level--;
}
sub last_next_propagates        # issue 94
# Does this last/next propagate out of this sub?
# Side effect - sets {needs_try_block} on any loops we need to generate a try block for
{
    $pos = shift;
    $label = shift;

    if(!defined $label) {
        return 1 if($nesting_level == 0);
        $top = $nesting_stack[-1];
        if($pos != 0 && $top->{in_loop}) {      # If this is NOT a stmt level last/next, we need the exception for it
            for $ndx (reverse 0 .. $#nesting_stack) {
                if($nesting_stack[$ndx]->{is_loop}) {
                    $nesting_stack[$ndx]->{needs_try_block} = 1;
                    say STDERR "last_next_propagates: setting line_needs_try_block{$nesting_stack[$ndx]->{lno}} from last/next at line $." if($::debug >= 5);
                    $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= TRY_BLOCK_EXCEPTION;
                    last;
                }
            }
        }
        return !($top->{in_loop} || $top->{in_eval});
    } elsif($Pythonizer::PassNo == 0) {         # only do this once
        for $ndx (reverse 0 .. $#nesting_stack) {
            if(exists $nesting_stack[$ndx]->{label} && $nesting_stack[$ndx]->{label} eq $label) {
                if($pos != 0 || $ndx != $#nesting_stack) {           # No need to use exception for last/next inner if at stmt level;
                    $nesting_stack[$ndx]->{needs_try_block} = 1;
                    say STDERR "last_next_propagates: setting line_needs_try_block{$nesting_stack[$ndx]->{lno}} from last/next at line $." if($::debug >= 5);
                    $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= TRY_BLOCK_EXCEPTION;
                }
                return 0;
            }
        }
        return 1;
    }
}

sub handle_return_in_expression         # SNOOPYJC: Handle 'return' in the middle of an expression
{
    return if($Pythonizer::PassNo != 0);
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
    return 1 if(exists $line_needs_try_block{$top->{lno}});
    return 0;
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
            gen_statement("$pyname = $LOCALS_STACK.pop()");
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
    return 1 if($nesting_level == 0);           # Generate an exception instead of a syntax error
    my $top = $nesting_stack[-1];
    return 1 if(!$top->{in_loop});
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

    my @locals = ();

    my $i;
    for($i = 1; $i<=$#ValClass; $i++) {
        last if($ValClass[$i] eq '=');
        if($ValClass[$i] =~ /[ashG]/) {
            if($i+1 <= $#ValClass && $ValClass[$i+1] eq '(') {
                logme('W',"A 'local' statement with a subscript or hash key is not implemented for $ValPerl[$i]");
                $i = &Pythonizer::matching_br($i+1);
                last if($i < 0);
                next;
            }
            push @locals, $ValPerl[$i];
        }
    }
    return if(!@nesting_stack);       # Local at the outermost file level is treated like "my" so we can skip them
    $top = $nesting_stack[-1];
    my $lno = $top->{lno};
    if($::debug >=5) {
        say STDERR "handle_local for line $. pushed @locals to block on line $lno";
    }
    if(exists $line_locals{$lno}) {
        push @{$line_locals{$lno}}, @locals;
    } else {
        $line_locals{$lno} = \@locals;
    }
    $line_sub{$lno} = (defined $top->{cur_sub} ? $top->{cur_sub} : 'main');
    $line_needs_try_block{$top->{lno}} |= TRY_BLOCK_FINALLY;
}

sub prepare_local
{
    my $quote = shift;
    my $lno = shift;

    my $sigil = substr($quote,0,1);
    my $sub = $line_sub{$lno};

    my $bare = 0;
    if($sigil eq '$') {
        decode_scalar($quote,0);
    } elsif($sigil eq '@') {
        decode_array($quote);
    } elsif($sigil eq '%') {
        decode_hash($quote);
    } elsif($sigil =~ /[A-Za-z_]/) {
        decode_bare($quote);
        $Pythonizer::VarSubMap{$quote}{$sub} = '+';    # We don't detect it because it's normally an 'i' token like FH
        $bare = 1;
    } else {
        return;
    }
    #add_package_name(substr($quote,0,$cut));           # SNOOPYJC: Doesn't work here
    if(!$::implicit_global_my && !$bare) {              # SNOOPYJC: Add the package name manually
        if($ValPy[0] =~ /^\(len\((.*)\)-1\)$/) {
            $ValPy[0] = '(len(' . cur_package() . '.' . $1 . ')-1)';
        } else {
            $ValPy[0] = cur_package() . '.' . $ValPy[0];         # Add the package name
        }
    }
    $line_locals_map{$lno}{$quote} = $ValPy[0];
    if(!exists $Pythonizer::NeedsInitializing{$sub}{$ValPy[0]}) {
        $Pythonizer::NeedsInitializing{$sub}{$ValPy[0]} = 'm';
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
   $tno=0;
   @ValClass=@ValCom=@ValPerl=@ValPy=@ValType=(); # "Token Type", token comment, Perl value, Py analog (if exists)
   $TokenStr='';
   $ExtractingTokensFromDoubleQuotedTokensEnd = -1;     # SNOOPYJC
   $ExtractingTokensFromDoubleQuotedStringEnd = 0;      # SNOOPYJC
   $ate_dollar = -1;                                    # issue 50
   my $end_br;                  # issue 43
   
   if( $::debug > 3 && $main::breakpoint >= $.  ){
      $DB::single = 1;
   }
   while( $source ){
      $had_space = (substr($source,0,1) eq ' ');   # issue 50
      ($source)=split(' ',$source,1);  # truncate white space on the left (Perl treats ' ' like AWK. )
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
         last if( $source=~/^\s*[;{}]\s*(#.*)?$/); # single closing statement symnol on the line.
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
         #say STDERR "Got ; balance=$balance, tno=$tno, nesting_last=$nesting_last";
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
         }elsif( $tno>0 && (length($source)==1 || $source =~ /^}\s*#/ ||
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
              $ValPerl[0] eq 'use' && $ValPerl[1] eq 'constant') {
              ;
          }elsif( length($source)==1 && $ValClass[$tno-1] ne '=' && $ValClass[$tno-1] ne 'f'){      # issue 82, issue 60 (map/grep)
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
                 ($ValPerl[$tno-1] eq ')' || $source=~/^.\s*#/ || index($source,'}',1) == -1 || 
                  ($tno == 1 && $ValClass[0] eq 'C')||  # SNOOPYJC: do {...} until(...); else {...}; elsif {...}; eval {...};
                  ($tno == 2 && $ValPerl[0] eq 'sub') ||
                  ($tno == 1 && ($ValPerl[0] eq 'BEGIN' || $ValPerl[0] eq 'END')))){	# issue 35, 45
             # $tno>0 this is the case when curvy bracket has comments'
             enter_block() if($s eq '{');                 # issue 94
             # SNOOPYJC Pythonizer::getline('{',substr($source,1)); # make it a new line to be proceeed later
             Pythonizer::getline('^',substr($source,1)); # SNOOPYJC: make it a new line to be proceeed later
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
      }elsif( $s eq '/' && ( $tno==0 || $ValClass[$tno-1] =~/[~\(,kc=o0!]/ || $ValPerl[$tno-1] eq 'split' ||
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
            $ValPy[$tno]="'''".escape_backslash($ValPerl[$tno])."'''"; # only \n \t \r, etc needs to be  escaped # issue 39
         }else{
            $ValPy[$tno]="'".escape_backslash($ValPerl[$tno])."'"; # only \n \t \r, etc needs to be  escaped
         }
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
	 }elsif(index($ValPy[$tno], "\n") >= 0 && $ValPy[$tno] !~ /^f"""/) {	# issue 39 - multi-line string
            $ValPy[$tno] =~ s/^f"/f"""/;			# issue 39
	    $ValPy[$tno] .= '""';				# issue 39
         }
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
             push @EndBlocks, $w if(!$Pythonizer::PassNo);         # SNOOPYJC
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
             ($ValClass[$tno-1] eq 'f' && ($ValPerl[$tno-1] eq 'open' || $ValPerl[$tno-1] eq 'opendir')) ||
             ($tno-2>=0 && $ValClass[$tno-1] eq '(' && $ValClass[$tno-2] eq 'f' &&
                ($ValPerl[$tno-2] eq 'open' || $ValPerl[$tno-2] eq 'opendir'))) {       # issue 92
            my $sigil = '';
            $sigil = '&' if($ValPerl[$tno-1] eq 'sub');   # issue 92, 108: Differentiate between sub and FH
            remap_conflicting_names($w, $sigil, '');      # issue 92: sub takes the name from other vars
         }
         $ValPy[$tno]=~tr/:/./s;                # SNOOPYJC
         $ValPy[$tno]=~tr/'/./s;                # SNOOPYJC
         $ValCom[$tno]='';                      # SNOOPYJC
         if( exists($keyword_tr{$w}) ){
            $ValPy[$tno]=$keyword_tr{$w};
         }
         if( exists($CONSTANT_MAP{$w}) ) {      # SNOOPYJC
             $ValPy[$tno] = $CONSTANT_MAP{$w};  # SNOOPYJC
         }                                      # SNOOPYJC
         if( exists($TokenType{$w}) ){
            $class=$TokenType{$w};
            if($tno != 0 && (($ValPerl[$tno-1] eq '{' && $source =~ /^[a-z0-9]+}/) ||   # issue 89: keyword in a hash like $hash{delete} or $hash{q}
                (index('(,', $ValPerl[$tno-1])>=0 && $source =~ /^[a-z0-9]+\s*=>/))) {  # issue 89: keyword in hash def like (qw=>14, use=>15)
                $class = 'i';                   # issue 89
                $ValPy[$tno] = $w;              # issue 89
            } elsif($tno == 2 && $ValClass[0] eq 'G' && $ValClass[1] eq '=' && $class eq 'k' &&
                    $w eq 'sub') {                    # SNOOPYJC: *GLOB = sub {...} - change to sub GLOB {...}
                $TokenStr = join('',@ValClass);                # replace doesn't work w/o $TokenStr
                replace(1, 'i', substr($ValPerl[0],1), $ValPy[0]);       # Change the = to the subname (eat the '*')
                replace(0, $ValClass[$tno], $ValPerl[$tno], $ValPy[$tno]);      # Start with the sub
                popup();                                       # Eat the extra 'sub'
                remap_conflicting_names($ValPerl[1], '&', '');      # issue 92: sub takes the name from other vars
                $class = 'i';
                $tno--;
                $Pythonizer::LocalSub{$ValPerl[$tno]} = 1;
            } elsif($tno != 0 && ($ValClass[$tno-1] eq 'D' || 
                ($ValClass[$tno-1] eq 'k' && $ValPerl[$tno-1] eq 'sub'))) {    # SNOOPYJC: Part of an OO method ref or sub def - change this to an 'i' class
                $class = 'i';
                $ValPy[$tno] = $w;
            }                                   # issue 89
            $ValClass[$tno]=$class;
            if( $class eq 'c' && $tno > 0 && $Pythonizer::PassNo && ($ValClass[0] ne 'C' || $ValPerl[0] ne 'do')){ # Control statement, like if # SNOOPYJC: and do
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
            } elsif($class eq 'c' && !$Pythonizer::PassNo && ($w eq 'if' || $w eq 'unless') &&          # SNOOPYJC
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
               if( $tno>0 && $w eq 'my' && $Pythonizer::PassNo){        # SNOOPYJC: In the first pass, we need to see the 'my' so we don't make $i global!
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
               if( $w eq 'q' ){
                  $cut=single_quoted_literal($delim,2);
                  if( $cut== -1 ){
                     $Pythonizer::TrStatus=-255;
                     last;
                  }
                  # issue 51 $ValPerl[$tno]=substr($source,length($w)+1,$cut-length($w)-2);
                  #say STDERR "after single_quoted_literal, cut=$cut, length(\$w)=".length($w).", length(\$source)=".length($source);
                  $ValPerl[$tno]=remove_escaped_delimiters($delim, substr($source,length($w)+1,$cut-length($w)-2));      # issue 51
                  $w=escape_backslash($ValPerl[$tno]);
                  $ValPy[$tno]=escape_quotes($w,2);
                  $ValClass[$tno]='"';
               }elsif( $w eq 'qq' ){
                  # decompose doublke quote populate $ValPy[$tno] as a side effect
                  $cut=double_quoted_literal($delim,length($w)+1); # side affect populates $ValPy[$tno] and $ValPerl[$tno]
                  $ValClass[$tno]='"';
	 	  if(index($ValPy[$tno], "\n") >= 0 && $ValPy[$tno] !~ /^f"""/) { # issue 39 - multi-line string
            	      $ValPy[$tno] =~ s/^f"/f"""/;		# issue 39
	    	      $ValPy[$tno] .= '""';			# issue 39
		   }						# issue 39
               }elsif( $w eq 'qx' ){
                  #executable, needs interpolation
                  $cut=double_quoted_literal($delim,length($w)+1);
                  $ValPy[$tno]=$ValPy[$tno];
                  $ValClass[$tno]='x';
               }elsif( $w eq 'm' | $w eq 'qr' | $w eq 's' ){
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
                            $ValPy[$tno]='re.sub('.$quoted_regex.','.put_regex_in_quotes($arg2, $delim, $original_regex2).','; #  double quotes neeed to be escaped just in case; issue 111
                        }else{
                            $ValPy[$tno]="re.sub($quoted_regex".','.put_regex_in_quotes($arg2, $delim, $original_regex2).",$DEFAULT_VAR)";	# issue 32, issue 78, issue 111
                        }
                     }else{
                        # this is string replace operation coded in Perl as regex substitution
                        $ValPy[$tno]='str.replace('.$quoted_regex.','.$quoted_regex.',1)';
                     }
                  } elsif( $w eq 'qr' ) {               # SNOOPYJC: qr in other context
                     ($modifier,$groups_are_present)=is_regex($arg1);                           # SNOOPYJC
                     $modifier='' if($modifier eq 'r');                                         # SNOOPYJC
                     $ValPy[$tno]='re.compile('.put_regex_in_quotes($arg1, $delim, $original_regex).$modifier.')';       # SNOOPYJC, issue 111
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
                  # SNOOPYJC if( $tr_modifier eq 'd' ){
                  if( $tr_modifier =~ /d/ ){            # SNOOPYJC
                          $tr_modifier =~ s/d//;        # SNOOPYJC
                          $ValPy[$tno]=".maketrans('','',".put_regex_in_quotes($arg1, $delim, $original_regex1).')'; # deletion via none, issue 111: add $delim
                  # SNOOPYJC }elsif( $tr_modifier eq 's' ){
                  }elsif( $tr_modifier =~ /s/ ){         # SNOOPYJC
                       # sqeeze In Python should be done via Regular expressions
                         $tr_modifier =~ s/s//;        # SNOOPYJC
                         if( $arg2 eq '' || $arg1 eq $arg2  ){
                            $ValPerl[$tno]='re';
                            $ValPy[$tno]='re.sub('.put_regex_in_quotes("([$arg1])(\\1+)", $delim, $original_regex1).",r'\\1'),"; # needs to be translated into  two statements, issue 111: add $delim
                         }else{
                            $ValPerl[$tno]='re';
                            if( $ValClass[$tno-2] eq 's' ){
                                $ValPy[$tno]="$ValPy[$tno-2].translate($ValPy[$tno-2].maketrans(".put_regex_in_quotes($arg1,$delim,$original_regex1).','.put_regex_in_quotes($arg2,$delim,$original_regex2).')); ';       # issue 111: Add $delim
                                $ValPy[$tno].='re.sub('.put_regex_in_quotes("([$arg2])(\\1+)", $delim, $original_regex2).",r'\\1'),"; # needs to be translated into  two statements, issue 111: Add $delim
                            }else{
                                $::TrStatus=-255;
                                $ValPy[$tno].='re.sub('.put_regex_in_quotes("([$arg2])(\\1+)", $delim, $original_regex2).",r'\\1'),";     # issue 111
                                logme('W',"The modifier $tr_modifier for tr function with non empty second arg ($arg2) requires preliminary invocation of translate. Please insert it manually ");
                            }
                         }
                  # SNOOPYJC }elsif( $tr_modifier eq '' ){
                  } else {              # SNOOPYJC
                      #one typical case is usage of array element on the left side $main::tail[$a_end]=~tr/\n/ /;
                      $ValPy[$tno]='.maketrans('.put_regex_in_quotes($arg1, $delim, $original_regex1).','.put_regex_in_quotes($arg2, $delim, $original_regex2).')'; # needs to be translated into  two statements, issue 111
                      $ValPy[$tno] .= ",flags=$tr_modifier" if($tr_modifier);
                      if($tr_modifier =~ /[a-qs-z]/) {  # 'r' is handled
                          logme('W',"The modifier $tr_modifier for tr function currently is not translatable. Manual translation requred ");
                      }
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
                      $ValPy[$tno]='"'.$python.'".split()';	# issue 44: python split doesn't take a regex!
                   }
               }
            } elsif($w eq 'autoflush' && $tno-2 > 0 && $ValClass[$tno-1] eq 'D' &&
                ($ValPerl[$tno-2] eq 'STDOUT' || $ValPerl[$tno-2] eq 'STDERR')) {       # SNOOPYJC
               # Pretend they use $| so we define the autoflush functions for these standard outputs
               $SpecialVarsUsed{'$|'} = 1;                                              # SNOOPYJC
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
         }
         if($ValClass[$tno] eq 'i') {                   # issue 94
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
            decode_scalar($source,1);
	    if($tno!=0 &&                               # issue 50, issue 92
               (($ValClass[$tno-1] eq 's' && $ValPerl[$tno-1] eq '$') || # issue 50
                $ValClass[$tno-1] eq '@' || 
                ($ValClass[$tno-1] eq '%' && !$had_space))) {	# issue 50
               # Change $$xxx to $xxx, @$xxx to $xxx and %$yyy to $yyy but NOT % $yyy as that's a MOD operator!
               $TokenStr = join('',@ValClass);             # issue 50: replace doesn't work w/o $TokenStr
               replace($tno-1, $ValClass[$tno], $ValPerl[$tno], $ValPy[$tno]);  # issue 50
               popup();                         # issue 50
	       $tno--;				# issue 50 - no need to change hashref to hash or arrayref to array in python
               $ate_dollar = $tno;              # issue 50: remember where we did this
               #$ValPerl[$tno]=$ValPy[$tno]=$s;	# issue 50
	    }
            if( $ValPy[$tno] eq 'SIG' ) {              # issue 81 - implement signals
               $ValClass[$tno] = 'f';
               if($::debug >= 3) {
                  say STDERR "decode_scalar SIG source=$source";
               }
               if($tno == 0) {                  # at start of line like $SIG{ALRM} = sub { die "timeout"; };
                   # Special case for __DIE__ - just set a flag
                   if($source =~ /\{\s*__DIE__/) {
                       $ValClass[$tno] = 's';
                       if($source =~ /Carp::confess/) {
                           $ValPy[$tno] = $DIE_TRACEBACK;
                           $source =~ s/\{\s*__DIE__\s*\}\s*=.*$/=1;/;
                       } else {
                           $ValPy[$tno] = $DIE_TRACEBACK;
                           $source =~ s/\{\s*__DIE__\s*\}\s*=.*$/=0;/;
                       }
                   } else {
                       # Change to signal.signal(SIG, RHS);
                       $ValPy[$tno] = 'signal.signal';
                       $source =~ s/=\s*['"]DEFAULT['"]/=_DFL/;
                       $source =~ s/=\s*['"]IGNORE['"]/=_IGN/;
                       $source =~ s/\{\s*([A-Z_]+)\s*\}\s*=\s*(.*);/($1, $2);/;
                       $source =~ s/Carp::confess\(\s*\@_\s*\)/traceback::print_stack(\$f)/;
                   }
                } else {
                   #$ValPy[$tno] = '_getsignal';        # Not sure to use this or that based on what the user's gonna do!
                   $ValPy[$tno] = 'signal.getsignal';   # This choice allows the user to save/restore the value but not compare it to 'DEFAULT' or 'IGNORE'
                   $source =~ tr/{}/()/;
                }
                if($::debug >= 3) {
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
         if( substr($source,1)=~/^(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)/ ){       # SNOOPYJC: Allow ' from old perl
            $arg1=$1;
            if( $arg1 eq '_' ){
               $ValPy[$tno]="$PERL_ARG_ARRAY";	# issue 32
               $ValType[$tno]="X";
               $SpecialVarsUsed{'@_'} = 1;                       # SNOOPYJC
            }elsif( $arg1 eq 'ARGV'  ){
		    # issue 49 $ValPy[$tno]='sys.argv';
                  $ValPy[$tno]='sys.argv[1:]';	# issue 49
                  $ValType[$tno]="X";
                  $SpecialVarsUsed{'@ARGV'} = 1;                       # SNOOPYJC
            }else{
               my $arg2 = remap_conflicting_names($arg1, '@', substr($source,length($arg1)+1,1));      # issue 92
	       $arg2 = escape_keywords($arg2);		# issue 41
               if( $tno>=2 && $ValClass[$tno-2] =~ /[sd'"q]/  && $ValClass[$tno-1] eq '>'  ){
                  $ValPy[$tno]='len('.$arg2.')'; # scalar context   # issue 41
                  $ValType[$tno]="X";
                }else{
                  $ValPy[$tno]=$arg2;            # issue 41
               }
               $ValPy[$tno]=~tr/:/./s;
               $ValPy[$tno]=~tr/'/./s;          # SNOOPYJC
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
               $SpecialVarsUsed{'%ENV'} = 1;                # SNOOPYJC
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
            $Pythonizer::LocalSub{$ValPerl[$tno]} = 1;
         }else{
           $cut=1;
         }
      }elsif( $s eq '*' && ($ch = substr($source,1,1)) ne '*' && $ch ne '='){  # issue 108: typeglob
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
	 }
         $ValClass[$tno]='('; # we treat anything inside curvy backets as expression
         $cut=1;
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
         } elsif($trigram eq '**=' || $trigram eq '>>=' || $trigram eq '<<=') { # SNOOPYJC
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
               # issue 93 if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && join('',@ValClass) !~ /^t?[ahs]=/ ){  # SNOOPYJC
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
            if( $source=~/^<(\w*)>/ || $quadgram eq '<<>>'){    # issue 66
               # SNOOPYJC $ValClass[$tno]='i';
               $ValClass[$tno]='j';             # SNOOPYJC
               if($quadgram eq '<<>>') {        # issue 66
                   $cut = 4;                    # issue 66
                   $safe_mode = 1;              # issue 66
               } else {                         # issue 66
                   $cut=length($1)+2;
                   $ValPerl[$tno]="<$1>";
                   $fh = $1;
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
                       $ValPy[$tno]="next(fileinput.input(), None)";        # issue 66: Allows for $.
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
            if( $s eq '.'  ){
               $ValPy[$tno]=' + ';
	       if( $source=~/(^[.]\d+(?:[_]\d+)*(?:[Ee][+-]?\d+(?:[_]\d+)*)?)/  ){	# issue 23: float constant starting with '.'
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
            }else{
	       $cut=1;						# issue 23
	    }
	    # issue 23 $cut=1;
         }
      }
      if($ValClass[$tno] =~ /[ahsG]/) {         # SNOOPYJC: Handle globals in packages
          if($Pythonizer::PassNo) {
              add_package_name(get_perl_name($ValPerl[$tno], substr($source,$cut,1),
                  ($ate_dollar == $tno  ? '$' : ''))) unless($::implicit_global_my);
          } else {
              capture_varclass();                # SNOOPYJC
          }
      } elsif($ValClass[$tno] eq 'j' && index($ValPerl[$tno], '$') >= 0) {
          if($Pythonizer::PassNo) {
              add_package_name_j() unless ($::implicit_global_my);
          } else {
              capture_varclass_j();
          }
      }
      finish(); # subroutine that prepeares the next cycle
   } # while
   if($tno > 0) {                                       # issue 94
        if($ValClass[0] eq 'k' && ($ValPerl[0] eq 'last' || $ValPerl[0] eq 'next')) {    # issue 94
            handle_last_next(0);                              # issue 94
        } elsif($ValClass[0] eq 't' && $ValPerl[0] eq 'local' && !$Pythonizer::PassNo) {        # issue 108
            handle_local();                                     # issue 108
        }
        for(my $i=1; $i <= $#ValClass; $i++) {
            if($ValClass[$i] eq 'k') {
                if($ValPerl[$i] eq 'last' || $ValPerl[$i] eq 'next') {
                    handle_last_next($i);
                } elsif($ValPerl[$i] eq 'return') {
                    handle_return_in_expression($i);
                }
            }
        }

   }

   $TokenStr=join('',@ValClass);
   if( $::debug>=2 && $Pythonizer::PassNo ){
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
   if( length($source)==0  ){
       # the current line ended but ; or ){ } were not reached
       $original=$Pythonizer::IntactLine;
       my @tmpBuffer = @BufferValClass;	# Issue 7
       @BufferValClass = ();		# Issue 7
       $source=Pythonizer::getline();
       @BufferValClass = @tmpBuffer;	# Issue 7
       if( length($Pythonizer::IntactLine)>0 ){
          $original.="\n".$Pythonizer::IntactLine;
          $Pythonizer::IntactLine=$original;
       }else{
         $Pythonizer::IntactLine=$original;
       }
   }
   if($ExtractingTokensFromDoubleQuotedStringEnd > 0 && $ValClass[$tno] eq '"') {               # SNOOPYJC
       # Correct the ValPerl because we unfortunately get it wrong, exp if $cut-2 is negative!
       $ValPerl[$tno] = substr($ValPy[$tno], 4, length($ValPy[$tno])-7);
   }
   if( $::debug > 3  ){
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
    return $rl;
}

sub bash_style_or_and_fix
# On level zero those are used instead of if statement
{
my $split=$_[0];
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
   # issue 93: if this is an assignment, only transform it if it contains a control statement afterwards or if it's a low precedence op
   my $tstr = join('',@ValClass);
   if(($tstr =~ /^t?[ahs](?:\(.*\))*=/ || ($tstr =~ /^kiiA/ && $ValPerl[0] eq 'use' && $ValPerl[1] eq 'constant')) && 
      !$is_low_prec &&
      substr($source,$split) !~ /^\s*(?:return|next|last|assert|delete|require|die)\b/) {       # issue 93
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
{
my $source=$_[0];
my $update=$_[1]; # if update is zero then only ValPy is updated
my $rc=-1;
   $s2=substr($source,1,1);
   if ( $update  ){
      $ValClass[$tno]='s'; # we do not need to set it if we are analysing double wuoted literal
   }
   my $specials = q(!?<>()!;]&`'+-"@$|/,\\%=~^:);             # issue 50, SNOOPYJC
   if(($s2 eq '$' || $s2 eq '%') && substr($source,2,1) =~ /[\w:']/) {   # issue 50: $$ is a special var, but not $$a or $$: or $$'
       $specials = '!';
   }
   if( $s2 eq '.'  ){
      # file line number
      # issue 66 $ValPy[$tno]='fileinput.filelineno()';
      # issue 66 $ValPy[$tno]='fileinput.lineno()';       # issue 66: Mimic the perl behavior
       $::Pyf{_nr} = 1;              # issue 66
       $ValPy[$tno]='_nr()';         # issue 66: Mimic the perl behavior, no matter if we're using fileinput or not
       $SpecialVarR2L{$ValPy[$tno]} = 'INPUT_LINE_NUMBER';      # Name if used on LHS
       $ValType[$tno]="X";
       my $vn = substr($source,0,2);                    # SNOOPYJC
       $SpecialVarsUsed{$vn} = 1;                       # SNOOPYJC
       $ValPerl[$tno]=$vn if($update);                  # SNOOPYJC
       $cut=2
   }elsif( $s2 eq '^'  && substr($source,2,1) =~ /[A-Z]/ ){     # SNOOPYJC
       $s3=substr($source,2,1);
       $cut=3;
       $ValType[$tno]="X";
       my $vn = substr($source,0,3);                    # SNOOPYJC
       $SpecialVarsUsed{$vn} = 1;                       # SNOOPYJC
       $ValPerl[$tno]=$vn if($update);                  # SNOOPYJC
       if( $s3=~/\w/  ){
          if( exists($SPECIAL_VAR2{$s3}) ){
            $ValPy[$tno]=$SPECIAL_VAR2{$s3};
          }else{
            $ValPy[$tno]='unknown_perl_special_var'.$s3;
         }
       }
   # issue 46 }elsif( index(q(!?<>()!;]&`'+"),$s2) > -1  ){
   }elsif( index($specials,$s2) > -1 && substr($source,1,2) ne '::' ){	# issue 46, issue 50, SNOOPYJC ($:: is not $:)
      $ValPy[$tno]=$SPECIAL_VAR{$s2};
      $cut=2;
      $ValType[$tno]="X";
      my $vn = substr($source,0,2);                    # SNOOPYJC
      $SpecialVarsUsed{$vn} = 1;                       # SNOOPYJC
      $ValPerl[$tno]=$vn if($update);                  # SNOOPYJC
   }elsif( $s2 =~ /\d/ ){
       $source=~/^.(\d+)/;
       my $vn=substr($source,0,1).$1;                   # SNOOPYJC
       $SpecialVarsUsed{$vn} = 1;                       # SNOOPYJC
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
      $source=~/^..\{(\w+)\}/ or $source=~/^..\$?(\w+)/ or $source=~/^..\{\$(\w+)\}/;  # Handle $#{var} $#var $#$var $#{$var}
      #say STDERR "decode_scalar: source='$source', \$1=$1";
      $ValType[$tno]="X";
      if( $update ){
         $ValPerl[$tno]=substr($source,0,2).$1; # SNOOPYJC
      }
      if( $1 eq 'ARGV'  ){                      # SNOOPYJC: Generate proper code for $#ARGV
          $ValPy[$tno] ='(len(sys.argv)-2)';    # SNOOPYJC
      } elsif($1 eq '_') {                      # issue 107
          $ValPy[$tno] ="(len($PERL_ARG_ARRAY)-1)";    # issue 107
      } else {                                  # SNOOPYJC
          $ValPy[$tno]='(len('.$1.')-1)';       # SNOOPYJC
      }
      # SNOOPYJC $cut=length($1)+2;
      $cut=length($&);                          # SNOOPYJC
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
               ($ValClass[$tno-1] eq 's' && $ValPerl[$tno-1] eq '$'))) {
          ;             # Do nothing if this is like $$h_ref{key}
      } else {
          $next_c = substr($source,$cut,1);
      }
      if( ($k=index($name,'::')) > -1 ){
          # SNOOPYJC $ValType[$tno]="X";
         if( $k==0 || substr($name,$k) eq 'main' ){
            substr($name,0,2)="$MAIN_MODULE.";
            $name=~tr/:/./s;            # SNOOPYJC
            $name=~tr/'/./s;            # SNOOPYJC
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
            if( $source=~/^(._\s*\[\s*(\d+)\s*\])/  ){
               $ValPy[$tno]="$PERL_ARG_ARRAY".'['.$2.']';	# issue 32
               $cut=length($1);
               $SpecialVarsUsed{'@_'} = 1;                      # SNOOPYJC
            }elsif(substr($source,2,1) eq '[') {                # issue 107: Vararg
               $ValPy[$tno]=$PERL_ARG_ARRAY;                    # issue 107
               $cut=2;                                          # issue 107
               $SpecialVarsUsed{'@_'} = 1;                      # issue 107
            }else{
               $ValPy[$tno]="$DEFAULT_VAR";			# issue 32
               $cut=2;
               $SpecialVarsUsed{'$_'} = 1;                      # SNOOPYJC
            }
         }elsif( $s2 eq 'a' || $s2 eq 'b' ){
            $ValType[$tno]="X";
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
           if( $1 eq 'ENV'  ){
              $ValType[$tno]="X";
              $ValPy[$tno]='os.environ';
              $SpecialVarsUsed{'%ENV'} = 1;                       # SNOOPYJC
           }elsif( $1 eq 'ARGV'  ){
              $ValType[$tno]="X";
              if($cut < length($source) && substr($source,$cut,1) eq '[') {    # $ARGV[...] is a reference to @ARGV
                  $SpecialVarsUsed{'@ARGV'} = 1;                       # SNOOPYJC
	          $ValPy[$tno]='sys.argv[1:]';
              } else {
                  $SpecialVarsUsed{'$ARGV'} = 1;                       # SNOOPYJC
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
         $modifier.='|re.'.uc($temp[$i]);	# issue 11
     }#for
     if( $modifier ne '' ) { $modifier =~ s/^\|/,/; } # issue 11
     $regex=1;
     $cut=0;
   }
   @temp=split(//,$myregex);
   $prev_sym='';
   $meta_no=0;
   for( $i=0; $i<@temp; $i++ ){
      $sym=$temp[$i];
      if( $prev_sym ne '\\' && $sym eq '(' ){
         return($modifier,1);
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
   if($::debug > 3) {
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
           return 're.search('.$quoted_regex.','; #  we do not need the result of match as no groups is present. # issue 75
         }
      # issue 93 }elsif( $ValClass[$tno-1] eq '0'  ||  $ValClass[$tno-1] eq '(' ){
      }elsif( $ValClass[$tno-1] =~ /[0o]/  ||  $ValClass[$tno-1] eq '(' ){      # issue 93
            # this is calse like || /text/ or while(/#/)
            if( $groups_are_present ){
                return "($DEFAULT_MATCH:=re.search(".$quoted_regex.",$DEFAULT_VAR))"; #  we need to have the result of match to extract groups. # issue 32
         }else{
           return 're.search('.$quoted_regex.",$DEFAULT_VAR)"; #  we do not need the result of match as no groups is present.	# issue 32, 75
         }
      }else{
         return 're.search('.$quoted_regex.",$DEFAULT_VAR)"; #  we do not need the result of match as no groups is present.	# issue 32, 75
      }
   }else{
      # this is a string
      $ValClass[$tno]="'";
      return '.find('.escape_quotes($myregex).')';
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
      $ValPy[$tno]=escape_quotes($quote,2);
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

   if($::debug >= 3) {
       say STDERR ">interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)";
   }
   my ($k, $ind, $result, $pc, $prev);
   local $cut;                  # Save the global version of this!
   $prev = '';
   $quote = interpolate_string_hex_escapes($quote);                     # SNOOPYJC: Replace \x{ddd...} with python equiv
   #
   # decompose all scalar variables, if any, Array and hashes are left "as is"
   #
   $k=index($quote,'$');
   if( $k==-1 && index($quote, '@') == -1){             # issue 47
      # case when double quotes are used for a simple literal that does not reaure interpolation
      # Python equvalence between single and doble quotes alows some flexibility
      $ValPy[$tno]=escape_quotes($quote,2); # always generate with quotes --same for Python 2 and 3
      say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)=$close_pos, ValPy[$tno]=$ValPy[$tno]" if($::debug >=3);
      return $close_pos;
   }
   # SNOOPYJC: In the first pass, extract all variable references and return them as separate tokens
   # so we can mark their references, and add things like initialization.
   # If we're handling a here_is document, or a regex, we don't do this (but we probably should: $close_pos == 0)
   if($Pythonizer::PassNo == 0 && $close_pos != 0) {                       # SNOOPYJC
       my $pos = extract_tokens_from_double_quoted_string($pre_escaped_quote,1)+$offset;
       if($ExtractingTokensFromDoubleQuotedStringEnd > 0) {
          $ExtractingTokensFromDoubleQuotedStringEnd += $offset;
          say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)=$pos (begin extract mode)" if($::debug >=3);
          return $pos;
       }
   }

   #
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
            $result.=substr($quote,0,$k); # with or without quotes depending on version.
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
         $quote = $sig . substr($quote,2);	# issue 43: eat the '{'. At this point, $end_br points after the '}', issue 47
         #say STDERR "quote1a=$quote, end_br=$end_br\n";
      }
      if($sig eq '$') {                 # issue 47
         decode_scalar($quote,0); #get's us scalar or system var
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
         }
         #does not matter what type of variable this is: regular or special variable
         #my $next_c = substr($quote,$cut,1);
         #if($next_c eq '[') {
         #substr($ValPerl[$tno],0,1) = '@';
         #} elsif($next_c eq '{') {
         #substr($ValPerl[$tno],0,1) = '%';
         #}
         add_package_name(get_perl_name(substr($quote,0,$cut), substr($quote,$cut,1), $prev));        # SNOOPYJC
         $prev = '';
         $result.=$ValPy[$tno]; # copy string provided by decode_scalar. ValPy[$tno] changes if Perl contained :: like in $::debug
      } else {                          # issue 47: '@'
          #say STDERR "end_br=$end_br, quote=$quote";
         if($end_br > 0 && substr($quote,0,3) eq '@[%') {  # @{[%hash]}
            $quote = substr($quote, 2);
            decode_hash($quote);
            add_package_name(substr($quote,0,$cut));            # SNOOPYJC
            $ValPy[$tno] = 'functools.reduce(lambda x,y:x+y,'.$ValPy[$tno].'.items())';
            $end_br -= 2;    # 2 to account for the 2 we ate
            #say STDERR "quote1b=$quote, end_br=$end_br\n";
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
                $result .= '@' if($k != 0);             # SNOOPYJC: If we have @$, then just eat the '@'
                next;
            }
            add_package_name(substr($quote,0,$cut));            # SNOOPYJC
         }
         #does not matter what type of variable this is: regular or special variable
         $result.="LIST_SEPARATOR.join($ValPy[$tno])"; # copy string provided by decode_array. ValPy[$tno] changes if Perl contained :: like in $::debug
      }

      $quote=substr($quote,$cut); # cure the nesserary number of symbol determined by decode_scalar.
      $end_br -= $cut;			# issue 43
      if($sig eq '$') {                 # issue 47
          #say STDERR "quote2=$quote, result1=$result, end_br=$end_br";
          my $p_len = length($quote);                       # issue 13, 43
          $quote =~ s/(?<![{\$])(?:->)?\{([A-Za-z_][A-Za-z0-9_]*)\}/\{\'$1\'\}/g;     # issue 13: Remove bare words in $hash{...}
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
          }
          my $quote2 = $quote;
          if($ind = extract_bracketed($quote2, '{}[]', '')) {        # issue 53, issue 98
             # issue 109 $cut=length($ind);
             my $ind_cut=length($ind);
             # issue 109 $ind =~ tr/$//d;               # We need to decode_scalar on each one!
             # issue 53 $ind =~ tr/{}/[]/;
             #say "looking for '{' in $ind";
             for(my $i = 0; $i < length($ind); $i++) {	# issue 53: change hash ref {...} to use .get(...) instead
                 my $c = substr($ind,$i,1);                 # issue 109
                 if($c eq '{') {		# issue 53
                     $l = matching_curly_br($ind, $i);	# issue 53
                     #say "found '{' in $ind at $i, l=$l";
                     next if($l < 0);			# issue 53
                     $ind = substr($ind,0,$i).'.get('.substr($ind,$i+1,$l-($i+1)).",'')".substr($ind,$l+1);	# issue 53: splice in the call to get
                     #say "ind=$ind";
                     # issue 109 $i = $l+7;				# issue 53: 7 is length('.get') + length(",''")
                 } elsif($c eq '$') {                       # issue 109: decode special vars in subscripts/hash keys
                     my $var = substr($ind,$i);
                     my $pr = '';
                     decode_scalar($var,0);     # issue 109
                     if($cut == 1) {     # Just a '$' with no variable
                        $pr = '$';
                        $var = substr($ind,$i+1);
                        substr($ind,$i,1) = '';
                        decode_scalar($var,0);          # Try again
                     }
                     add_package_name(get_perl_name(substr($var,0,$cut), substr($var,$cut,1), $pr));     # SNOOPYJC
                     substr($ind,$i,$cut) = $ValPy[$tno];   # issue 109
                     $i += (length($ValPy[$tno])-$cut);     # issue 109
                 }
             }						# issue 53
             $result.=$ind; # add string Variable part of the string
             # issue 109 $quote=substr($quote,$cut);
             $quote=substr($quote,$ind_cut);        # issue 109
             $end_br -= $ind_cut;			# issue 43
             #say STDERR "quote4=$quote, end_br=$end_br";
          }
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
       $result.=$quote;
   }
   if($outer_delim eq '"""' && substr($result,-1,1) eq '"' &&
      (substr($result,-2,1) ne '\\' || substr($result,-3,1) eq '\\')) {    # SNOOPYJC: oops - we have to fix this!
       $result = substr($result,0,length($result)-1)."\\".'"';
   }
   $result.=$outer_delim;
   #say STDERR "double_quoted_literal: result=$result";
   $ValPy[$tno]=$result;
   say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex)=$close_pos, ValPy[$tno]=$ValPy[$tno]" if($::debug >=3);
   return $close_pos;
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

    say STDERR ">extract_tokens_from_double_quoted_string($quote)" if($::debug>=3);
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
            if( $::debug > 3  ){
                say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
            }
            $tno++;
            say STDERR "<extract_tokens_from_double_quoted_string($quote) result=$pos" if($::debug>=3);
            return $pos;
        }
        my $sigil = substr($quote,$pos,1);
        my $end_br = -1;
        if(substr($quote,$pos+1,1) eq '{') {		# issue 43: ${...}
            $end_br = matching_curly_br($quote, $pos+1); # issue 43
            $quote = '$'.substr($quote,2);		# issue 43: eat the '{'. At this point, $end_br points after the '}'
        }
        if($sigil eq '$') {
            decode_scalar($quote, 1);
        } else {
            decode_array($quote);
            $ValClass[$tno] = 'a';
        }
        $ValPerl[$tno] = substr($quote, 0, $cut);
        my $m;
        if($cut < length($quote)) {
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
        $ExtractingTokensFromDoubleQuotedStringEnd = length($quote);
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
        $ValPerl[$tno] = $quote;
        $ValPy[$tno] = 'f"""' . $ValPerl[$tno] . '"""';
        $ExtractingTokensFromDoubleQuotedTokensEnd = -1;
        $ExtractingTokensFromDoubleQuotedStringEnd = 0;
        if( $::debug > 3  ){
           say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
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
            if($k+1 < length($str)) {
                my $nx3 = substr($str,$k+1,3);
                if($nx3 eq '->[' || $nx3 eq '->{') {   # Move past any '->' that ends in a '[' or '{'
                    $k += 2;
                }
                my $d = substr($str,$k+1,1);
                my $m = -1;
                $m = matching_curly_br($str,$k+1) if ($d eq '{');
                $m = matching_square_br($str,$k+1) if ($d eq '[');
                $k = $m if($m >= 0);
                if($k+1 < length($str)) {
                    my $d = substr($str,$k+1,1);
                    $m = -1;
                    $m = matching_curly_br($str,$k+1) if ($d eq '{');
                    $m = matching_square_br($str,$k+1) if ($d eq '[');
                    $k = $m if($m >= 0);
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
        if( $arg1 eq '_' ){
           $ValPy[$tno]="$PERL_ARG_ARRAY";	# issue 32
           #$ValType[$tno]="X";
        }elsif( $arg1 eq 'ARGV'  ){
                # issue 49 $ValPy[$tno]='sys.argv';
              $ValPy[$tno]='sys.argv[1:]';	# issue 49
              $SpecialVarsUsed{'@ARGV'} = 1;                       # SNOOPYJC
              #$ValType[$tno]="X";
        }else{
           my $arg2 = remap_conflicting_names($arg1, '@', '');     # issue 92
           $arg2 = escape_keywords($arg2);		# issue 41
           #if( $tno>=2 && $ValClass[$tno-2] =~ /[sd'"q]/  && $ValClass[$tno-1] eq '>'  ){
              #$ValPy[$tno]='len('.$arg1.')'; # scalar context
              #$ValType[$tno]="X";
              #}else{
              $ValPy[$tno]=$arg2;
              #}
           $ValPy[$tno]=~tr/:/./s;
           $ValPy[$tno]=~tr/'/./s;
           if( substr($ValPy[$tno],0,1) eq '.' ){
              $ValPy[$tno]="$MAIN_MODULE.$ValPy[$tno]";
              #$ValType[$tno]="X";
           }
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
        $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '%', '');     # issue 92
        $ValPy[$tno] = escape_keywords($ValPy[$tno]);
        if( substr($ValPy[$tno],0,1) eq '.' ){
            #$ValCom[$tno]='X';
           $ValPy[$tno]="$MAIN_MODULE.$ValPy[$tno]";
        } elsif($ValPy[$tno] eq 'ENV') {                # issue 103
           $ValType[$tno]="X";
           $ValPy[$tno]='os.environ';
           $SpecialVarsUsed{'%ENV'} = 1;                       # SNOOPYJC
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
{
    my $str = shift;

    $str =~ s/\\x\{([A-Fa-f0-9])\}/\\x0$1/g;
    $str =~ s/\\x\{([A-Fa-f0-9]{2})\}/\\x$1/g;
    $str =~ s/\\x\{([A-Fa-f0-9]{3})\}/\\u0$1/g;
    $str =~ s/\\x\{([A-Fa-f0-9]{4})\}/\\u$1/g;
    $str =~ s/\\x\{([A-Fa-f0-9]{5})\}/\\U000$1/g;
    $str =~ s/\\x\{([A-Fa-f0-9]{6})\}/\\U00$1/g;
    $str =~ s/\\x\{([A-Fa-f0-9]{7})\}/\\U0$1/g;
    $str =~ s/\\x\{([A-Fa-f0-9]{8})\}/\\U$1/g;

    return $str;
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
          return qq(""").substr($string,0,length($string)-1).qq(\"""");
      }
      return qq(""").$string.qq(""") 
   }
   return qq(').$string.qq(') if(index($string,"'")==-1 ); # no need to escape any quotes.
   return q(").$string.qq(") if( index($string,'"')==-1 ); # no need to scape any quotes.
#
# We need to escape quotes
#
   if(substr($string,-1,1) eq '"') {    # SNOOPYJC: oops - we have to fix this!
       return qq(""").substr($string,0,length($string)-1).qq(\"""");
   }
   return qq(""").$string.qq(""");
}
sub put_regex_in_quotes
{
my $string=$_[0];
my $delim=$_[1];        # issue 111
my $original_regex=$_[2]; # issue 111
   if($::debug > 4) {
       say STDERR "put_regex_in_quotes($string, $delim, $original_regex)";
   }
   if($delim ne "'") {  # issue 111
       $string =~ s/\$\&/\\g<0>/g;	# issue 11
       $string =~ s/\$(\d)/\\g<$1>/g; # issue 11
       # SNOOPYJC if( $string =~/\$\w+/ ){
       # issue 111 if( $string =~/^\$\w+/ ){    # SNOOPYJC: We have to interpolate all $vars inside!! e.g. /DC_$year$month/ gen rf"..."
       # issue 111 return substr($string,1); # this case of /$regex/ we return the variable.
       # issue 111 }
       $string = $ValPy[$tno] = perl_regex_to_python($string);          # issue 111
       interpolate_strings($string, $original_regex, 0, 0, 1);          # issue 111
       return 'r'.$ValPy[$tno];                                         # issue 111
   }
   # SNOOPYJC return 'r'.escape_quotes($string);
   return 'r'.escape_quotes(perl_regex_to_python($string));   # SNOOPYJC
}

sub perl_regex_to_python
# Convert a perl regex to a python regex
{
    #$DB::single = 1;
    my $regex = shift;

    $regex =~ s'\\Z'$'g;
    $regex =~ s'\\z'\\Z'g;

    return $regex;
}

sub escape_backslash
# All special symbols different from the delimiter and \ should be escaped when translating Perl single quoted literal to Python
# For example \n \t \r  are not treated as special symbols in single quotes in Perl (which is probably a mistake)
{
my $string=$_[0];
my $backslash='\\';
my $result=$string;
# issue 51 for( my $i=length($string)-1; $i>=0; $i--  ){
   for( my $i=length($string)-2; $i>=0; $i--  ){                # issue 51
      if( substr($string,$i,1) eq $backslash ){
         if(index('nrtfbvae',substr($string,$i+1,1))>-1 ){
            substr($result,$i,0)='\\'; # this is a really crazy nuance
         }
      }
   } # for
   return $result;
}

sub remove_oddities
# Remove some oddities from the generated code to make it easier to read/understand
{
    my $line = shift;

    # Change "not X is not None" to "X is None"
    $line =~ s/\bnot ([\w.]+(?:\[[\w\']+\])*) is not None\b/$1 is None/g;

    #  if not (childPid is not None):
    $line =~ s/\bnot \(([\w.]+(?:\[[\w\']+\])*) is not None\)/$1 is None/g;

    # FIXME: Change "_list_of_n((7, 7, 7), 3" to "(7, 7, 7)"
    # if($line =~ /\b_list_of_n\(\(.*\), (\d+)\)/) {

    return $line;
}

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

      $line=$PythonCode[0];
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
      push(@PythonCode,$_[$i]);
   } #for
   ($::debug>4) && say 'Generated partial line ',join('',@PythonCode);
}

sub save_code           # issue 74: save the generated python code so we can insert some new code before it
{
    @SavePythonCode = @PythonCode;      # copy the code
    @PythonCode = ();
}
sub restore_code        # issue 74
{
    @PythonCode = @SavePythonCode;
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
   	splice(@ValType,$pos,0,'');
   } else {
       $ValType[$pos] = '';
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
       logme('E',"Attempt to delete element  $from in set containing $#ValClass elements. Request ignored");
       return;
   }elsif($from+$howmany>scalar(@ValClass)){
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
  return $#str;
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
  return $#str;
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
  return $#str;
} # matching_square_br

sub escape_keywords		# issue 41
# Accepts a name and escapes any python keywords in it by appending underscores.  The name can
# be a period separated list of names.  Returns the escaped name.
# Note: We also escape the names of the built-in functions like len, etc
{
	my $name = shift;
	my @ids = split /[.]/, $name;
	my @result = ();
	for my $id (@ids) {
	   if(exists $PYTHON_RESERVED_SET{$id}) {
	       $id = $id.'_';
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

sub mapped_name                         # issue 92
{
    my $name = shift;
    my $sigil = shift;                  # @, %, $, & or '' for FH
    my $trailer = shift;                # [ or { or ''

    $sigil = actual_sigil($sigil, $trailer);
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

    return $name if(!$name);
    return $name if(substr($name,-1,1) eq ')');         # e.g. "globals()"
    return $name if($name =~ /\.__dict__$/);            # package version of globals()
    return $name if(substr($name,0,3) eq 'os.');
    return $name if(substr($name,0,4) eq 'sys.');
    return $name if(substr($name,0,5) eq 'math.');
    my @ids = split/[.]/, $name;
    my $id = $ids[-1];
    my $s = $sigil;
    $sigil = actual_sigil($sigil, $trailer);
    my $mid = mapped_name($id, $sigil, $trailer);
    if(exists $NameMap{$id} && exists $NameMap{$id}{$sigil} && $NameMap{$id}{$sigil} ne $id) {
        return $NameMap{$id}{$sigil};
    }
    if($sigil ne '' && $sigil ne '&') {
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
        $NameMap{$id}{$sigil} = $ids[-1];
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
                if(exists $Pythonizer::VarSubMap{$id}) {
                    $Pythonizer::VarSubMap{$mn} = $Pythonizer::VarSubMap{$id};
                    delete $Pythonizer::VarSubMap{$id};
                }
                if(exists $Pythonizer::VarType{$id}) {
                    $Pythonizer::VarType{$mn} = $Pythonizer::VarType{$id};
                    delete $Pythonizer::VarType{$id};
                }
                for $sub (keys %Pythonizer::NeedsInitializing) {
                    my $subh = $Pythonizer::NeedsInitializing{$sub};
                    if(exists $subh->{$id}) {
                        $subh->{$mn} = $subh->{$id};
                        delete $Pythonizer::NeedsInitializing{$sub}{$id};
                    }
                }
                for $sub (keys %Pythonizer::initialized) {
                    my $subh = $Pythonizer::initialized{$sub};
                    if(exists $subh->{$id}) {
                        $subh->{$mn} = $subh->{$id};
                        delete $Pythonizer::initialized{$sub}{$id};
                    }
                }
            }
        }
    }
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
1;

