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
use config;				# issue 32
require Exporter;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXPORT = qw(gen_statement tokenize gen_chunk append replace destroy insert destroy autoincrement_fix @ValClass  @ValPerl  @ValPy @ValCom @ValType $TokenStr escape_keywords %SPECIAL_FUNCTION_MAPPINGS save_code restore_code %token_precedence);	# issue 41, issue 65, issue 74, issue 93
#our (@ValClass,  @ValPerl,  @ValPy, $TokenStr); # those are from main::

  $VERSION = '0.93';
  #
  # types of veriables detected during the first pass; to be implemented later
  #
  #%is_numeric=();
#
# List of Perl special variables
#

   %SPECIAL_VAR=(';'=>'PERL_SUBSCRIPT_SEPARATOR','>'=>'os.geteuid()','<'=>'os.getuid()','('=>'os.getgid()',')'=>'os.getegid()',
                '?'=>"$SUBPROCESS_RC",
		#SNOOPYJC '!'=>'unix_diag_message',
		'!'=>'OS_ERROR',		# SNOOPYJC
                # SNOOPYJC '$'=>'process_number',
		'$'=>'os.getpid()',             # SNOOPYJC
                ';'=>'subscript_separator,',
                ']'=>'perl_version',
		#SNOOPYJC '&'=>'last_successful_match',
		'&'=>"$DEFAULT_MATCH.group(0)",	# SNOOPYJC, issue 32
                '@'=>'EVAL_ERROR',              # SNOOPYC
		'"'=>'LIST_SEPARATOR',		# issue 46
                '|'=>'OUTPUT_AUTOFLUSH',        # SNOOPYJC
		'`'=>'string_preceeeding_last_match',"'"=>'post_last_match_string',
                '+'=>'last_capture_group','/'=>'lines_separator',','=>'output_field_separator','\\'=>'unknown_perl_special_var',
                );
   %SPECIAL_VAR2=('O'=>'os.name','T'=>'OS_BASETIME', 'V'=>'sys.version[0]', 'X'=>'sys.executable()', # $^O and friends
                  'W'=>'WARNING');              # SNOOPYJC

   # Map of functions to python where the mapping is different for scalar and list context
   %SPECIAL_FUNCTION_MAPPINGS=('localtime'=>{scalar=>'tm_py.ctime', list=>'tm_py.localtime'},
                'reverse'=>{list=>'[::-1]', scalar=>'_reverse_scalar'}  # issue 65
                );


   %keyword_tr=('eq'=>'==','ne'=>'!=','lt'=>'<','gt'=>'>','le'=>'<=','ge'=>'>=',
                'and'=>'and','or'=>'or','not'=>'not',
                'x'=>' * ',
                'abs'=>'abs',                           # SNOOPYJC
                'alarm'=>'signal.alarm',                # issue 81
		'assert'=>'assert',			# SNOOPYJC
		'atan2'=>'math.atan2',			# SNOOPYJC
		'basename'=>'os.path.basename',		# SNOOPYJC
                'binmode'=>'_dup',                      # SNOOPYJC
                'bless'=>'NoTrans!','BEGIN'=>'if True:',        # SNOOPYJC
                # SNOOPYJC 'caller'=>q(['implementable_via_inspect',__file__,sys._getframe().f_lineno]),
		# issue 54 'chdir'=>'.os.chdir','chmod'=>'.os.chmod',
		'chdir'=>'os.chdir','chmod'=>'os.chmod',	# issue 54
		'chomp'=>'.rstrip("\n")','chop'=>'[0:-1]','chr'=>'chr',
		# issue close 'close'=>'.f.close',
		'close'=>'.close()',	# issue close
                'cmp'=>'_cmp',                          # SNOOPYJC
                # issue 42 'die'=>'sys.exit', 
                'die'=>'raise Die',     # issue 42
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
                'grep'=>'filter', 'goto'=>'NoTrans!', 'getcwd'=>'os.getcwd',
                'join'=>'.join(',
		# issue 33 'keys'=>'.keys',
                'keys'=>'.keys()',	# issue 33
                'last'=>'break', 'local'=>'', 'lc'=>'.lower()', 'length'=>'len', 
		# issue localtime 'localtime'=>'.localtime',
		'localtime'=>'tm_py.localtime',		# issue localtime
                'map'=>'map', 'mkdir'=>'os.mkdir', 'my'=>'',
                'next'=>'continue', 'no'=>'NoTrans!',
                'own'=>'global', 'oct'=>'oct', 'ord'=>'ord',
                'our'=>'',                      # SNOOPYJC
                'package'=>'NoTrans!', 'pop'=>'.pop()', 'push'=>'.extend(',
                'printf'=>'print',
                'rename'=>'os.replace',         # SNOOPYJC
                'say'=>'print','scalar'=>'len', 'shift'=>'.pop(0)', 'split'=>'re.split', 
		# issue 34 'sort'=>'sort', 
                'sleep'=>'time.sleep',          # SNOOPYJC
		'sqrt'=>'math.sqrt',		# SNOOPYJC
		'sort'=>'sorted', 		# issue 34
		'state'=>'global',
                'read'=>'.read',                # issue 10
                   'stat'=>'os.stat','sysread'=>'.read',
                   'substr'=>'','sub'=>'def','STDERR'=>'sys.stderr','SYSIN'=>'sys.stdin','system'=>'os.system','sprintf'=>'',
		   'STDOUT'=>'sys.stdout',	# issue 10
                   'sysseek'=>'perl_sysseek',
                   'STDERR'=>'sys.stderr','STDIN'=>'sys.stdin', '__LINE__' =>'sys._getframe().f_lineno',
                'reverse'=>'[::-1]',            # issue 65
                'rindex'=>'.rfind', 
                # SNOOPYJC 'ref'=>'type', 
                'ref'=>'_ref',                  # SNOOPYJC
                'require'=>'NoTrans!', 'return'=>'return', 'rmdir'=>'os.rmdir',
                'tie'=>'NoTrans!',
		'time'=>'_time',		# SNOOPYJC
                'timegm'=>'calendar.timegm',    # SNOOPYJC
                'uc'=>'.upper()', 'ucfirst'=>'.capitalize()', 'undef'=>'None', 'unless'=>'if not ', 'unlink'=>'os.unlink',
                'umask'=>'os.umask',            # SNOOPYJC
                   'unshift'=>'.insert(0,',
		   'use'=>'NoTrans!', 'until'=>'while not ','untie'=>'NoTrans!',
                'values'=>'.values()',	# SNOOPYJC
                 'warn'=>'print',
                 'wait'=>'_wait',       # SNOOPYJC
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
       # j
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
                        a=>25, s=>25, h=>25, i=>25, '('=>25, ')'=>25, '"'=>25, q=>25, x=>25,
			# 24      left        D           ->
                        D=>24,
			# 23      nonassoc    ^           ++ --
                        '^'=>23,
			# 22      right       *           **
                        '*'=>22,
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
                        f=>16,
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
		  'basename'=>'f',	# SNOOPYJC
		  'binmode'=>'f',	# SNOOPYJC
                  'caller'=>'f','chdir'=>'f','chomp'=>'f', 'chop'=>'f', 'chmod'=>'f','chr'=>'f','close'=>'f',
                  'cmp'=>'>',           # SNOOPYJC: comparison
                  'delete'=>'f',        # issue delete
                  'default'=>'C','defined'=>'f','die'=>'f',
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
                  'given'=>'c','grep'=>'f',
                  'join'=>'f',
                  'keys'=>'f',
                  'last'=>'k', 'lc'=>'f', 'length'=>'f', 'local'=>'t', 'localtime'=>'f',
                  'my'=>'t', 'map'=>'f', 'mkdir'=>'f',
                  'next'=>'k','not'=>'!',
                  'our'=>'t',                   # SNOOPYJC
                  # issue 93 'or'=>'0', 
                  'or'=>'o',                    # issue 93
                  'own'=>'t', 'oct'=>'f', 'ord'=>'f', 'open'=>'f',
		  'opendir'=>'f', 'closedir'=>'f', 'readdir'=>'f', 'seekdir'=>'f', 'telldir'=>'f', 'rewinddir'=>'f',	# SNOOPYJC
                  'push'=>'f', 'pop'=>'f', 'print'=>'f', 'package'=>'c',
                  'printf'=>'f',                # SNOOPYJC
                  'rindex'=>'f','read'=>'f', 
                  'rename'=>'f',                # SNOOPYJC
		  # issue 61 'return'=>'f', 
		  'return'=>'k', 		# issue 61
                  'reverse'=>'f',               # issue 65
		  'ref'=>'f',
                  'say'=>'f','scalar'=>'f','shift'=>'f', 'split'=>'f', 'sprintf'=>'f', 'sort'=>'f','system'=>'f', 'state'=>'t',
		  'sleep'=>'f',		# SNOOPYJC
		  'sqrt'=>'f',		# SNOOPYJC
                  'stat'=>'t','sub'=>'k','substr'=>'f','sysread'=>'f',  'sysseek'=>'f',
                  'tie'=>'f',
		  'time'=>'f', 'gmtime'=>'f', 'timelocal'=>'f',	'timegm'=> 'f', # SNOOPYJC
		  'unlink'=>'f',		# SNOOPYJC
                  'values'=>'f',
                  'warn'=>'f', 'when'=>'C', 'while'=>'c',
                  'undef'=>'f', 'unless'=>'c', 'unshift'=>'f','until'=>'c','uc'=>'f', 'ucfirst'=>'f','use'=>'c','untie'=>'f',
                  'umask'=>'f',                  # SNOOPYJC
                  'wait'=>'f',                   # SNOOPYJC
                  );
       %FuncType=(    # a=Array, h=Hash, s=Scalar, I=Integer, F=Float, N=Numeric, S=String, u=Unknown, f=function, H=FileHandle, ?=Optional, m=mixed
		  'abs'=>'N:N', 'alarm'=>'N:N', 'atan2'=>'NN:F', 'basename'=>'S:S',
		  'binmode'=>'HS?:u',
                  'chdir'=>'S:I','chomp'=>'S:u', 'chop'=>'S:u', 'chmod'=>'Ia:u','chr'=>'I?:S','close'=>'H:I',
                  'delete'=>'u:a', 'defined'=>'u:I','die'=>'S:u', 'each'=>'h:a', 'exists'=>'u:I', 'exit'=>'S:u', 'fc'=>'S:S', 'flock'=>'HI:I', 'fork'=>':I',
                  'fileparse'=>'SS?:a of S',
                  'glob'=>'S:a of S', 'index'=>'SSI?:I', 'int'=>'s:I', 'grep'=>'Sa:a of S', 'join'=>'Sa:S', 'keys'=>'h:a of S', 'lc'=>'S:S',
                  'length'=>'S:I', 'localtime'=>'I?:a of I', 'map'=>'fa:a', 'mkdir'=>'S:I', 'oct'=>'s:I', 'ord'=>'S:I', 'open'=>'HSS?:I',
		  'opendir'=>'HS:I', 'closedir'=>'H:I', 'readdir'=>'H:S', 'rename'=>'SS:I', 'seekdir'=>'HI:I', 'telldir'=>'H:I', 'rewinddir'=>'H:u',
                  'push'=>'aa:I', 'pop'=>'a:s', 'print'=>'H?a:I', 'printf'=>'H?Sa:I', 'rindex'=>'SSI?:I','read'=>'HsII?:I', 'reverse'=>'a:a', 'ref'=>'u:S', 
                  'say'=>'H?a:I','scalar'=>'a:I','shift'=>'a?:s', 'sleep'=>'I:I', 'split'=>'SSI?:a of s', 'sprintf'=>'Sa:S', 'sort'=>'fa:a','system'=>'a:I',
                  'sqrt'=>'N:F', 'substr'=>'SII?S?:S','sysread'=>'HsII?:I',  'sysseek'=>'HII:I', 'time'=>':I', 'gmtime'=>'I?:a of I', 'timegm'=>'IIIIII:I',
                  'timelocal'=>'IIIIII:I', 'unlink'=>'a?:I', 'values'=>'h:a', 'warn'=>'a', 'undef'=>'u', 'unshift'=>'aa', 'uc'=>'S:S',
                  'ucfirst'=>'S:S', 'umask'=>'I?:I'
                  );
#
# one to one translation of digramms. most are directly translatatble.
#
   %digram_tokens=('++'=>'^', '--'=>'^', '+='=>'=', '-='=>'=', '.='=>'=', '%='=>'=', 
                   '|='=>'=', '&='=>'=',                        # SNOOPYJC
                   '=~'=>'~','!~'=>'~',
                   '=='=>'>', '!='=>'>', '>='=>'>', '<='=>'>', # comparison
                   '=>'=>'A', '->'=>'D',                        # issue 93
                   '<<' => 'H', '>>'=>'I', '&&'=>'0', '||'=>'0', # issue 93
                   '*='=>'=', '/='=>'=', '**'=>'*', '::'=>'P' ); # issue 93

   %digram_map=('++'=>'+=1','--'=>'-=1','+='=>'+=', '*='=>'*=', '/='=>'/=', '.='=>'+=', '=~'=>'','<>'=>'readline()','=>'=>': ','->'=>'.',
                '&&'=>' and ', '||'=>' or ','::'=>'.',
               );

#  %SpaceBefore=(in=>1, is=>1, an=>1, or=>1);                  # SNOOPYJC - always generate a space before these 2-letter output words

   %SpaceBoth=('='=>1, '+='=>1, '-='=>1, '*='=>1, '/='=>1, '%='=>1,
               '>'=>1, '>='=>1, '<'=>1, '<='=>1, '=='=>1, '!='=>1,
               '|='=>1, '&='=>1, '^='=>1, '>>='=>1, '<<='=>1, '**='=>1, '//='=>1); # SNOOPYJC - always generate a space before and after these

my ($source,$cut,$tno)=('',0,0);
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
%sub_external_last_nexts=();    # issue 94: Map of subnames to set of all last/next labels that propagate out ('' if no label)
%line_needs_try_block=();       # issue 94: Map from line number to 1 if that line needs a try block
sub initialize                  # issue 94
{
    $nesting_level = 0;
    @nesting_stack = ();
    $last_label = undef;
    $last_block_lno=0;
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
sub enter_block                 # issue 94
{
    # FIXME: Use a different character like 开 = open in Chinese to replace the '{' for the second round
    return if($last_block_lno == $. && scalar(@ValPerl) <= 1);       # We see the '{' twice on like if(...) {
    if($::debug >= 4) {
        say STDERR "enter_block at line $., prior nesting_level=$nesting_level, ValPerl=@ValPerl";
    }
    $last_block_lno = $.;
    my %nesting_info = ();
    my $begin = 0;
    $begin++ if(scalar(@ValClass) >= 2 && $ValClass[0] eq 'W');         # with fileinput...
    $nesting_info{type} = '';
    $nesting_info{type} = $ValPy[$begin];
    $nesting_info{type} =~ s/:\s*$//;           # Change "else: " to "else"
    $nesting_info{lno} = $.;
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
    my $label = '';
    $label = $nesting_last->{label} if(exists $nesting_last->{label});
    if(exists $nesting_last->{can_call} && $Pythonizer::PassNo == 0) {
        for $sub (keys %{$nesting_last->{can_call}}) {
            if(exists $sub_external_last_nexts{$sub} && exists $sub_external_last_nexts{$sub}{$label}) {
                say STDERR "exit_block: setting line_needs_try_block{$nesting_last->{lno}} from call to $sub" if($::debug >= 5);
                $line_needs_try_block{$nesting_last->{lno}} = 1;
            }
        }
    }
    $nesting_level--;
}
sub last_next_propagates        # issue 94
# Does this last/next propagate out of this sub?
# Side effect - sets {needs_try_block} on any loops we need to generate a try block for
{
    $label = shift;

    if(!defined $label) {
        return 1 if($nesting_level == 0);
        $top = $nesting_stack[-1];
        return !($top->{in_loop} || $top->{in_eval});
    } elsif($Pythonizer::PassNo == 0) {         # only do this once
        for $ndx (reverse 0 .. $#nesting_stack) {
            if(exists $nesting_stack[$ndx]->{label} && $nesting_stack[$ndx]->{label} eq $label) {
                if($ndx != $#nesting_stack) {           # No need to use exception for last/next inner;
                    $nesting_stack[$ndx]->{needs_try_block} = 1;
                    say STDERR "last_next_propagates: setting line_needs_try_block{$nesting_stack[$ndx]->{lno}} from last/next at line $." if($::debug >= 5);
                    $line_needs_try_block{$nesting_stack[$ndx]->{lno}} = 1;
                }
                return 0;
            }
        }
        return 1;
    }
}

sub handle_last_next            # issue 94
{
    my $label = undef;

    return if($nesting_level == 0);
    if($#ValClass >= 1 && $ValClass[1] eq 'i') {
        $label = $ValPerl[1];
    }
    if(last_next_propagates($label)) {
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

sub loop_needs_try_block                # issue 94
{
    my $at_bottom = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($::debug >= 4) {
        no warnings 'uninitialized';
        say STDERR "loop_needs_try_block($at_bottom), top=@{[%$top]}";
    }
    return 1 if(exists $line_needs_try_block{$top->{lno}});
    return 0;
}

sub next_last_needs_raise               # issue 94
# Do we need to generate a raise statement for this next/last?
{
    return 1 if($nesting_level == 0);           # Generate an exception instead of a syntax error
    my $top = $nesting_stack[-1];
    return 1 if(!$top->{in_loop});
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
   if( $::debug > 3 && $main::breakpoint >= $.  ){
      $DB::single = 1;
   }
   while( $source ){
      $had_space = (substr($source,0,1) eq ' ');   # issue 50
      ($source)=split(' ',$source,1);  # truncate white space on the left (Perl treats ' ' like AWK. )
      $s=substr($source,0,1);
      if( $s eq '#'  ){
         # plain vanilla tail comment
         if( $tno > 0  ){
             # issue 82 $tno--;
             # issue 82 $ValCom[$tno]=$source;
            $ValCom[$tno-1]=$source;                    # issue 82
         }else{
             Pythonizer::output_line('',$source); # to block reproducing the first source line
         }
         $source=Pythonizer::getline();
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

      }elsif( $s eq '{' ){
          #say STDERR "got {, tno=$tno, source=$source, ValPerl=@ValPerl";
         # we treat '{' as the beginning of the block if it is the first or the last symbol on the line or is preceeded by ')' -- Aug 7, 2020
          if( $tno==0 ){
             enter_block();                 # issue 94
             if( length($source)>1  ){
                Pythonizer::getline(substr($source,1)); # save tail
             }
             last; # artificially truncating the line making it one-symbol line
             # issue 82 }elsif( length($source)==1 ){
          }elsif( length($source)==1 && $ValClass[$tno-1] ne '='){      # issue 82
             # $tno>0 but line may came from buffer.
             # We recognize end of statemt only if previous token eq ')' to avod collision with #h{$s}
             enter_block();                 # issue 94
             Pythonizer::getline('{'); # make $tno==0 on the next iteration
             popup(); # eliminate '{' as it does not have tno==0
             last;
	  # issue 35 }elsif( $ValClass[$tno-1] eq ')' || $source=~/^.\s*#/ || index($source,'}',1) == -1){
          }elsif( $ValClass[$tno-1] ne '=' &&                   # issue 82
                 ($ValPerl[$tno-1] eq ')' || $source=~/^.\s*#/ || index($source,'}',1) == -1 || 
                  ($ValClass[0] eq 'C' && $ValPerl[0] eq 'do') ||               # SNOOPYJC: do {...} until(...);
                  ($ValClass[0] eq 'C' && $ValPerl[0] eq 'else') ||             # SNOOPYJC: else {...}
                  ($tno == 2 && $ValPerl[0] eq 'sub') ||
                  ($tno == 1 && ($ValPerl[0] eq 'BEGIN' || $ValPerl[0] eq 'END')))){	# issue 35, 45
             # $tno>0 this is the case when curvy bracket has comments'
             enter_block();                 # issue 94
             Pythonizer::getline('{',substr($source,1)); # make it a new line to be proceeed later
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
           $ValPerl[$tno]=remove_escaped_delimiters($s, substr($source,1,$cut-2));       # issue 51
           substr($source,0,$cut)=''; # you need to provide modifiers to perl_match
           $cut=0;
           if( $tno>=1 && ( ($ValClass[$tno-2] eq 'f' && $ValPerl[$tno-2] !~ /^(?:chomp|chop|chr|shift)$/)      # issue 99: not a function that takes no args
                            || $ValPerl[$tno-1] eq 'split') ){
              # in split regex should be plain vanilla -- no re.match is needed.
              $ValPy[$tno]=put_regex_in_quotes( $ValPerl[$tno]); #  double quotes neeed to be escaped just in case
           }else{
              $ValPy[$tno]=perl_match($ValPerl[$tno]); # there can be modifiers after the literal.
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
            $ValPerl[$tno]=substr($source,1,$cut-2); # FIXME: we do not allow variables is here string.
	    # issue 39 $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno]);
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);	# issue 39
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
         }elsif( $source=~/(^\d+(?:[.]\d*)?(?:e[+-]?\d+)?)/  ){	# issue 23
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
         }
         $ValPerl[$tno]=$w;
         $ValClass[$tno]='i';
         $ValPy[$tno]=$w;
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
            }                                   # issue 89
            $ValClass[$tno]=$class;
            if( $class eq 'c' && $tno > 0 && $Pythonizer::PassNo && ($ValClass[0] ne 'C' || $ValPerl[0] ne 'do')){ # Control statement, like if # SNOOPYJC: do
               # The current solution is pretty britle but works
               # You can't recreate Perl source from ValPerl as it does not have 100% correspondence.
               # So the token buffer implemented Oct 08, 2020 --NNB
               # Note you can't use both getline buffer and token buffer, so you can't add '{' to the end of if statement
               # You need to jump thoou the hoops in Pythonizer to inject '{' and '}' into the stream
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
	 	  if(index($ValPy[$tno], "\n") >= 0) {		# issue 39 - multi-line string
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
                  $arg1=remove_escaped_delimiters($delim, substr($source,0,$cut-1));     # issue 51
                  $source=substr($source,$cut); #cut to symbol after the delimiter
                  $cut=0;
                  if( $w eq 'm' || ($w eq 'qr' &&  $ValClass[$tno-1] eq '~') ){
                     $ValClass[$tno]='q';
                     $ValPy[$tno]=perl_match($arg1); # it calls is_regex internally
                  }elsif( $w eq 'qr' && $tno>=2 && $ValClass[$tno-1] eq '(' && $ValPerl[$tno-2] eq 'split' ){
                      # in split regex should be  plain vanilla -- no re.match is needed.
                      $ValPy[$tno]='r'.$quoted_regex; #  double quotes neeed to be escaped just in case
                  }elsif( $w eq 's' ){
                     $ValPerl[$tno]='re';
                     $ValClass[$tno]='f';
                     # processing second part of 's'
                     if( $delim=~tr/{([<'/{([<'/ ){
                        # case tr[abc][cde]
                        $delim=substr($source,0,1); # new delimiter can be different from the old, althouth this is raraly used in Perl.
                        $source=substr($source,1,0); # remove delimiter
                     }
                     # now string is  /def/d or [def]
                     $cut=single_quoted_literal($delim,0);
                     # issue 51 $arg2=substr($source,0,$cut-1);
                     $arg2=remove_escaped_delimiters($delim, substr($source,0,$cut-1));          # issue 51
                     $source=substr($source,$cut);
                     $cut=0;
                     ($modifier,undef)=is_regex($arg2); # modifies $source as a side effect
                     if( length($modifier) > 1 ){
                        #regex with modifiers
                         $quoted_regex='re.compile('.put_regex_in_quotes($arg1)."$modifier)";
                     }else{
                        # No modifier
                        $quoted_regex=put_regex_in_quotes($arg1);
                     }
                     if( length($modifier)>0 ){
                        #this is regex
                        if( $tno>=1 && $ValClass[$tno-1] eq '~'   ){
                           # explisit s
                            $ValPy[$tno]='re.sub('.$quoted_regex.','.put_regex_in_quotes($arg2).','; #  double quotes neeed to be escaped just in case
                        }else{
                            $ValPy[$tno]="re.sub($quoted_regex".','.put_regex_in_quotes($arg2).",$DEFAULT_VAR)";	# issue 32, 78
                        }
                     }else{
                        # this is string replace operation coded in Perl as regex substitution
                        $ValPy[$tno]='str.replace('.$quoted_regex.','.$quoted_regex.',1)';
                     }
                  } elsif( $w eq 'qr' ) {               # SNOOPYJC: qr in other context
                     ($modifier,$groups_are_present)=is_regex($arg1);                           # SNOOPYJC
                     $modifier='' if($modifier eq 'r');                                         # SNOOPYJC
                     $ValPy[$tno]='re.compile('.put_regex_in_quotes($arg1).$modifier.')';       # SNOOPYJC
                  }else{
                     abend("Internal error while analysing $w in line $. : $_[0]");
                  }
               }elsif( $w eq 'tr' || $w eq 'y'  ){
                  # tr function has two parts; also can be named y
                  $source=substr($source,length($w)+1); # cut the word and delimiter
                  $cut=single_quoted_literal($delim,0);
                  # issue 51 $arg1=substr($source,0,$cut-1); # regex always ends before the delimiter
                  $arg1=remove_escaped_delimiters($delim, substr($source,0,$cut-1)); # regex always ends before the delimiter # issue 51
                  $source=substr($source,$cut); # remove first part of substitution exclufing including the delimeter
                  if( index('{([<',$delim) > -1 ){
                     # case tr[abc][cde]
                     $delim=substr($source,0,1); # new delimiter can be different from the old, althouth this is raraly used in Perl.
                     $source=substr($source,1,0); # remove delimiter
                  }
                  # now string is  /def/d or [def]
                  $cut=single_quoted_literal($delim,0);
                  # issue 51 $arg2=substr($source,0,$cut-1);
                  $arg2=remove_escaped_delimiters($delim, substr($source,0,$cut-1));     # issue 51
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
                  if( $tr_modifier eq 'd' ){
                          $ValPy[$tno]=".maketrans('','',".put_regex_in_quotes($arg1).')'; # deletion via none
                  }elsif( $tr_modifier eq 's' ){
                       # sqeeze In Python should be done via Regular expressions
                         if( $arg2 eq '' || $arg1 eq $arg2  ){
                            $ValPerl[$tno]='re';
                            $ValPy[$tno]='re.sub('.put_regex_in_quotes("([$arg1])(\\1+)").",r'\\1'),"; # needs to be translated into  two statements
                         }else{
                            $ValPerl[$tno]='re';
                            if( $ValClass[$tno-2] eq 's' ){
                                $ValPy[$tno]="$ValPy[$tno-2].translate($ValPy[$tno-2].maketrans(".put_regex_in_quotes($arg1).','.put_regex_in_quotes($arg2).')); ';
                                $ValPy[$tno].='re.sub('.put_regex_in_quotes("([$arg2])(\\1+)").",r'\\1'),"; # needs to be translated into  two statements
                            }else{
                                $::TrStatus=-255;
                                $ValPy[$tno].='re.sub('.put_regex_in_quotes("([$arg2])(\\1+)").",r'\\1'),";
                                logme('S',"The modifier $tr_modifier for tr function with non empty second arg ($arg2) requires preliminary invocation of translate. Please insert it manually ");
                            }
                         }
                  }elsif( $tr_modifier eq '' ){
                      #one typical case is usage of array element on the left side $main::tail[$a_end]=~tr/\n/ /;
                      $ValPy[$tno]='.maketrans('.put_regex_in_quotes($arg1).','.put_regex_in_quotes($arg2).')'; # needs to be translated into  two statements
                  }else{
                      $::TrStatus=-255;
                      logme('S',"The modifier $tr_modifier for tr function currently is not translatable. Manual translation requred ");
                  }

               }elsif( $w eq 'qw' ){
                  # we can emulate it with split function, althouth wq is mainly compile time.
                   $cut=single_quoted_literal($delim,length($w)+1);
                   # issue 51 $ValPerl[$tno]=substr($source,length($w)+1,$cut-length($w)-2);
                   $ValPerl[$tno]=remove_escaped_delimiters($delim, substr($source,length($w)+1,$cut-length($w)-2));
                   if( $ValPerl[0] eq 'use' ){
                      $ValPy[$tno]=$ValPerl[$tno];
                   }else{
		      # issue 44 $ValPy[$tno]='"'.$ValPerl[$tno].'".split(r"\s+")';
                      $ValPy[$tno]='"'.$ValPerl[$tno].'".split()';	# issue 44: python split doesn't take a regex!
                   }
               }
            }
	 } elsif( ($tno>1 && $ValPerl[$tno-1] eq '<<' && index('sd)', $ValClass[$tno-2]) < 0) || # issue 39 - bare HereIs (and not a shift)
	          ( $tno>2 && $ValPerl[$tno-1] eq '~' && $ValPerl[$tno-2] eq '<<' && index('sd)', $ValClass[$tno-3]) < 0)) {	# issue 39 - bare HereIs (and not a shift)
            $has_squiggle = ($ValPerl[$tno-1] eq '~');
            $tno--; # overwrite previous token; Dec 20, 2019 --NNB
            $tno-- if($has_squiggle);           # overwrite that one too!
            $ValClass[$tno]='"';		# issue 39
            $ValPerl[$tno]=substr($source,0,$cut); # FIXME: we do not allow variables is here string.
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);	# issue 39
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
	    if($tno!=0 && 
               (($ValClass[$tno-1] eq 's' && $ValPerl[$tno-1] eq '$') || # issue 50
                $ValClass[$tno-1] eq '@' || 
                ($ValClass[$tno-1] eq '%' && !$had_space))) {	# issue 50
               # Change $$xxx to $xxx, @$xxx to $xxx and %$yyy to $yyy but NOT % $yyy as that's a MOD operator!
	       popup();                         # issue 50
	       $tno--;				# issue 50 - no need to change hashref to hash or arrayref to array in python
      	       $ValPerl[$tno]=$ValPy[$tno]=$s;	# issue 50
	    }
            $end_br = 0;                                # issue 43
            if(substr($source,1,1) eq '{') {		# issue 43: ${...}
                $end_br = matching_curly_br($source, 1); # issue 43
                $source = '$'.substr($source,2);	# issue 43: eat the '{'. At this point, $end_br points after the '}'
            }
            decode_scalar($source,1);
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
                $ValPerl[$tno] = '{'.$ValPerl[$tno].'}'; # issue 43: remember we had ${var} for where we care (like <${var}>)
            }
         }
      }elsif( $s eq '@'  ){
         # SNOOPYJC if( substr($source,1)=~/^(\:?\:?\w+(\:\:\w+)*)/ ){
         if( substr($source,1)=~/^(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)/ ){       # SNOOPYJC: Allow ' from old perl
            $arg1=$1;
            if( $arg1 eq '_' ){
               $ValPy[$tno]="$PERL_ARG_ARRAY";	# issue 32
               $ValType[$tno]="X";
            }elsif( $arg1 eq 'ARGV'  ){
		    # issue 49 $ValPy[$tno]='sys.argv';
                  $ValPy[$tno]='sys.argv[1:]';	# issue 49
                  $ValType[$tno]="X";
            }else{
	       my $arg2 = escape_keywords($arg1);		# issue 41
               if( $tno>=2 && $ValClass[$tno-2] =~ /[sd'"q]/  && $ValClass[$tno-1] eq '>'  ){
                  $ValPy[$tno]='len('.$arg2.')'; # scalar context   # issue 41
                  $ValType[$tno]="X";
                }else{
                  $ValPy[$tno]=$arg2;            # issue 41
               }
               $ValPy[$tno]=~tr/:/./s;
               $ValPy[$tno]=~tr/'/./s;          # SNOOPYJC
               if( substr($ValPy[$tno],0,1) eq '.' ){
                  $ValPy[$tno]='__main__'.$ValPy[$tno];
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
            $ValPerl[$tno]=$1;
            $ValPy[$tno]=$1;
            $ValPy[$tno]=~tr/:/./s;
            $ValPy[$tno]=~tr/'/./s;             # SNOOPYJC
	    $ValPy[$tno] = escape_keywords($ValPy[$tno]);
            if( substr($ValPy[$tno],0,1) eq '.' ){
               $ValCom[$tno]='X';
               $ValPy[$tno]='__main__'.$ValPy[$tno];
            }
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
	    $ValPy[$tno] = escape_keywords($ValPy[$tno]);
            if( substr($ValPy[$tno],0,1) eq '.' ){
               $ValCom[$tno]='X';
               $ValPy[$tno]='__main__'.$ValPy[$tno];
            }
            $Pythonizer::LocalSub{$ValPerl[$tno]} = 1;
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
            if($digram eq '=>' && $tno != 0 && $ValClass[$tno-1] eq 'f' && $ValPerl[$tno-1] eq 'delete') {    # issue delete
                $ValClass[$tno-1] = '"';        # delete => '...' - make it into 'delete' => '...'
                $ValPy[$tno-1] = "'delete'";
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
           if( ($k=index('fdlzesACM',$s2))>-1 && substr($source,2,1)=~/\s/  ){
              $ValClass[$tno]='f';
              $ValPerl[$tno]=$digram;
              $ValPy[$tno]=('os.path.isfile','os.path.isdir','os.path.islink','not os.path.getsize','os.path.exists','os.path.getsize','_getA', '_getC', '_getM')[$k];          # SNOOPYJC
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
               $ValClass[$tno]='i';
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
                   if(length($fh)==0){         # issue 66
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
                       insert(0, 'W', "<$fh>", qq{with fileinput.input("<$fh>",openhook=lambda _,__:$fh) as $DIAMOND:});    # issue 66
                       $tno++;                                     # issue 66
                       $ValPy[$tno]="next($DIAMOND, None)";        # issue 66: Allows for $.
                   }
               }else{           # we're just reading one line so we can't use the context manager as it closes the file handle
                   if(length($fh)==0){         # issue 66
                       $ValPy[$tno]="next(fileinput.input(), None)";        # issue 66: Allows for $.
                   }elsif($fh eq 'STDIN' ){     # issue 66
                       # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                       $ValPy[$tno]='sys.stdin().readline()';
                       # $ValPy[$tno]="next(with fileinput.input('-'), None)";        # issue 66: Allows for $.
                   }else{
                       # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                       $ValPy[$tno]="$fh.readline()";
                       #insert(0, 'W', "<$fh>", qq{with fileinput.input("<$fh>",openhook=lambda _,__:$fh) as $DIAMOND:});    # issue 66
                       #$tno++;                                     # issue 66
                       #$ValPy[$tno]=qq{next(with fileinput.input("<$fh>",openhook=lambda _,__:$fh), None)};        # issue 66: Allows for $.
                   }
               }
            }elsif($source =~ /^<\$(\w*)>/ ) {          # issue 66: <$fh>
               $ValClass[$tno]='i';
               $cut=length($1)+3;
               $ValPerl[$tno]="<\$$1>";
               #
               # Let's try to determine the context
               #
	       # issue 62 if( $tno==2 && $ValClass[0] eq 'a' && $ValClass[1] eq '='){
               if( $tno>=2 && $ValClass[$tno-2] eq 'a' && $ValClass[$tno-1] eq '='){	# issue 62: handle "my @a=<FH>;" and "chomp(my @a=<FH>);"
                   $ValPy[$tno]="$1.readlines()";
               }elsif($ValClass[0] eq 'c' and $ValPerl[0] eq 'while') { # issue 66
                   insert(0, 'W', "<$1>", qq{with fileinput.input("<$1>",openhook=lambda _,__:$1) as $DIAMOND:});    # issue 66
                   $tno++;                                     # issue 66
                   $ValPy[$tno]="next($DIAMOND, None)";        # issue 66: Allows for $.
               }else{
                   # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                   $ValPy[$tno]="$1.readline()";
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
	       if( $source=~/(^[.]\d+(?:e[+-]?\d+)?)/  ){	# issue 23
	          $ValClass[$tno] = 'd';			# issue 23
		  $ValPy[$tno] = $ValPerl[$tno] = $1;		# issue 23
		  $cut=length($1);				# issue 23
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
      finish(); # subroutine that prepeares the next cycle
   } # while
   if($tno > 0 && $ValClass[0] eq 'k' && ($ValPerl[0] eq 'last' || $ValPerl[0] eq 'next')) {    # issue 94
       handle_last_next();                              # issue 94
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
      substr($source,0,$cut)='';
   }
   if( length($source)==0  ){
       # the current line ended but ; or ){ } were not reached
       $original=$Pythonizer::IntactLine;
       @tmpBuffer = @BufferValClass;	# Issue 7
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
   if( $::debug > 3  ){
     say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
   }
   $tno++;
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
   if(join('',@ValClass) =~ /^t?[ahs](?:\(.*\))*=/ && 
      !$is_low_prec &&
      substr($source,$split) !~ /^\s*(?:return|next|last|assert|delete|require|die)\b/) {       # issue 93
       if($::debug >= 3) {
          say STDERR "bash_style_or_and_fix($split) returning 0 - does not need transforming";
       }
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
   my $specials = q(!?<>()!;]&`'+"@$|,\\);              # issue 50
   if($s2 eq '$' && substr($source,2,1) =~ /[\w:]/) {   # issue 50
       $specials = '!';
   }
   if( $s2 eq '.'  ){
      # file line number
      # issue 66 $ValPy[$tno]='fileinput.filelineno()';
       $ValPy[$tno]='fileinput.lineno()';       # issue 66: Mimic the perl behavior
       $ValType[$tno]="X";
       $cut=2
   }elsif( $s2 eq '^'  ){
       $s3=substr($source,2,1);
       $cut=3;
       $ValType[$tno]="X";
       if( $s3=~/\w/  ){
          if( exists($SPECIAL_VAR2{$s3}) ){
            $ValPy[$tno]=$SPECIAL_VAR2{$s3};
          }else{
            $ValPy[$tno]='unknown_perl_special_var'.$s3;
         }
       }
   # issue 46 }elsif( index(q(!?<>()!;]&`'+"),$s2) > -1  ){
   }elsif( index($specials,$s2) > -1  ){	# issue 46, issue 50
      $ValPy[$tno]=$SPECIAL_VAR{$s2};
      $cut=2;
      $ValType[$tno]="X";
   }elsif( $s2 =~ /\d/ ){
       $source=~/^.(\d+)/;
       if( $update ){
          $ValPerl[$tno]=$1;
          $ValType[$tno]="X";
       }
       if( $s2 eq '0' ){
         $ValType[$tno]="X";
         $ValPy[$tno]="__file__";
       }else{
          $ValType[$tno]="X";
          $ValPy[$tno]="$DEFAULT_MATCH.group($1)";		# issue 32
       }
       $cut=length($1)+1;
   }elsif( $s2 eq '#' ){
      if(!($source=~/^..(\w+)/)) {
          $source=~/^...(\w+)/;                # SNOOPYJC: Handle $#$arr_ref
      }
      $ValType[$tno]="X";
      if( $update ){
         $ValPerl[$tno]=$1;
      }
      if( $1 eq 'ARGV'  ){                      # SNOOPYJC: Generate proper code for $#ARGV
          $ValPy[$tno] ='(len(sys.argv)-2)';    # SNOOPYJC
      } else {                                  # SNOOPYJC
          $ValPy[$tno]='(len('.$1.')-1)';       # SNOOPYJC
      }
      $cut=length($1)+2;
  # SNOOPYJC }elsif( $source=~/^.(\w*(\:\:\w+)*)/ ){
  }elsif( $source=~/^.(\w*((?:(?:\:\:)|\')\w+)*)/ ){    # SNOOPYJC: old perl uses ' for ::
      $cut=length($1)+1;
      $name=$1;
      $ValPy[$tno]=$name;
      if( $update ){
         $ValPerl[$tno]=substr($source,0,$cut);
      }
      if( ($k=index($name,'::')) > -1 ){
         $ValType[$tno]="X";
         if( $k==0 || substr($name,$k) eq 'main' ){
            substr($name,0,2)='__main__.';
            $ValPy[$tno]=$name;
            $rc=1 #regular var
         }else{
            substr($name,$k,2)='.';
	    $name = escape_keywords($name);
	    $ValPy[$tno]=$name;
            $rc=1 #regular var
         }
     } elsif( ($k=index($name,"'")) > -1 ){             # Old perl uses ' for ::
         $ValType[$tno]="X";
         if( $k==0 || substr($name,$k) eq 'main' ){
            substr($name,0,1)='__main__.';
            $ValPy[$tno]=$name;
            $rc=1 #regular var
         }else{
            substr($name,$k,1)='.';
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
            }else{
               $ValPy[$tno]="$DEFAULT_VAR";			# issue 32
               $cut=2;
            }
         }elsif( $s2 eq 'a' || $s2 eq 'b' ){
            $ValType[$tno]="X";
	    # issue 32 $ValPy[$tno]='perl_sort_'.$s2;
            $ValPy[$tno]="$PERL_SORT_$s2";	# issue 32
            $cut=2;
         }else{
            $rc=1 #regular var
         }
      }else{
        # this is a "regular" name with the length greater then one
        # $cut points to the next symbol after the scanned part of the scapar
           # check for Perl system variables
           if( $1 eq 'ENV'  ){
              $ValType[$tno]="X";
              $ValPy[$tno]='os.environ';
           }elsif( $1 eq 'ARGV'  ){
              $ValType[$tno]="X";
              if($cut < length($source) && substr($source,$cut,1) eq '[') {    # $ARGV[...] is a reference to @ARGV
	          $ValPy[$tno]='sys.argv[1:]';
              } else {
                  $ValPy[$tno]='fileinput.filename()';	# issue 49: Differentiate @ARGV from $ARGV, issue 66
              }
           }else{
	     $ValPy[$tno] = escape_keywords($ValPy[$tno]);	# issue 41
             $rc=1; # regular variable
           }
      }
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

my  ($modifier, $i,$sym,$prev_sym,@temp);
my  $is_regex=0;
my  $groups_are_present;
#
# Is this regex or a reguar string used in regex for search
#
   ($modifier,$groups_are_present)=is_regex($myregex);
   if( length($modifier) > 1 ){
      #regex with modifiers
      $quoted_regex='re.compile('.put_regex_in_quotes($myregex).$modifier.')';
   }else{
      # No modifier
      $quoted_regex=put_regex_in_quotes($myregex);
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
	$line = Pythonizer::getline();		# issue 39
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
   $quote=remove_escaped_delimiters($closing_delim, $quote);     # issue 51
   $ValPerl[$tno]=$quote; # also will serve as original
   if (length($quote) == 1 ){
      $ValPy[$tno]=escape_quotes($quote,2);
      return $close_pos;
   }
   #
   # decompose all scalar variables, if any, Array and hashes are left "as is"
   #
   $k=index($quote,'$');
   if( $k==-1 && index($quote, '@') == -1){             # issue 47
      # case when double quotes are used for a simple literal that does not reaure interpolation
      # Python equvalence between single and doble quotes alows some flexibility
      $ValPy[$tno]=escape_quotes($quote,2); # always generate with quotes --same for Python 2 and 3
      return $close_pos;
   }
   #
   #decode each part. Double quote literals in Perl are ver difficult to decode
   # This is a parcial implementation of the most common cases
   # Full implementation is possible only in two pass scheme
my  $outer_delim;
    $quote = escape_curly_braces($quote);        # issue 51
    $k=index($quote,'$');                        # issue 51 - recompute in case it moved

    if (index($quote,'"')==-1 && index($quote, "\n")==-1){      # issue multi-line here
       $outer_delim='"'
    # issue 53: we use single quotes in our 'bareword' so we can't use them here if we have {...}
    }elsif(index($quote,"'")==-1 && index($quote,'{')==-1 && index($quote,"\n")==-1){     # issue 53, multi-line here
      $outer_delim="'";
    }else{
      $outer_delim='"""';
    }
   $result='f'.$outer_delim; #For python 3 we need special opening quote
   while( $k > -1  ){
      if( $k > 0 ){
         if( substr($quote,$k-1,1) eq '\\' ){
            # escaped $
            # issue 51 $k=index($quote,'$',$k+1);
            substr($quote,$k-1,1) = '';         # issue 51 - eat the escape
            $k=index($quote,'$',$k);            # issue 51
            next;
         }else{
            # we have the first literal string  before varible
            $result.=substr($quote,0,$k); # with or without quotes depending on version.
         }
      }
      $result.='{';  # we always need '{' for f-strings
      $quote=substr($quote,$k);
      #say STDERR "quote1=$quote\n";
      $end_br = -1;				# issue 43
      if(substr($quote,1,1) eq '{') {		# issue 43: ${...}
         $end_br = matching_curly_br($quote, 1); # issue 43
         $quote = '$'.substr($quote,2);		# issue 43: eat the '{'. At this point, $end_br points after the '}'
         #say STDERR "quote1a=$quote, end_br=$end_br\n";
      }
      decode_scalar($quote,0); #get's us scalar or system var
      #does not matter what type of veriable this is: regular or special variable
      $result.=$ValPy[$tno]; # copy string provided by decode_scalar. ValPy[$tno] changes if Perl contained :: like in $::debug
      $quote=substr($quote,$cut); # cure the nesserary number of symbol determined by decode_scalar.
      $end_br -= $cut;			# issue 43
      #say STDERR "quote2=$quote, result1=$result, end_br=$end_br";
      my $p_len = length($quote);                       # issue 13, 43
      $quote =~ s/(?<!\$)\{([A-Za-z_][A-Za-z0-9_]*)\}/\{\'$1\'\}/g;     # issue 13: Remove bare words in $hash{...}
      my $n_len = length($quote);
      if($end_br >= 0 && $n_len > $p_len) {             # issue 13, 43  it grew so move the pointer over
          $end_br += ($n_len - $p_len);                 # issue 13, 43
      }                                                 # issue 13, 43
      #say STDERR "quote3=$quote";
      # issue 98 if( $quote=~/^\s*([\[\{].+?[\]\}])/  ){
      if( $quote=~/^([\[\{].+?[\]\}])/  ){              # issue 98: Don't allow spaces before the [ or {
         #HACK element of the array of hash. Here we cut corners and do not process expressions as index.
         $ind=$1;
         $cut=length($ind);
         $ind =~ tr/$//d;
	 # issue 53 $ind =~ tr/{}/[]/;
         #say "looking for '{' in $ind";
	 for(my $i = 0; $i < length($ind); $i++) {	# issue 53: change hash ref {...} to use .get(...) instead
	     if(substr($ind,$i,1) eq '{') {		# issue 53
	         $l = matching_curly_br($ind, $i);	# issue 53
                 #say "found '{' in $ind at $i, l=$l";
		 next if($l < 0);			# issue 53
		 $ind = substr($ind,0,$i).'.get('.substr($ind,$i+1,$l-($i+1)).",'')".substr($ind,$l+1);	# issue 53: splice in the call to get
                 #say "ind=$ind";
		 $i = $l+7;				# issue 53: 7 is length('.get') + length(",''")
	     }
	 }						# issue 53
         $result.=$ind; # add string Variable part of the string
         $quote=substr($quote,$cut);
         $end_br -= $cut;			# issue 43
         #say STDERR "quote4=$quote, end_br=$end_br";
      }
      #say STDERR "quote5=$quote, end_br=$end_br";
      $quote = substr($quote, $end_br) if($end_br > 0);	# issue 43
      $result.='}'; # end of variable
      $k=index($quote,'$'); #next scalar
   }

   $k=index($quote,'@');                # issue 47
   while( $k > -1  ){
      if( $k > 0 ){
         $pc = substr($quote,$k-1,1);
         if( $pc eq '\\' ){
            # escaped $
            # issue 51 $k=index($quote,'$',$k+1);
            substr($quote,$k-1,1) = '';         # issue 51 - eat the escape
            $k=index($quote,'@',$k);            # issue 51
            next;
         }elsif( $pc =~ /\w/ ) {        # Probable email address xyz@abc.com - don't interpret the '@'
            $k = index($quote,'@',$k+1);
            next;
         }else{
            # we have the first literal string  before varible
            $result.=substr($quote,0,$k); # with or without quotes depending on version.
         }
      }
      $result.='{';  # we always need '{' for f-strings
      $quote=substr($quote,$k);
      #say STDERR "quote1=$quote\n";
      $end_br = -1;				# issue 43
      if(substr($quote,1,1) eq '{') {		# issue 43: @{...}
         $end_br = matching_curly_br($quote, 1); # issue 43
         $quote = '@'.substr($quote,2);		# issue 43: eat the '{'. At this point, $end_br points after the '}'
         #say STDERR "quote1a=$quote, end_br=$end_br\n";
      }
      if($end_br > 0 && substr($quote,0,3) eq '@[%') {  # @{[%hash]}
          $quote = substr($quote, 2);
          decode_hash($quote,0);
          $ValPy[$tno] = 'functools.reduce(lambda x,y:x+y,'.$ValPy[$tno].'.items())';
          $end_br -= 2;    # 2 to account for the 2 we ate
          #say STDERR "quote1b=$quote, end_br=$end_br\n";
      } else {
          decode_array($quote,0); #get's us scalar or system var
      }
      #does not matter what type of veriable this is: regular or special variable
      $result.="LIST_SEPARATOR.join($ValPy[$tno])"; # copy string provided by decode_array. ValPy[$tno] changes if Perl contained :: like in $::debug
      $quote=substr($quote,$cut); # cure the nesserary number of symbol determined by decode_array.
      $end_br -= $cut;			# issue 43
      #say STDERR "quote2=$quote, result1=$result, end_br=$end_br";
      $quote = substr($quote, $end_br) if($end_br > 0);	# issue 43
      $result.='}'; # end of variable
      $k=index($quote,'@'); #next array
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
   return $close_pos;
}

sub escape_curly_braces                 # issue 51
# If the string already has {...} in it, replace them with {{...}} for f strings
# Make sure NOT to replace ${...} and @{...} as they have special meaning
# Also don't mess with $hash{...} or $arrhash[...]{...} or $hashhash{...}{...}
{
    my $str = shift;
    #say STDERR "escape_curly_braces($str)";

    my $in_id = 0;
    for(my $k = 0; $k < length($str); $k++) {
        my $c = substr($str,$k,1);
        if($c eq '$' && substr($str, $k+1) =~ /^(\:?\:?\w+(\:\:\w+)*)/) {
            $k += length($1);
            if($k+1 < length($str)) {
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

     if( substr($source,1)=~/^(\:?\:?\w+(\:\:\w+)*)/ ){
        $arg1=$1;
        if( $arg1 eq '_' ){
           $ValPy[$tno]="$PERL_ARG_ARRAY";	# issue 32
           #$ValType[$tno]="X";
        }elsif( $arg1 eq 'ARGV'  ){
                # issue 49 $ValPy[$tno]='sys.argv';
              $ValPy[$tno]='sys.argv[1:]';	# issue 49
              #$ValType[$tno]="X";
        }else{
           $arg1 = escape_keywords($arg1);		# issue 41
           #if( $tno>=2 && $ValClass[$tno-2] =~ /[sd'"q]/  && $ValClass[$tno-1] eq '>'  ){
              #$ValPy[$tno]='len('.$arg1.')'; # scalar context
              #$ValType[$tno]="X";
              #}else{
              $ValPy[$tno]=$arg1;
              #}
           $ValPy[$tno]=~tr/:/./s;
           if( substr($ValPy[$tno],0,1) eq '.' ){
              $ValPy[$tno]='__main__'.$ValPy[$tno];
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

     if( substr($source,1)=~/^(\:?\:?[_a-zA-Z]\w*(\:\:[_a-zA-Z]\w*)*)/ ){
        $cut=length($1)+1;
        #$ValClass[$tno]='h'; #hash
        #$ValPerl[$tno]=$1;
        $ValPy[$tno]=$1;
        $ValPy[$tno]=~tr/:/./s;
        $ValPy[$tno] = escape_keywords($ValPy[$tno]);
        if( substr($ValPy[$tno],0,1) eq '.' ){
            #$ValCom[$tno]='X';
           $ValPy[$tno]='__main__'.$ValPy[$tno];
        }
     }else{
       $cut=1;
     }
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
   $string =~ s/\$\&/\\g<0>/g;	# issue 11
   $string =~ s/\$(\d)/\\g<$1>/g; # issue 11
   # SNOOPYJC if( $string =~/\$\w+/ ){
   if( $string =~/^\$\w+/ ){    # SNOOPYJC: FIXME: We have to interpolate all $vars inside!! e.g. /DC_$year$month/ gen rf"..."
      return substr($string,1); # this case of /$regex/ we return the variable.
   }
   # SNOOPYJC return 'r'.escape_quotes($string);
   return 'r'.escape_quotes($string);   # SNOOPYJC
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
      if( scalar(@PythonCode) >256  ){
         $chunk=$PythonCode[$i];
         $k=$i;
         --$k while($PythonCode[$k] eq $chunk);
         logme('T','The number of generated chunk exceeed 256');
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
      $pos=scalar($ValClass)-$pos;
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
     $s=substr($str,$k,1);
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
     $s=substr($str,$k,1);
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
{
	my $name = shift;
	my @ids = split /[.]/, $name;
	my @result = ();
	for my $id (@ids) {
	   if(exists $PYTHON_KEYWORD_SET{$id}) {
	       $id = $id.'_';
	   }
           push @result, $id;
	}
	return join('.', @result);
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
1;

