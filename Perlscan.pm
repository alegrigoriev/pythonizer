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
use Pyconfig;               # issue 32
use Text::Balanced qw{extract_bracketed};       # issue 53
require Exporter;
use Data::Dumper;                       # issue 108
use Storable qw(dclone);                # SNOOPYJC
use Carp qw(cluck);                     # SNOOPYJC
use charnames qw/:full :short/;         # SNOOPYJC
use File::Basename;                 # SNOOPYJC
use File::Spec::Functions qw(file_name_is_absolute catfile);   # SNOOPYJC
use Encode qw/find_encoding/;           # issue s70

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXPORT = qw(gen_statement tokenize gen_chunk append replace destroy insert destroy autoincrement_fix @ValClass  @ValPerl  @ValPy @ValCom @ValType $TokenStr escape_keywords unescape_keywords %SPECIAL_FUNCTION_MAPPINGS save_code restore_code %token_precedence %SpecialVarsUsed @EndBlocks %SpecialVarR2L get_sub_vars_with_class %FileHandles add_package_to_mapped_name %FuncType %PyFuncType %UseRequireVars %UseRequireOptionsPassed %UseRequireOptionsDesired mapped_name %WHILE_MAGIC_FUNCTIONS %UseSwitch @BeginBlocks @InitBlocks @CheckBlocks @UnitCheckBlocks special_code_block_name ok_to_break_line handle_block_scope_pragma);   # issue 41, issue 65, issue 74, issue 92, issue 93, issue 78, issue names, issue s40, issue s129, issue s155, issue s228, use integer, use English
#our (@ValClass,  @ValPerl,  @ValPy, $TokenStr); # those are from main::

  $VERSION = '0.93';
  #
  # types of veriables detected during the first pass; to be implemented later
  #
  #%is_numeric=();

  %SpecialVarsUsed=();                  # SNOOPYJC: Keep track of special vars used so we can generate better code if you don't use some feature
  %NameMap=();                          # issue 92: Map names to python names (Original python name => {sigil => new python name, ...})
  %ReverseNameMap=();                   # issue s172: New python name => Original python name
  @EndBlocks=();                        # SNOOPYJC: List of END blocks with their unique names
  @BeginBlocks=();                      # issue s155: List of BEGIN blocks with their unique names
  @InitBlocks=();                       # issue s155: List of INIT blocks with their unique names
  @CheckBlocks=();                      # issue s155: List of CHECK blocks with their unique names
  @UnitCheckBlocks=();                  # issue s155: List of UNITCHECK blocks with their unique names
  %SpecialVarR2L=();                    # SNOOPYJC: Map from special var RHS to LHS
  %FileHandles = ();                    # SNOOPYJC: Set of file handles used in this file
  @UseLib=();                           # SNOOPYJC: Paths added using "use lib"
  %UseSwitch=();                        # issue s129: use Switch: set of what's passed on the use statement like __ or fallthrough
  $fullpy = undef;                      # SNOOPYJC: Path to python file of package ref
  %UseRequireVars=();                   # issue names: map from fullpath to setref of perl varnames
  %UseRequireOptionsPassed=();          # issue names: map from fullpath to string of options that were sent to pythonizer
  %UseRequireOptionsDesired=();         # issue names: map from fullpath to string of options we want passed to pythonizer
  %BlockScopePragmas=();                # use integer, use English
  %StatementStartingLno=();             # issue s275: Map from line number to statement_starting_lno
#
# List of Perl special variables
#

   # NOTE: If you add more to this hash, update $specials in decode_scalar, defined below
   %SPECIAL_VAR=(';'=>'PERL_SUBSCRIPT_SEPARATOR','>'=>'os.geteuid()','<'=>'os.getuid()',
                '('=>"' '.join(map(str, os.getgrouplist(os.getuid(), os.getgid())))",     # SNOOPYJC
                ')'=>"' '.join(map(str, os.getgrouplist(os.geteuid(), os.getegid())))",   # SNOOPYJC
                '?'=>"$SUBPROCESS_RC",
                #SNOOPYJC '!'=>'unix_diag_message',
                '!'=>'OS_ERROR',        # SNOOPYJC
                # SNOOPYJC '$'=>'process_number',
                '$'=>'os.getpid()',             # SNOOPYJC
                ';'=>'subscript_separator,',
                # SNOOPYJC ']'=>'perl_version',
                ']'=>"$PERL_VERSION",           # SNOOPYJC
                #SNOOPYJC '&'=>'last_successful_match',
                '&'=>"$DEFAULT_MATCH.group(0)", # SNOOPYJC, issue 32
                '@'=>'EVAL_ERROR',              # SNOOPYC
                '"'=>'LIST_SEPARATOR',      # issue 46
                '|'=>'OUTPUT_AUTOFLUSH',        # SNOOPYJC
                '`'=>"$DEFAULT_MATCH.string[:$DEFAULT_MATCH.start()]",  # SNOOPYJC
                "'"=>"$DEFAULT_MATCH.string[$DEFAULT_MATCH.end():]",    # SNOOPYJC
                '-'=>"$DEFAULT_MATCH.start",    # SNOOPYJC: Needs fixing at end to change [...] to (...)
                '+'=>"$DEFAULT_MATCH.end",      # SNOOPYJC: Needs fixing at end to change [...] to (...)
                '/'=>'INPUT_RECORD_SEPARATOR',','=>'OUTPUT_FIELD_SEPARATOR','\\'=>'OUTPUT_RECORD_SEPARATOR',
                '%'=>'FORMAT_PAGE_NUMBER', '='=>'FORMAT_LINES_PER_PAGE', '~'=>'FORMAT_NAME', '^'=>'FORMAT_TOP_NAME',    # SNOOPYJC
                ':'=>'FORMAT_LINE_BREAK_CHARACTERS',
                '*'=>'MATCH_MULTIPLE_LINES',          # issue s140
                );
   %SPECIAL_VAR2=('O'=>'_os_name',     # SNOOPYJC: was os.name
                  'T'=>'OS_BASETIME', 'V'=>'sys.version[0]', 'X'=>'sys.executable', # $^O and friends
                  'L'=>'FORMAT_FORMFEED',                       # SNOOPYJC
                  'T'=>'BASETIME',                         # SNOOPYJC
                  'F'=>2,                       # SNOOPYJC
                  'W'=>'WARNING');              # SNOOPYJC

   %SPECIAL_VAR_FULL=(TAINT=>'False', SAFE_LOCALES=>'False', UNICODE=>'0', UTF8CACHE=>'True', UTF8LOCALE=>'True');      # issue s23

   %SpecialVarType=('.'=>'I', '?'=>'S', '!'=>'I', '$'=>'I', ';'=>'S', ']'=>'F', 
                    '0'=>'S', '@'=>'S', '"'=>'S', '|'=>'I', '/'=>'m', ','=>'S', # changed '/' to 'm' to distinguish undef from ''
                    '^O'=>'S', '^T'=>'S', '^V'=>'S', '^X'=>'S', '^W'=>'I',
                    '^TAINT'=>'I', '^SAFE_LOCALES'=>'I', '^UNICODE'=>'I', 'UTF8CACHE'=>'I', 'UTF8LOCALE'=>'I',          # issue s23
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
        'grep'=>{list=>'filter', scalar=>'filter_s'},       # issue 37: Note: The "_s" gets removed when emitting the code
        'map'=>{list=>'map', scalar=>'map_s'},          # issue 37: Note: The "_s" gets removed when emitting the code
        'keys'=>{list=>'.keys()', scalar=>'.keys()_s'},     # issue s3: Note: The "_s" gets removed when emitting the code
        'values'=>{list=>'.values()', scalar=>'.values()_s'},   # issue s3: Note: The "_s" gets removed when emitting the code
                'chomp'=>{list=>'.rstrip("\n")', scalar=>'.rstrip("\n")_s'}, # issue s48: Note: The "_s" gets removed when emitting the code
                'chop'=>{list=>'[0:-1]', scalar=>'[0:-1]_s'},           # issue s48: Note: The "_s" gets removed when emitting the code
                'split'=>{list=>'_split', scalar=>'_split_s'},          # issue s52
                'readdir'=>{list=>'_readdirs', scalar=>'_readdir'},     # issue s40
                'readline'=>{list=>'.readlines()', scalar=>'_readline_full'},  # issue s40
                'caller'=>{list=>'_caller', scalar=>'_caller_s'},       # issue s177
                );

   %SPECIAL_FUNCTION_TYPES=('tm_py.ctime'=>'I?:S', '_cgtime'=>'I?:S', '_splice_s'=>'aI?I?a?:s',
                            '.keys()_s'=>'h:I', '.values()_s'=>'h:I',           # issue s3
                            '_readdir'=>'H:S', '_readline_full'=>'H:S',         # issue s40
                            '.rstrip("\n")_s'=>'S:m', '[0:-1]_s'=>'S:m',        # issue s48
                            '_split_s'=>'S?S?I?:I',                             # issue s52, issue s246: Add the '?' to everything
                            '_reverse_scalar'=>'a of S?:S',     # test reverse
                            # issue s153 'filter_s'=>'Sa:I', 
                            'filter_s'=>'sa:I',         # issue s153
                            'caller_s'=>'I?:m',         # issue s177
                            'map_s'=>'fa:I');

   # issue s40:
   # From the documentation: If the condition expression of a while statement is 
   # based on any of a group of iterative expression types then it gets some magic 
   # treatment. The affected iterative expression types are readline, the <FILEHANDLE>
   # input operator, readdir, glob, the <PATTERN> globbing operator, and each. If the
   # condition expression is one of these expression types, then the value yielded by
   # the iterative operator will be implicitly assigned to $_. If the condition
   # expression is one of these expression types or an explicit assignment of one of
   # them to a scalar, then the condition actually tests for definedness of the
   # expression's value, not for its regular truth value.                     
   %WHILE_MAGIC_FUNCTIONS=('glob'=>1, 'readline'=>1, 'readdir'=>1,
                          # this one causes problems: 'each'=>1, 
                          );            # issue s40

   %keyword_tr=('eq'=>'==','ne'=>'!=','lt'=>'<','gt'=>'>','le'=>'<=','ge'=>'>=',
                'and'=>'and','or'=>'or','not'=>'not',
                'x'=>' * ',
                'abs'=>'abs',                           # SNOOPYJC
                'alarm'=>'signal.alarm',                # issue 81
        'assert'=>'assert',         # SNOOPYJC
        'atan2'=>'math.atan2',          # SNOOPYJC
        'basename'=>'_basename',        # SNOOPYJC
                'binmode'=>'_dup',                      # SNOOPYJC
                'bless'=>'_bless','BEGIN'=>'for _ in range(1):',        # SNOOPYJC, issue s12
                'UNITCHECK'=>'for _ in range(1):', 'CHECK'=>'for _ in range(1):', 'INIT'=>'for _ in range(1):',       # SNOOPYJC, issue s12
                # SNOOPYJC 'caller'=>q(['implementable_via_inspect',__file__,sys._getframe().f_lineno]),
                'caller'=>'_caller',            # issue s195
        # issue 54 'chdir'=>'.os.chdir','chmod'=>'.os.chmod',
                'carp'=>'_carp', 'confess'=>'_confess', 'croak'=>'_croak', 'cluck'=>'_cluck',   # SNOOPYJC
                'longmess'=>'_longmess', 'shortmess'=>'_shortmess',                             # SNOOPYJC
        'chdir'=>'_chdir','chmod'=>'_chmod',    # issue 54
        'chomp'=>'.rstrip("\n")','chop'=>'[0:-1]','chr'=>'chr',
        # issue close 'close'=>'.f.close',
        'close'=>'_close_', # issue close, issue 72, issue test coverage
                'cmp'=>'_cmp',                          # SNOOPYJC
                'cos'=>'math.cos',                      # issue s3
                # issue 42 'die'=>'sys.exit', 
                'die'=>'raise Die',     # issue 42
                'dirname'=>'_dirname',          # SNOOPYJC
                'defined'=>'unknown', 'delete'=>'.pop(','defined'=>'perl_defined',
                'each'=>'_each',                        # SNOOPYJC
                'END'=>'_END_',                      # SNOOPYJC
                'exp'=>'math.exp',                      # issue s3
                '__expand'=>"$DEFAULT_MATCH.expand",    # issue s131
                'for'=>'for','foreach'=>'for',          # SNOOPYJC: remove space from each
                'else'=>'else: ','elsif'=>'elif ',
                # issue 42 'eval'=>'NoTrans!', 
                'eval'=>'try',  # issue 42
                'exec'=>'_exec',    # issue s247
                'exit'=>'sys.exit','exists'=> 'in', # if  key in dictionary 'exists'=>'.has_key'
                'fc'=>'.casefold()',                    # SNOOPYJC
        'flock'=>'_flock',          # issue flock
                'fileno'=>'_fileno',                    # SNOOPYJC
                'fileparse'=>'_fileparse',              # SNOOPYJC
                'fork'=>'os.fork',                      # SNOOPYJC
        'glob'=>'glob.glob',            # SNOOPYJC
                'hex'=>'int',                           # SNOOPYJC
                'if'=>'if ', 'index'=>'.find',
        'int'=>'_int',              # issue int
                'isa'=>'_isa',                          # issue s54
                'getopt'=>'getopt', 'getopts'=>'getopt',    # issue s67
        'GetOptions'=>'argparse',       # issue 48
        'gmtime'=>'_gmtime',            # issue times
                'grep'=>'filter', 'goto'=>'goto', 'getcwd'=>'os.getcwd',
                'join'=>'.join(',
        # issue 33 'keys'=>'.keys',
                'keys'=>'.keys()',  # issue 33
                'kill'=>'_kill',      # SNOOPYJC
                'last'=>'break', 'local'=>'', 'lc'=>'.lower()', 
                'lcfirst'=>'_lcfirst',          # SNOOPYJC
                'length'=>'lens',               # SNOOPYJC
        # issue localtime 'localtime'=>'.localtime',
        'localtime'=>'_localtime',      # issue times
                'log'=>'math.log',              # issue s3
                'lstat'=>'_lstat',              # SNOOPYJC
                'map'=>'map', 
                # issue mkdir 'mkdir'=>'os.mkdir', 
                'mkdir'=>'_mkdir',              # issue mkdir
                'my'=>'',
                'next'=>'continue', 
                # SNOOPYJC 'no'=>'NoTrans!',
                'no'=>'import',         # SNOOPYJC: for "no autovivification;";
                # SNOOPYJC 'own'=>'global', 
                # SNOOPYJC 'oct'=>'oct', 
                'oct'=>'int',           # SNOOPYJC: oct is the reverse in python!
                'ord'=>'ord',
                'our'=>'',                      # SNOOPYJC
                'pack'=>'_pack',                # SNOOPYJC
                'package'=>'package', 'pop'=>'.pop()', 'push'=>'.extend(',
                'pos'=>'pos',                   # SNOOPYJC
                # SNOOPYJC 'printf'=>'print',
                'printf'=>'printf',             # SNOOPYJC: Don't have the same python name for both print and printf so PyFuncType is distinct
                'quotemeta'=>'_quotemeta',      # SNOOPYJC, issue s28
                'rename'=>'os.replace',         # SNOOPYJC
                'say'=>'print','scalar'=>'len', 'shift'=>'.pop(0)', 
                'sin'=>'math.sin',              # issue s3
                'splice'=>'_splice',            # issue splice
                # SNOOPYJC 'split'=>'re.split', 
                'split'=>'_split',      # SNOOPYJC perl split has different semantics on empty matches at the end
                'seek'=>'_seek',                # SNOOPYJC
        # issue 34 'sort'=>'sort', 
                'sleep'=>'tm_py.sleep',         # SNOOPYJC
                'sqrt'=>'math.sqrt',        # SNOOPYJC
                'sort'=>'sorted',       # issue 34
                'state'=>'global',
                'rand'=>'_rand',                # SNOOPYJC
                'read'=>'.read',                # issue 10
                'readlink'=>'_readlink',        # issue s128
                   'stat'=>'_stat','sysread'=>'.sysread',
                   'substr'=>'_substr','sub'=>'def','STDERR'=>'sys.stderr','STDIN'=>'sys.stdin',        # issue bootstrap
                   # SNOOPYJC 'system'=>'os.system',
                   'system'=>'_system',         # SNOOPYJC
                   'sprintf'=>'_sprintf',
                   'STDOUT'=>'sys.stdout',  # issue 10
                   # SNOOPYJC 'sysseek'=>'perl_sysseek',
                   'sysseek'=>'_sysseek',       # SNOOPYJC
                   'STDERR'=>'sys.stderr','STDIN'=>'sys.stdin', '__LINE__' =>'sys._getframe().f_lineno',
                   '__FILE__'=>'__file__',      # SNOOPYJC
                   '__SUB__'=>'_sub',           # SNOOPYJC
                'reverse'=>'[::-1]',            # issue 65
                'rindex'=>'.rfind', 
                # SNOOPYJC 'ref'=>'type', 
                'ref'=>'_ref',                  # SNOOPYJC
                # SNOOPYJC 'require'=>'NoTrans!', 
            'opendir'=>'_opendir', 'closedir'=>'_closedir', 
                'readdir'=>'_readdirs',                 # issue s40: Start with the list version
                'seekdir'=>'_seekdir', 'telldir'=>'_telldir', 'rewinddir'=>'_rewinddir',    # SNOOPYJC
                'readline'=>'.readlines()',     # issue s40
                'redo'=>'continue',             # SNOOPYJC
                'require'=>'__import__',        # SNOOPYJC
                'return'=>'return', 'rmdir'=>'_rmdir',
                'tell'=>'_tell',                # SNOOPYJC
                # issue s154 'tie'=>'NoTrans!',
        'time'=>'_time',        # SNOOPYJC
        'timelocal'=>'_timelocal',  # issue times
                'timegm'=>'_timegm',            # issue times
                'truncate'=>'_truncate',        # SNOOPYJC
                'uc'=>'.upper()', 
                # issue s28 'ucfirst'=>'.capitalize()',
                'ucfirst'=>'_ucfirst',          # issue s28
                'undef'=>'None', 'unless'=>'if not ', 
                # issue s94 'unlink'=>'os.unlink',
                'unlink'=>'_unlink',        # issue s94
                'umask'=>'os.umask',            # SNOOPYJC
                   'unshift'=>'.insert(0,',
                   # SNOOPYJC 'use'=>'NoTrans!', 
                   'use'=>'import',
                'unpack'=>'_unpack',    # SNOOPYJC
                   'until'=>'while not ',
                   # issue s154 'untie'=>'NoTrans!',
                   'utime'=>'_utime',   # issue s32
                'values'=>'.values()',  # SNOOPYJC
                # issue s101 'warn'=>'print',
                 'warn'=>'wprint',      # issue s101: problem with PyFuncType clash - wprint isn't actually called
                 'wait'=>'_wait',       # SNOOPYJC
                 'waitpid'=>'_waitpid',         # SNOOPYJC
                 'xor'=>'_logical_xor',         # issue s237
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
       # p => => Pattern match like =~ or !~ (issue s151: distinguish ~ from p)
       # q => Pattern like  m/.../, s/../.../, tr/../../, or wr, or /.../
       # r => range (..)
       # s => Scalar like $var
       # t => Variable type like local, my, own, state
       # u, v, w
       # x => Executable in `...` or qx
       # y => Extra python code we need to generate as is (used in multi_subscripts)
       # z
       # A => => (arrow)
       # B
       # C => More control like default, else, elsif
       # D => -> (dot in python)
       # E
       # F => Named Unary Operators (not generated, but used in calls to next_lower_or_equal_precedent_token)
       # G => TypeGlob *name
       # H => Here doc <<
       # I => >>
       # J, K, L, 
       # M => ~~ (smartMatch)
       # N, O
       # P => :: (package reference)
       # Q..V
       # W => Context manager (with)
       # X..Z
       # 0 => &&, ||
       # ^ => ++ or --
       # > => comparison like > < >= <= == eq ne lt gt le ge
       # = => assignment like = += -= etc
       # ? => ? (part of ? : )
       # : => :
       # . => . or ::
       # * => *, **, or x
       # ! => !
       # +, -, /, % => Operators
       # ~ => ~ (issue s151)
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
                        '!'=>21, '\\'=>21, '~'=>21,     # issue s151
            # 20      left        p           =~ !~
                        'p'=>20,                        # issue s151
            # 19      left        */%         * / % x
                        '*'=>19, '/'=>19, '%'=>19,
            # 18      left        +-.         + - .
                        '+'=>18, '-'=>18, '.'=>18,
            # 17      left        HI          << >>
                        H=>17, I=>17,
            # 16      nonassoc    f           named unary operators
                        F=>16,      # Used in a call to next_lower_or_equal_precedent_token; issue s190: also used for weak functions
            # 15      nonassoc    N/A         isa
            # 14      chained     >           < > <= >= lt gt le ge
                        '>'=>14,
            # 13      chain/na    >           == != eq ne <=> cmp ~~
                        'M'=>13,              # issue s251
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
          'qw'=>'q',        # issue 44
          'wr'=>'q','qx'=>'q','m'=>'q','s'=>'q','tr'=>'q',
                  # issue 93 'and'=>'0',
                  'and'=>'o',           # issue 93
          'abs'=>'f',           # SNOOPYJC
                  'alarm'=>'f',         # issue 81
          'assert'=>'c',    # SNOOPYJC
          'atan2'=>'f',     # SNOOPYJC
          'autoflush'=>'f', # SNOOPYJC
          'basename'=>'f',  # SNOOPYJC
          'binmode'=>'f',   # SNOOPYJC
                  'bless'=>'f',         # SNOOPYJC
                  'break'=>'k',         # issue s129
                  'caller'=>'f','chdir'=>'f','chomp'=>'f', 'chop'=>'f', 'chmod'=>'f','chr'=>'f','close'=>'f',
                  'chop_'=>'f', 'chomp_'=>'f',              # issue s148
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
                  'exec'=>'f',          # issue s247
                  '__expand'=>'f',      # issue s131
                  'exp'=>'f',           # issue s3
                  'eval'=>'C',          # issue 42
                  'fc'=>'f',            # SNOOPYJC
                  'fileno'=>'f',        # SNOOPYJC
                  'fileparse'=>'f',     # SNOOPYJC
                  'flock'=>'f',     # issue flock
                  'fork'=>'f',      # SNOOPYJC
                  'glob'=>'f',      # SNOOPYJC
                  'if'=>'c',  'index'=>'f',
                  'int'=>'f',       # issue int
                  'isa'=>'f',           # issue s54
                  'for'=>'c', 'foreach'=>'c',
                  'getopt'=>'f', 'getopts'=>'f',    # issue s67
                  'GetOptions'=>'f',    # issue 48
                  'goto'=>'k',          # SNOOPYJC
                  'given'=>'c','grep'=>'f',
                  'hex'=>'f',           # SNOOPYJC
                  'join'=>'f',
                  'keys'=>'f',
                  'kill'=>'f',          # SNOOPYJC
                  'last'=>'k', 'lc'=>'f', 'length'=>'f', 'local'=>'t', 'localtime'=>'f',
                  'lcfirst'=>'f',       # SNOOPYJC
                  'log'=>'f',           # issue s3
                  'lstat'=>'f',
                  'my'=>'t', 'map'=>'f', 'mkdir'=>'f',
                  'next'=>'k','not'=>'!',
                  'no'=>'k',                    # SNOOPYJC
                  'our'=>'t',                   # SNOOPYJC
                  # issue 93 'or'=>'0', 
                  'or'=>'o',                    # issue 93
                  # SNOOPYJC 'own'=>'t', 
                  'oct'=>'f', 'ord'=>'f', 'open'=>'f',
                  'opendir'=>'f', 'closedir'=>'f', 'readdir'=>'f', 'seekdir'=>'f', 'telldir'=>'f', 'rewinddir'=>'f',    # SNOOPYJC
                  'readline'=>'f',      # issue s40
                  'push'=>'f', 'pop'=>'f', 'print'=>'f', 'package'=>'c',
                  'pack'=>'f',
                  'pos'=>'f',                   # SNOOPYJC
                  'printf'=>'f',                # SNOOPYJC
                  'quotemeta'=>'f',             # SNOOPYJC
                  'rand'=>'f',                  # SNOOPYJC
                  'redo'=>'k',                  # SNOOPYJC
                  'require'=>'k',               # SNOOPYJC
                  'rindex'=>'f','read'=>'f', 
                  'readlink'=>'f',              # issue s128
                  'rename'=>'f',                # SNOOPYJC
                  # issue 61 'return'=>'f', 
                  'return'=>'k',        # issue 61
                  'reverse'=>'f',               # issue 65
                  'ref'=>'f',
                  'rmdir'=>'f',         # SNOOPYJC
                  'say'=>'f','scalar'=>'f','shift'=>'f', 
                  'select'=>'f',        # SNOOPYJC
                  'sin'=>'f',           # issue s3
                  'splice'=>'f',                # issue splice
                  'split'=>'f', 'sprintf'=>'f', 'sort'=>'f','system'=>'f', 'state'=>'t',
                  'seek'=>'f',          # SNOOPYJC
                  'sleep'=>'f',     # SNOOPYJC
                  'sqrt'=>'f',      # SNOOPYJC
                  'stat'=>'f','sub'=>'k','substr'=>'f','sysread'=>'f',  'sysseek'=>'f',
                  'stat_cando'=>'f',
                  'tell'=>'f',          # SNOOPYJC
                  'tie'=>'f',
                  'tied'=>'f',          # issue s154
                  'time'=>'f', 'gmtime'=>'f', 'timelocal'=>'f', 'timegm'=> 'f', # SNOOPYJC
                  'truncate'=>'f',              # SNOOPYJC
                  'unlink'=>'f',        # SNOOPYJC
                  'unpack'=>'f',                # SNOOPYJC
                  'use'=>'k',                   # SNOOPYJC
                  'values'=>'f',
                  'warn'=>'f', 
                  'when'=>'c',                  # issue s129
                  'while'=>'c',
                  'undef'=>'f', 'unless'=>'c', 'unshift'=>'f','until'=>'c','uc'=>'f', 'ucfirst'=>'f',
                  # SNOOPYJC 'use'=>'c',
                  'untie'=>'f',
                  'umask'=>'f',                  # SNOOPYJC
                  'utime'=>'f',                  # issue s32
                  'wait'=>'f',                   # SNOOPYJC
                  'waitpid'=>'f',                # SNOOPYJC
                  'wantarray'=>'d',              # SNOOPYJC
                  'xor'=>'o',                    # issue s237
                  '__FILE__'=>'"', '__LINE__'=>'d', '__PACKAGE__'=>'"', '__SUB__'=>'f', # SNOOPYJC
                  );
                      # NB: Use ValPerl[$i] as the key here!
       %FuncType=(    # a=Array, h=Hash, s=Scalar, I=Integer, F=Float, N=Numeric, S=String, u=undef, f=function, H=FileHandle, ?=Optional, m=mixed
                  'tie'=>'mSa?:s', 'untie'=>'m', 'tied'=>'m:s',         # issue s154
                  'chop_'=>':S', 'chomp_'=>':S',                        # issue s148: New postfix versions
                  '_num'=>'m:N', '_int'=>'m:I', '_str'=>'m:S',
                  '_bn'=>'m:s',                                         # issue s117
                  '_pb'=>'B:s',                                         # issue s124
                  '_flt'=>'m:F',                                        # issue s3
                  '_map_int'=>'a:a of I', '_map_num'=>'a:a of N', '_map_str'=>'a:a of S',
                  '_assign_global'=>'SSm:m', '_read'=>'HsII?:s',
                  '_set_breakpoint'=>':u',              # issue s62
                  '__expand'=>'R:S',                    # issue s131
                  'xor' => 'mm:B',                      # issue s237
                  '_logical_xor' => 'mm:B',             # issue s237
                  'exp'=>'F:F', 'log'=>'F:F', 'cos'=>'F:F', 'sin'=>'F:F',       # issue s3
                  '$#'=>'a:I',                                                # issue 119: _last_ndx
                  're'=>':S', 'tr'=>':S',                                         # SNOOPYJC, issue s252: add ':'
                  'abs'=>'N:N', 'alarm'=>'N:N', 'atan2'=>'NN:F', 
                  'autoflush'=>'I?:I', 'basename'=>'S:S', 'binmode'=>'HS?:m',
                  # issue s154 'bless'=>'mS?:m',                      # SNOOPYJC
                  'bless'=>'mm?:m',                      # SNOOPYJC, issue s154: bless function will take a class or instance, not just str
                  'caller'=>'I?:a',
                  'can'=>'mS:m',                # issue s180
                  'carp'=>'a:u', 'confess'=>'a:u', 'croak'=>'a:u', 'cluck'=>'a:u',   # SNOOPYJC
                  'longmess'=>'a:S', 'shortmess'=>'a:S',                             # SNOOPYJC
                  'chdir'=>'S:I',
                  # issue s48 'chomp'=>'S:m', 'chop'=>'S:m', 
                  'chomp'=>'a?:m', 'chop'=>'a?:m',        # issue s48
                  'chmod'=>'Ia:I','chr'=>'I?:S','close'=>'H:I',
                  # issue s238 'cmp'=>'SS:I', 
                  'cmp'=>'mm:I',        # issue s238: Don't convert to str here because it could be an object
                  '<=>'=>'NN:I',
                  '~~'=>'mm:I',         # issue s251
                  'delete'=>'u:a', 'defined'=>'u:I','die'=>'S:m', 'dirname'=>'S:S', 'each'=>'h:a', 'exists'=>'m:I', 
                  # 'exec'=>'s?a:',          # issue s247
                  'exec'=>'a:',          # issue s247
                  'exit'=>'I?:u', 'fc'=>'S:S', 'flock'=>'HI:I', 'fork'=>':m', 'fileno'=>'H:I',
                  'fileparse'=>'Sm?:a of S', 'hex'=>'S?:I', 'GetOptions'=>'a:I',
                  'getopt'=>'a:I', 'getopts'=>'a:I',            # issue s67
                  'glob'=>'S:a of S', 'index'=>'SSI?:I', 'int'=>'s:I', 
                  # issue s153 'grep'=>'Sa:a of S', 
                  'grep'=>'sa:a of S',          # issue s153: Handle grep !/pat/, ...
                  'join'=>'Sa:S', 'keys'=>'h:a of S', 
                  'isa'=>'mS:I',                # issue s54
                  'kill'=>'mI:u', 'lc'=>'S:S', 'lstat'=>'m?:a of I',
                  'lcfirst'=>'S:S',
                  'length'=>'S:I', 'localtime'=>'I?:a of I', 'map'=>'fa:a', 'mkdir'=>'SI?:I', 'oct'=>'S?:I', 'ord'=>'S?:I', 
                  # issue s166 'open'=>'HSS?:I',
                  'open'=>'HSs?:I',     # issue s166: Don't convert the 3rd arg
                  'pack'=>'Sa:S',
                  'opendir'=>'HS:I', 'closedir'=>'H:I', 'readdir'=>'H:a of S', 'rename'=>'SS:I', 'rmdir'=>'S:I',
                  'readline'=>'H:a of S',    # issue s40
                  'seekdir'=>'HI:I', 'telldir'=>'H:I', 'rewinddir'=>'H:m',
                  'push'=>'aa:I', 'pop'=>'a:s', 'pos'=>'s:I', 'print'=>'H?a:I', 'printf'=>'H?S?a:I', 'quotemeta'=>'S?:S', 'rand'=>'F?:F',
                  'rindex'=>'SSI?:I','read'=>'HsII?:I', '.read'=>'HsII?:I', 'reverse'=>'a?:a', 'ref'=>'u:S', 
                  'readlink'=>'S:S',            # issue s128
                  '_refs'=>'u:S',               # issue s3
                  'say'=>'H?a:I',
                  # issue s254 'scalar'=>'a:I',
                  'scalar'=>'m:I',              # issue s254
                  'seek'=>'HII:u', 'shift'=>'a?:s', 'sleep'=>'I:I', 'splice'=>'aI?I?a?:a',
                  'select'=>'H?:H',             # SNOOPYJC
                  # issue s246 'split'=>'SSI?:a of m',
                  'split'=>'S?S?I?:a of m',     # issue s246: add the '?' to everything
                  'sprintf'=>'Sa:S', 'sort'=>'f?a:a','system'=>'a:I',
                  'stat_cando'=>'aII:I',        # issue s33
                  'sqrt'=>'N:F', 'stat'=>'m?:a of I', 'substr'=>'SII?S?:S','sysread'=>'HsII?:I',  'sysseek'=>'HII:I', 'tell'=>'H:I', 'time'=>':I', 'gmtime'=>'I?:a of I', 'timegm'=>'IIIIII:I',
                  'truncate'=>'HI:I', 
                  'utime'=>'a:I',               # issue s32
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

    %PyFuncType=();                     # SNOOPYJC
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
        $PyFuncType{_smartmatch} = $FuncType{'~~'};     # issue s251
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
        $PyFuncType{'_get_element'} = 'mI:m';           # issue s43
        $PyFuncType{'_set_element'} = 'msm:m';           # issue s148: _set_element works on Arrays and Hashes
        $PyFuncType{_flatten} = 'a:a';          # issue s103
        $PyFuncType{_chomp_with_result} = 'm:I';    # issue s167
        $PyFuncType{_chop_with_result} = 'm:S';     # issue s167
        $PyFuncType{_chop_without_result} = 'm:S';     # issue s167
        $PYF_OUT_PARAMETERS{_chomp_with_result} = 1;    # issue s167
        $PYF_OUT_PARAMETERS{_chop_with_result} = 1;    # issue s167
        $PYF_OUT_PARAMETERS{_chop_without_result} = 1;    # issue s167
        $PyFuncType{_fetch_perl_global} = 'S:m';    # issue s176
        $PyFuncType{_store_perl_global} = 'Smm?:m';    # issue s176
        $PYF_OUT_PARAMETERS{_binmode} = 1;          # issue s183
        $PYF_OUT_PARAMETERS{_dup} = 1;              # issue s183
        $PYF_OUT_PARAMETERS{open} = 1;              # issue s183
        $PYF_OUT_PARAMETERS{_open} = 1;             # issue s183
        $PYF_OUT_PARAMETERS{'.read'} = 2;           # issue s183
        $PYF_OUT_PARAMETERS{'.sysread'} = 2;        # issue s183
        $PYF_OUT_PARAMETERS{'.rstrip("\n")'} = 1;   # issue s183: chomp
        $PYF_OUT_PARAMETERS{'[0:-1]'} = 1;          # issue s183: chop
        $PyFuncType{_store_out_parameter} = 'aImm?:m';   # issue s184
        $PyFuncType{_fetch_out_parameter} = 'I:m';   # issue s184
        $PyFuncType{_fetch_out_parameters} = 'mI?:m';   # issue s184
        $PyFuncType{_init_out_parameters} = 'aa:';   # issue s184
        $PyFuncType{setattr} = 'mSm:';              # issue s214
        $PyFuncType{_get_subref} = 'm:m';           # issue s229
        $PyFuncType{_method_call} = 'mSa?:m';       # issue s236
        $PyFuncType{_raise} = 'm:';
        $PyFuncType{lena} = 'a:I';                  # issue s254: We put in this version of 'scalar' if they use a goatse to make sure the arg is in list context

        for my $d (keys %DASH_X) {
            if($d =~ /[sMAC]/) {            # issue s124
                $FuncType{"-$d"} = 'm:I';
                $PyFuncType{$DASH_X{$d}} = 'm:I';
            } else {                        # issue s124
                $FuncType{"-$d"} = 'm:B';       # issue s124: They now return boolean
                $PyFuncType{$DASH_X{$d}} = 'm:B';   # issue s124
            }
        }

        for my $pkg (keys %PREDEFINED_PACKAGES) {       # See Pyconfig.pm
            # test overload methods $BUILTIN_LIBRARY_SET{$pkg} = 1;
            #$BUILTIN_LIBRARY_SET{$pkg} = 1 unless $pkg eq 'overload';   # test overload methods
            $BUILTIN_LIBRARY_SET{$pkg} = 1;
            for my $func_info (@{$PREDEFINED_PACKAGES{$pkg}}) {
                if(exists $func_info->{import_it}) {        # Needed for Time::HiRes (and overload)
                    delete $BUILTIN_LIBRARY_SET{$pkg};
                    next;
                }
                my $perl = $func_info->{perl};
                my $type = $func_info->{type};
                my $python = "_$perl";
                $python = $func_info->{python} if(exists $func_info->{python});
                if(exists $func_info->{calls}) {
                    $PYF_CALLS{$python} = $func_info->{calls};
                }
                if(exists $func_info->{out_parameter}) {
                    $PYF_OUT_PARAMETERS{$python} = $func_info->{out_parameter};
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
                    # issue s190 $TokenType{$perl} = 'f';
                    $TokenType{$perl} = 'F';    # issue s190: 'F' is a weak function, in other words, if there is a local sub of the same name it overrides it
                    if (exists $keyword_tr{$perl}) { # test_Time_HiRes: We will override this if the user imports the method
                        # NOTE: $::debug hasn't been set yet!!
                        #say STDERR "Found existing definition for $perl as $keyword_tr{$perl} as we're trying to set it to $python";
                        if($keyword_tr{$perl} ne $python) {
                            #say STDERR "Not overriding built-in $perl ($keyword_tr{$perl}) for new definition in $pkg ($python) unless it's imported";
                            ;
                        }
                    } else {
                        $keyword_tr{$perl} = $python;
                    }
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
                   # issue s151 '=~'=>'~','!~'=>'~',
                   '=~'=>'p','!~'=>'p',                     # issue s151
                   '=='=>'>', '!='=>'>', '>='=>'>', '<='=>'>', # comparison
                   '~~'=>'M',                               # issue s251
                   '=>'=>'A', '->'=>'D',                        # issue 93
                   '<<' => 'H', '>>'=>'I', '&&'=>'0', '||'=>'0', # issue 93
                   '*='=>'=', '/='=>'=', '**'=>'*', '::'=>'P' ); # issue 93

   %digram_map=('++'=>'+=1','--'=>'-=1','+='=>'+=', '*='=>'*=', '/='=>'/=', '.='=>'+=', '=~'=>'','<>'=>'readline()','=>'=>': ','->'=>'.',
                '&&'=>' and ', '||'=>' or ',
                # SNOOPYJC '::'=>'.',
                '::'=>'.__dict__',               # SNOOPYJC
                '~~'=>'_smartmatch',            # issue s251
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
@BufferValType=();      # issue 37
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
sub TRY_BLOCK_CONTINUE_NEEDED_ONE { 64 } # The 'continue' needed to use a try block: issue s49
sub TRY_BLOCK_FOREACH      { 128 }      # issue s100: used on foreach loop that needs a local var
$statement_starting_lno = 0;            # issue 116
%line_contains_stmt_modifier=();        # issue 116
%line_contains_for_loop_with_modified_counter=();       # SNOOPYJC
%line_modifies_foreach_counter=();      # issue s252: lno=>foreach_loop_lno
%line_contains_local_for_loop_counter=();   # issue s100
%line_contains_pos_gen=();      # SNOOPYJC: {lno=>scalar, ...} on any stmt that can generate the pos of this scalar
%line_contains_for_given=();    # issue s129: Is this 'for' really a 'given'?
# issue s224 %line_contained_array_conversion=();    # issue s137
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
$add_comma_after_anon_sub_end = 0;      # issue s39: Insert a ',' after the end of the anon sub we added
$last_expression_lno = 0;   # issue implicit conditional return
$last_expression_level = -1;    # issue implicit conditional return
%level_block_lnos = ();       # {level=>0 -or- "lno,..."} issue implicit conditional return
%sub_lines_contain_potential_last_expression=(); # {'sub_name'=>'lno,...', ...} issue implicit conditional return

sub initialize                  # issue 94
{
    $nesting_level = 0;
    @nesting_stack = ();
    $last_label = undef;
    $last_block_lno=0;
    $ate_dollar = -1;
    $nesting_last=undef;            # issue 94: Last thing we popped off the stack
    $add_comma_after_anon_sub_end = 0;  # issue s39
    $last_expression_lno = 0;   # issue implicit conditional return
    $last_expression_level = -1;    # issue implicit conditional return
    %level_block_lnos = ();       # issue implicit conditional return
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
    if($ValPy[$tno] =~ /^\(len\((.*)\)-1\)$/) {     # for $#arr
        my $id = $1;
        # issue s102 $id = remap_conflicting_names(unescape_id($id, $name), $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        if($::remap_global && !$::remap_all && $class eq 'global') {
            $id = unescape_id($id, $name);              # issue s102
            $id = remap_conflicting_names($id, $sigil, '', 1);
            $id = escape_keywords($id);                 # issue s102
        }
        $ValPy[$tno] = '(len(' . cur_package() . '.' . $id . ')-1)';
    }elsif($ValPy[$tno] =~ /^len\((.*)\)$/) {       # issue bootstrap: for scalar(@arr)
        my $id = $1;
        # issue s102 $id = remap_conflicting_names(unescape_id($id, $name), $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        if($::remap_global && !$::remap_all && $class eq 'global') {
            $id = unescape_id($id, $name);              # issue s102
            $id = remap_conflicting_names($id, $sigil, '', 1);
            $id = escape_keywords($id);                 # issue s102
        }
        $ValPy[$tno] = 'len(' . cur_package() . '.' . $id . ')';
    }elsif(substr($ValPy[$tno],0,1) eq '*') {           # issue bootstrap: we splatted this reference
        my $id = substr($ValPy[$tno],1);
        # issue s102 $id = remap_conflicting_names(unescape_id($id, $name), $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');
        if($::remap_global && !$::remap_all && $class eq 'global') {
            $id = unescape_id($id, $name);              # issue s102
            $id = remap_conflicting_names($id, $sigil, '', 1);
            $id = escape_keywords($id);                 # issue s102
        }
        $ValPy[$tno] = '*' . cur_package() . '.' . $id;     # Add the package name, moving the splat to the front
    } else {
        my $id = $ValPy[$tno];
        # issue s102 $id = remap_conflicting_names(unescape_id($id, $name), $sigil, '', 1) if($::remap_global && !$::remap_all && $class eq 'global');   # issue s102
        if($::remap_global && !$::remap_all && $class eq 'global') {
            $id = unescape_id($id, $name);              # issue s102
            $id = remap_conflicting_names($id, $sigil, '', 1);
            $id = escape_keywords($id);                 # issue s102
        }
        $ValPy[$tno] = cur_package() . '.' . $id;         # Add the package name
    }
    say STDERR "Changed $py to $ValPy[$tno] for global" if($::debug >= 5);
}

sub unescape_id             # issue s102
# given an escaped name like bytes_, remove the '_'
# given a mapped name like bytes_v, remove the '_v' too
{
    my $id = shift;
    my $perl_name = shift;

    return $id if substr($perl_name, -1, 1) eq '_';
    return substr($id, 0, length($id)-1) if substr($id, -1, 1) eq '_';
    return $id if substr($perl_name, -2, 2) =~ /^_[a-z]$/ && substr($perl_name, -1, 1) eq substr($id, -1, 1);
    return substr($id, 0, length($id)-2) if substr($id, -2, 2) =~ /^_[a-z]$/;
    return $id;
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
    # issue s241  $Pythonizer::SubAttributes{$ValPy[$tno]} = $Pythonizer::SubAttributes{$py} if exists $Pythonizer::SubAttributes{$py};         # issue s3
    &Pythonizer::clone_sub_attributes($py, $ValPy[$tno]);         # issue s3, issue s241
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
    my $name = '*' . $perl_name;        # TypeGlob, e.g. local *FH;
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
        $name = '*' . $name;    # TypeGlob
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
        if(substr($name,0,2) eq '$#') {         # issue s222: Handle $#$name and $#{$name}
            $name = '$' . substr($name,2);      # issue s222
        }                                       # issue s222
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

sub restore_cur_raw_package     # issue s155
# If we define a package in a block, set it back to what it was after the block
# Arg = what it was
{
    my $package = shift;
    if($Pythonizer::PassNo == &Pythonizer::PASS_2) {
        $::CurPackage = $package;
        gen_statement("builtins.__PACKAGE__ = '$package'");
    } else {
        for(my $i = 0; $i < @Pythonizer::Packages; $i++) {
            if($Pythonizer::Packages[$i] eq $package) {
                $#Pythonizer::Packages = $i;
                last;
            }
        }
    }
}

sub cur_raw_package         # issue s155
# Get the current package name w/o it being escaped
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
    return $result;
}

sub cur_package
# Get the current package name and escape it if it conflicts with a python reserved or special name
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
    # issue s100 $class = 'myfile' if($::implicit_global_my);   # issue s100
    $class = 'implicit_myfile' if($::implicit_global_my);   # issue s100
    # issue s83 $class = 'myfile' if($ValPerl[$tno] =~ /^\$[ab]$/);  # Sort vars
    $class = 'myfile' if($name =~ /^\$[ab]$/);  # issue s83: Sort vars
    $TokenStr=join('',@ValClass);
    my $declared_here = 0;
    # issue s144 if($ValClass[0] eq 't' && index($TokenStr,'=') < 0) {           # We are declaring this var
    my $peq;                # issue s144
    if($ValClass[0] eq 't' && (($peq = index($TokenStr,'=')) < 0 || $tno < $peq)) { # We are declaring this var, issue s144
        $class = $ValPerl[0];
        # issue s83 $class = 'myfile' if($class eq 'my' && !in_sub());
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
    my $cs = cur_sub();                 # issue s252
    $class = 'myfile' if($class eq 'my' && !in_sub());          # issue s83
    $class = 'global' if($class eq 'my' && special_code_block_name($cs)); # issue s155, issue s252
    $class = 'myfile' if($class eq 'local' && !@nesting_stack); # 'local' at outer scope is same as 'my'
    $class = 'my' if(scalar(@ValType) > $tno && $ValType[$tno] eq 'X');        # issue s79: Special variable like @_, @INC, @ENV should not be declared "global"
    if(exists $::aliased_foreach_subs{$cs} && $::aliased_foreach_subs{$cs} eq $name && $::nested_subs{$cs} ne '') { # issue s252
        $class = 'my';      # issue s252
        $declared_here = 1; # issue s252: It's the arg to our sub
    }                       # issue s252
    if($class eq 'our') {
        if($::implicit_global_my) {
            # issue s100 $class = 'myfile' 
            $class = 'implicit_myfile'      # issue s100
        } else {
            $class = 'global' 
        }
    }
    if($last_varclass_lno != $. && $last_varclass_lno) {
    say STDERR "Setting line_varclasses{$.} as a clone of line $last_varclass_lno" if($::debug >= 5);
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
    }
    $last_varclass_lno = $.;
    # issue s252 my $cs = cur_sub();
    if(!exists $line_varclasses{$last_varclass_lno}{$name} || $class eq 'my' || $class eq 'local'
       || $class eq 'state'                 # issue s144
       || (($class eq 'myfile' || $class eq 'implicit_myfile') && $declared_here)) {         # issue s83, issue s100
        my $cls = $class;
        if(!exists $last_varclass_sub{$name} || $last_varclass_sub{$name} ne $cs) {
            $cls = map_var_class_into_sub($class) if(!$declared_here);
            $last_varclass_sub{$name} = $cs;
        }
        $line_varclasses{$last_varclass_lno}{$name} = $class;
        #say STDERR "Setting sub_varclasses{$cs}{$name} = $cls for line $. (1)";
        $sub_varclasses{$cs}{$name} = $cls;
        $Pythonizer::VarSubMap{$ValPy[$tno]}{$cs} = '+' if($cls eq 'global');           # issue s79: If we're in an inner sub, this will propagate the 'global' to the outer one
    } elsif(exists $line_varclasses{$last_varclass_lno}{$name}) {
        $class = $line_varclasses{$last_varclass_lno}{$name};
        my $cls = $class;
        if(!exists $last_varclass_sub{$name} || $last_varclass_sub{$name} ne $cs) {
            $cls = map_var_class_into_sub($class) if(!$declared_here);
            $last_varclass_sub{$name} = $cs;
            #say STDERR "Setting sub_varclasses{$cs}{$name} = $cls for line $. (2)";
            $sub_varclasses{$cs}{$name} = $cls;
            $Pythonizer::VarSubMap{$ValPy[$tno]}{$cs} = '+' if($cls eq 'global');       # issue s79: If we're in an inner sub, this will propagate the 'global' to the outer one
        }
    }
    if($statement_starting_lno != $.) {                                         # issue s108: make first line the same as the last line of stmt
        $line_varclasses{$statement_starting_lno} = $line_varclasses{$.};       # issue s108
    }                                                                           # issue s108
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

sub capture_statement_starting_varclasses       # issue s110
# Capture the current varclasses and associate it with the start of the statement.
# We do this by adding an 's' to the end of the statement starting line number
{
    if($last_varclass_lno != $. && $last_varclass_lno) {
        $line_varclasses{$statement_starting_lno . 's'} = $line_varclasses{$last_varclass_lno};
    } else {
        $line_varclasses{$statement_starting_lno . 's'} = {};
    }
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

sub clone_line_varclasses
# For insertion of a return statement, just propagate the varclass from the prior line
{
    my $force = shift;                              # issue s79: should we force a clone even if we have one defined?
    if(!$force && exists $line_varclasses{$.}) {    # issue s79
        say STDERR "clone_line_varclasses: didn't clone line $. as it already has line_varclasses defined" if($::debug);    # issue s79
        return;                                     # issue s79
    }                                               # issue s79
    for(my $lno = $. - 1; $lno; $lno--) {
        if(exists $line_varclasses{$lno}) {
            $line_varclasses{$.} = dclone($line_varclasses{$lno});
            say STDERR "clone_line_varclasses: cloning line $. from line $lno" if($::debug);
            return;
        }
    }
    say STDERR "clone_line_varclasses: didn't find anything to clone from line $." if($::debug);
}

sub map_var_class_into_sub
# For a sub, map the class of the incoming (non-arg) variable
{
    my $cls = shift;
    $cls = 'nonlocal' if($cls eq 'my');
    $cls = 'package' if($cls eq 'global');
    # issue s100 $cls = 'global' if($cls eq 'myfile');
    $cls = 'global' if($cls eq 'myfile' || $cls eq 'implicit_myfile');  # issue s100
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
    # issue s127 for my $perl_name (keys %{$sub_varclasses{$sub}}) {
    for my $perl_name (sort keys %{$sub_varclasses{$sub}}) {    # issue s127
        if(($sub_varclasses{$sub}{$perl_name} eq $class && (($class ne 'global' || !template_var($perl_name))) ||    # issue s76
           ($class eq 'nonlocal' && template_var($perl_name)))) {                                                    # issue s76
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
    return escape_keywords($NameMap{$name}{$sigil});        # issue s176
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
    return 1 if($top->{cur_sub} =~ /^$ANONYMOUS_SUB\d+[a-z]?$/);        # issue s26
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

sub get_loop_ctr        # SNOOPYJC
{
    return undef if(!@nesting_stack);
    $top = $nesting_stack[-1];
    if(defined $top->{loop_ctr}) {
        my $cs = cur_sub();                 # issue s252
        if(exists $::aliased_foreach_subs{$cs}) {   # issue s252
            return join(',', ($top->{loop_ctr}, $::aliased_foreach_subs{$cs})); # issue s252
        }                                   # issue s252
        return $top->{loop_ctr};
    }
    my $cs = cur_sub();                         # issue s252
    if(exists $::aliased_foreach_subs{$cs}) {   # issue s252
        return $::aliased_foreach_subs{$cs};    # issue s252
    }                                           # issue s252
    return undef;
}

sub loop_ctr_type        # issue s252
# Get the type of this loop counter - call from a statement inside the loop
{
    my ($perl, $py) = @_;

    for(my $i = $#nesting_stack; $i >= 0; $i--) {
        if(($nesting_stack[$i]->{type} eq 'for' || $nesting_stack[$i]->{type} eq 'foreach') && 
            exists($nesting_stack[$i]->{loop_ctr}) && index($nesting_stack[$i]->{loop_ctr}, $perl) == 0) {
            if(exists $line_contains_local_for_loop_counter{$nesting_stack[$i]->{lno}} &&
               exists $line_contains_local_for_loop_counter{$nesting_stack[$i]->{lno}}{$py}) {
               return $line_contains_local_for_loop_counter{$nesting_stack[$i]->{lno}}{$py};
            }
       }
    }
    return '';
}

sub is_loop_ctr         # issue s252
# Is this ValPerl the loop counter?
{
    my $arg = $_[0];

    my $lc = get_loop_ctr();
    if(!defined $lc && $arg eq '$_') {
        for(my $k = 1; $k <= $#ValClass; $k++) {
            return 1 if($ValClass[$k] eq 'c' && $ValPy[$k] eq 'for');   # e.g. ... for(@array);
        }
    }
    return '' unless defined $lc;
    my @lcs = split(/,/, $lc);
    say STDERR "is_loop_ctr($arg) - checking $lc" if($::debug >= 5);
    for $lc (@lcs) {
        return 1 if($arg eq $lc);
    }
    return '';
}

sub set_loop_ctr_mod        # SNOOPYJC
# Set that the loop counter is modified in the loop
{
    my $lc_name = shift;

    for(my $i = $#nesting_stack; $i >= 0; $i--) {
        if($nesting_stack[$i]->{type} eq 'for' && exists($nesting_stack[$i]->{loop_ctr}) && index($nesting_stack[$i]->{loop_ctr}, $lc_name) == 0) {
            say STDERR "set_loop_ctr_mod: setting line_contains_for_loop_with_modified_counter{$nesting_stack[$i]->{lno}} from assignment to $lc_name in line $." if($::debug >= 5);
            $line_contains_for_loop_with_modified_counter{$nesting_stack[$i]->{lno}} = $lc_name;
            return;
        } elsif($nesting_stack[$i]->{type} eq 'foreach' && exists($nesting_stack[$i]->{loop_ctr}) && index($nesting_stack[$i]->{loop_ctr}, $lc_name) == 0) {  # issue s252
            say STDERR "set_loop_ctr_mod: 'foreach': setting line_contains_for_loop_with_modified_counter{$nesting_stack[$i]->{lno}} from assignment to $lc_name in line $." if($::debug >= 5);   # issue s252
            $line_contains_for_loop_with_modified_counter{$nesting_stack[$i]->{lno}} = $lc_name;    # issue s252
            $line_modifies_foreach_counter{$.} = $nesting_stack[$i]->{lno};                         # issue s252
            return;   # issue s252
        }
    }
    if($lc_name eq '$_') {                          # issue s252
        for(my $k = 1; $k <= $#ValClass; $k++) {
            if($ValClass[$k] eq 'c' && $ValPy[$k] eq 'for') {   # e.g. ... for(@array);
                $line_contains_for_loop_with_modified_counter{$.} = $lc_name;    # issue s252
                $line_modifies_foreach_counter{$.} = $.;                         # issue s252
                return;                                     # issue s252
            }
        }
    }
    my $cs = cur_sub();                         # issue s252
    if(exists $::aliased_foreach_subs{$cs} && $cs =~ /^$ANONYMOUS_SUB(\d+)/) {   # issue s252
        my $lno = $1;                           # issue s252
        $line_contains_for_loop_with_modified_counter{$lno} = $lc_name;    # issue s252
        $line_modifies_foreach_counter{$.} = $lno;                         # issue s252
    }
}

sub set_for_given        # issue s129
# Set that this 'for' loop is acting as a 'given'
{
    for(my $i = $#nesting_stack; $i >= 0; $i--) {
        last if $nesting_stack[$i]->{type} eq 'given';
        if($nesting_stack[$i]->{type} eq 'foreach') {
            say STDERR "setting line_contains_for_given{$nesting_stack[$i]->{lno}} from when in line $." if($::debug >= 5);
            $line_contains_for_given{$nesting_stack[$i]->{lno}} = 1;
            $nesting_stack[$i]->{type} = 'given';
            $nesting_stack[$i]->{is_loop} = 0;
            my $in_loop = 0;
            for(my $j = $i-1; $j >= 0; $j--) {      # recompute in_loop
                if($nesting_stack[$j]->{in_loop}) {
                    $in_loop = 1;
                    last;
                }
            }
            $nesting_stack[$i]->{in_loop} = $in_loop;
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
    if($top->{type} eq 'continue') {
        say STDERR "is_continue_block($at_bottom) = 1" if($::debug >= 4);
        return 1;
    }
    say STDERR "is_continue_block($at_bottom) = 0" if($::debug >= 4);
    return 0;
}

sub track_continue
# Track a 'continue' statement as soon as we lex it in the first pass
{
    return unless defined $nesting_last;            # issue s129
    return if in_when();                            # issue s170
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
    if(($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) || $::debug >= 6) {
        no warnings;
        say STDERR "enter_block at line $., prior nesting_level=$nesting_level, Tokenstr |".join('',@ValClass)."|, ValPerl=@ValPerl";
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
    # issue s78: if this is like foreach my $k(sort {...}) and we're at the '{' after the sort, then
    # don't mis-classify this as a loop start bracket
    if($ValClass[-1] eq 'f' && $ValPerl[-1] =~ /sort|map|grep|exec/) {       # issue s78, issue s247: add 'exec'
        $begin = $#ValClass;                            # issue s78
    } elsif ($#ValClass != 0 && $ValClass[-2] eq 'f' && $ValPerl[-2] =~ /sort|map|grep|exec/) {  # issue s78, issue s247: add 'exec'
        $begin = $#ValClass-1;                          # issue s78
    }
    $nesting_info{type} = '';
    $nesting_info{type} = $ValPy[$begin];
    $nesting_info{type} =~ s/:\s*$//;           # Change "else: " to "else"
    $nesting_info{type} = 'if' if($nesting_info{type} eq '{' && $delayed_block_closure); # issue s44: Here it looks like a {...} but it's really an if from bash_style_or_and_fix
    $nesting_info{loop_ctr} = $nesting_stack[-1]{loop_ctr} if(scalar(@nesting_stack) && exists($nesting_stack[-1]{loop_ctr}));
    if($nesting_info{type} eq 'for') {
        $TokenStr=join('',@ValClass);               # issue s100
        my $lcx = index($TokenStr,'s=');
        $lcx = index($TokenStr, 's^') if($lcx < 0);     # Loop for $i++ or $i-- if no loop ctr init
        if($lcx > 0) {
            if(exists $nesting_info{loop_ctr}) {
                $nesting_info{loop_ctr} = $ValPerl[$lcx] . ',' . $nesting_info{loop_ctr};
            } else {
                $nesting_info{loop_ctr} = $ValPerl[$lcx];
            }
        } else {                                # issue s100: Handle for(each) loop also
            $lcx = index($TokenStr, 's');       # issue s100: tokens 'cs' or 'cts'
            if(&Pythonizer::for_loop_uses_default_var(0)) {      # issue s235: Handle $selected{$_}++ for $self->param($name); -or- foreach (@arr)
                if(exists $nesting_info{loop_ctr}) {    # issue s252
                    $nesting_info{loop_ctr} = '$_' . ',' . $nesting_info{loop_ctr}; # issue s252
                } else {
                    $nesting_info{loop_ctr} = '$_';                 # issue s235
                }
                $nesting_info{type} = 'foreach'; # issue s235: flag this as a different type of loop
            } elsif($lcx > 0) {                      # issue s100: should be always true
                if(exists $nesting_info{loop_ctr}) {    # issue s252
                    $nesting_info{loop_ctr} = $ValPerl[$lcx] . ',' . $nesting_info{loop_ctr};   # issue s252
                } else {                            # issue s252
                    $nesting_info{loop_ctr} = $ValPerl[$lcx];   # issue s100
                }
                ##### $ValPy[$lcx] = remap_loop_var($ValPy[$lcx]);    # issue s100
                $nesting_info{type} = 'foreach'; # issue s100: flag this as a different type of loop
            }                                   # issue s100
        }                                       # issue s100
    } elsif($nesting_info{type} eq 'if ') {         # issue implicit conditional return
        delete $level_block_lnos{$nesting_level+1};   # issue implicit conditional return
    }
    $nesting_info{lno} = $.;
    # issue s110 $nesting_info{varclasses} = dclone($line_varclasses{$last_block_lno}) if($Pythonizer::PassNo == &Pythonizer::PASS_1);
    $nesting_info{level} = $nesting_level;
    $nesting_info{package} = cur_raw_package();                 # issue s155
    # Note a {...} block by itself is considered a loop
    $nesting_info{is_loop} = ($begin <= $#ValClass && (($ValPy[$begin] eq '{' && $nesting_info{type} ne 'if') ||        # issue s44
                                                       $ValPerl[$begin] eq 'for' || 
                                                       $ValPerl[$begin] eq 'foreach' || $ValPerl[$begin] eq 'continue' ||
                                                       # issue s137 $ValPerl[$begin] eq 'do' ||                      # issue s50
                                                       $ValPerl[$begin] eq 'while' || $ValPerl[$begin] eq 'until'));
    $nesting_info{is_cond} = ($begin <= $#ValClass && ($ValPerl[$begin] eq 'if' || $ValPerl[$begin] eq 'unless' ||
                                                       $nesting_info{type} eq 'if' ||           # issue s44
                                                       is_eval() ||    # issue ddts
                                                       $ValPerl[$begin] eq 'elsif' || $ValPerl[$begin] eq 'else'));
    if($Pythonizer::PassNo == &Pythonizer::PASS_1) {            # issue s110
        if($nesting_info{is_loop} && ($begin > $#ValClass || $ValPy[$begin] ne '{')) {      # issue s110, issue s243: handle my $seven = eval q(return 7);
            # Issue s110: The scope of variables declared as a loop carry inside of the { } block only
            $nesting_info{varclasses} = $line_varclasses{$statement_starting_lno . 's'};    # issue s110
        } else {
            $nesting_info{varclasses} = dclone($line_varclasses{$last_block_lno}) ;
        }
    }
    # SNOOPYJC: eval doesn't have to be first! $nesting_info{is_eval} = ($begin <= $#ValClass && $ValPerl[$begin] eq 'eval');
    $nesting_info{is_eval} = is_eval();     # SNOOPYJC
    if($nesting_info{is_eval}) {            # issue s219
        $nesting_info{type} = 'try';        # issue s219
    }                                       # issue s219
    $nesting_info{is_sub} = ($begin <= $#ValClass && $ValPerl[$begin] eq 'sub');
    $nesting_info{cur_sub} = (($begin+1 <= $#ValClass && $nesting_info{is_sub}) ? $ValPerl[$begin+1] : undef);

    $nesting_info{in_loop} = ($nesting_info{is_loop} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_loop}));
    $nesting_info{in_cond} = ($nesting_info{is_cond} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_cond}));
    $nesting_info{in_eval} = ($nesting_info{is_eval} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_eval}));
    $nesting_info{in_sub} = ($nesting_info{is_sub} || (scalar(@nesting_stack) && $nesting_stack[-1]{in_sub}));
    if($nesting_info{in_sub} && !$nesting_info{is_sub}) {
        $nesting_info{cur_sub} = $nesting_stack[-1]{cur_sub};
    }
    if($nesting_info{type} eq 'do') {                                               # issue s35
        $nesting_info{delayed_block_closure} = $delayed_block_closure;              # issue s35: stack it
        $delayed_block_closure = 0;                                                 # issue s35
    }
    if($nesting_info{type} eq 'continue' && exists $line_needs_try_block{$nesting_last->{lno}}) {       # issue s49
        # propagate this flag from the main loop into the continue block
        $line_needs_try_block{$.} |= ($line_needs_try_block{$nesting_last->{lno}} & TRY_BLOCK_CONTINUE_NEEDED_ONE);
        if($::debug >= 4 && ($line_needs_try_block{$nesting_last->{lno}} & TRY_BLOCK_CONTINUE_NEEDED_ONE)) {
            say STDERR "TRY_BLOCK_CONTINUE_NEEDED_ONE propagaged";
        }
    }
    if(defined $last_label) {
        $nesting_info{label} = $last_label;
        $last_label = undef;            # We used it up
    } elsif($#ValClass >= 0 && $ValClass[0] eq 'i' && $ValPy[0] =~ /^for / && $ValPerl[0] =~ /[A-Z]+/) {   # issue s30: BEGIN and friends
        $nesting_info{label} = $ValPerl[0];
        # we set this only if we need to use it $all_labels{$ValPerl[0]} = 1;
    }
    push @nesting_stack, \%nesting_info;
    if(($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) || $::debug >= 6) {
        no warnings 'uninitialized';
        $Data::Dumper::Indent=0;        # issue s110
        $Data::Dumper::Terse = 1;       # issue s110
        # issue s110   say STDERR "nesting_info=@{[%nesting_info]}";
        say STDERR "nesting_info=" . Dumper(\%nesting_info);    # issue s110: get better debug info
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
    undo_block_scope_pragmas();     # use integer, use English
    $nesting_last = pop @nesting_stack;
    if(($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) || $::debug >= 6) {
        say STDERR "exit_block at line $., prior nesting_level=$nesting_level, nesting_last->{type} is now $nesting_last->{type}";
    }
    if($nesting_last->{package} ne cur_raw_package()) {         # issue s155
        restore_cur_raw_package($nesting_last->{package});      # issue s155
    }                                                           # issue s155
    if(exists $level_block_lnos{$nesting_level+1}) {            # issue implicit conditional return
        # Grab the list of nested conditional return lines and propagate it up to the next level
        $last_expression_lno = $level_block_lnos{$nesting_level+1};     # issue implicit conditional return
        delete $level_block_lnos{$nesting_level+1};             # issue implicit conditional return
    } elsif($nesting_level == cur_sub_level()+1) {              # issue implicit conditional return
        $last_expression_lno = 0;                               # issue implicit conditional return
    }
    if($nesting_last->{type} eq 'do') {                                             # issue s35
        $delayed_block_closure = $nesting_last->{delayed_block_closure};            # issue s35: Unstack it
    } elsif($nesting_last->{type} eq 'foreach' && exists $nesting_last->{loop_ctr}) { # issue s100
        unmap_loop_var($nesting_last->{loop_ctr});                                  # issue s100
    } elsif($line_contains_local_for_loop_counter{$StatementStartingLno{$nesting_last->{lno}}}) {          # issue s100, issue s275
        for my $ctr (keys %{$line_contains_local_for_loop_counter{$StatementStartingLno{$nesting_last->{lno}}}}) {    # issue s100, issue s275
            unmap_loop_var('$' . $ctr);                                             # issue s100
        }                                                                           # issue s100
    } elsif($Pythonizer::PassNo == &Pythonizer::PASS_1 && $nesting_last->{type} eq 'if ') {         # issue implicit conditional return
        my $cs = cur_sub();
        # issue s79 if(($last_expression_lno =~ /,/ || $last_expression_lno > $nesting_last->{lno}) && $cs ne '__main__') {
        if(($last_expression_lno =~ /,/ || $last_expression_lno >= $nesting_last->{lno}) && $cs ne '__main__') {    # issue s79
            $level_block_lnos{$nesting_level} = $last_expression_lno;
        }
        { no warnings 'uninitialized';
          say STDERR "At end of if on line $. at level $nesting_level, sub_lines_contain_potential_last_expression = $sub_lines_contain_potential_last_expression{$cs}, last_expression_lno = $last_expression_lno, level_block_lnos = " . Dumper(\%level_block_lnos) if($::debug >= 5);
        }
    } elsif($Pythonizer::PassNo == &Pythonizer::PASS_1 && ($nesting_last->{type} eq 'elif ' || $nesting_last->{type} eq 'else')) {  # issue implicit conditional return
        my $cs = cur_sub();
        # issue s79 if(($last_expression_lno =~ /,/ || $last_expression_lno > $nesting_last->{lno}) && $cs ne '__main__') {
        if(($last_expression_lno =~ /,/ || $last_expression_lno >= $nesting_last->{lno}) && $cs ne '__main__') {    # issue s79
            my $csn = cur_sub_level();
            if($nesting_level == $csn) {
               $sub_lines_contain_potential_last_expression{$cs} .= ',' . $last_expression_lno;
            }
            $level_block_lnos{$nesting_level} .= ',' . $last_expression_lno;
        }
        { no warnings 'uninitialized';
          say STDERR "At end of $nesting_last->{type} on line $. at level $nesting_level, sub_lines_contain_potential_last_expression = $sub_lines_contain_potential_last_expression{$cs}, last_expression_lno = $last_expression_lno, level_block_lnos = " . Dumper(\%level_block_lnos) if($::debug >= 5);
        }
    } elsif($Pythonizer::PassNo == &Pythonizer::PASS_1 && $nesting_last->{type} =~ /^(?:sub|def)$/) {
        my $cs = $nesting_last->{cur_sub};
        # issue s79 if($last_expression_lno =~ /,/ || $last_expression_lno > $nesting_last->{lno}) {
        if($last_expression_lno =~ /,/ || $last_expression_lno >= $nesting_last->{lno}) {        # issue s79: Handle s/.../.../e all on same line
            if(exists $level_block_lnos{$nesting_level}) {
                $level_block_lnos{$nesting_level} .= ',' . $last_expression_lno;
            } else {
                $level_block_lnos{$nesting_level} = $last_expression_lno;
            }
            $sub_lines_contain_potential_last_expression{$cs} = $level_block_lnos{$nesting_level};
            delete $level_block_lnos{$nesting_level};
        }
        { no warnings 'uninitialized';
          say STDERR "At end of $cs at level $nesting_level, sub_lines_contain_potential_last_expression = $sub_lines_contain_potential_last_expression{$cs}, last_expression_lno = $last_expression_lno, level_block_lnos = " . Dumper(\%level_block_lnos) if($::debug >= 5);
        }
    }

    determine_varclass_keepers($nesting_last->{varclasses}, $nesting_last->{lno}) if($Pythonizer::PassNo == &Pythonizer::PASS_1);
    my $label = '';
    $label = $nesting_last->{label} if(exists $nesting_last->{label});
    if(exists $nesting_last->{can_call} && $Pythonizer::PassNo == &Pythonizer::PASS_1 &&
       $nesting_last->{is_loop}) {                          # issue s170
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
            my $exc = ($pos == 0) ? 0 : TRY_BLOCK_EXCEPTION;
            $exc = TRY_BLOCK_EXCEPTION if in_local_do();            # issue s137
            for $ndx (reverse 0 .. $#nesting_stack) {
                if($nesting_stack[$ndx]->{is_loop}) {
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

sub handle_return               # issue s30
{
    return if($Pythonizer::PassNo != &Pythonizer::PASS_1);
    if(in_BEGIN()) {
        handle_return_in_expression(0);
    }
}

sub handle_return_in_expression         # SNOOPYJC: Handle 'return' in the middle of an expression
{
    return if($Pythonizer::PassNo != &Pythonizer::PASS_1);
    # In the first pass, just mark that we need a try/except block for this sub,
    # but do nothing if we're in an eval since that case is already handled.
    my $exc = 0;
    for $ndx (reverse 0 .. $#nesting_stack) {
        return if($nesting_stack[$ndx]->{is_eval});     # We already have an exception to get out of an eval
        if($nesting_stack[$ndx]->{is_sub}) {
            $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= TRY_BLOCK_EXCEPTION;  # Need an exception to return from this sub
            $uses_function_return_exception = 1;
            return;
        } elsif($nesting_stack[$ndx]->{is_loop}) {
            if($nesting_stack[$ndx]->{type} eq 'for _ in range(1)') {  # issue s30: This is a BEGIN
                $all_labels{$nesting_stack[$ndx]->{label}} = 1 if $exc;
                $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= $exc;  # May need an exception to return from this BEGIN
                return;
            }
            $exc = TRY_BLOCK_EXCEPTION;
        } elsif($nesting_stack[$ndx]->{type} eq 'for _ in range(1)') {  # issue s30: This is a BEGIN
            $all_labels{$nesting_stack[$ndx]->{label}} = 1 if $exc;
            $line_needs_try_block{$nesting_stack[$ndx]->{lno}} |= $exc;  # May need an exception to return from this BEGIN
            return;
        }
    }
}

sub return_in_BEGIN_needs_raise         # issue s30: Does this 'return' in a BEGIN need a raise, or just a 'break'?
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        return if($nesting_stack[$ndx]->{is_eval});     # We already have an exception to get out of an eval
        if($nesting_stack[$ndx]->{is_loop}) {
            if($nesting_stack[$ndx]->{type} eq 'for _ in range(1)') {  # issue s30: This is a BEGIN
                return 0;               # Just generate a 'break'
            } else {
                return 1;               # Must generate a 'raise'
            }
        } elsif($nesting_stack[$ndx]->{type} eq 'for _ in range(1)') {  # issue s30: This is a BEGIN
            return 0;
        }
    }
    return 0;
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

sub set_continue_needed_try_block       # issue s49
{
    my $at_bottom = shift;
    my $value = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($value) {
        $line_needs_try_block{$top->{lno}} |= TRY_BLOCK_CONTINUE_NEEDED_ONE;
        say STDERR "set_continue_needed_try_block, setting line_needs_try_block{$top->{lno}} to TRY_BLOCK_CONTINUE_NEEDED_ONE" if($::debug >= 3);
    } elsif(exists $line_needs_try_block{$top->{lno}}) {
        $line_needs_try_block{$top->{lno}} &= ~TRY_BLOCK_CONTINUE_NEEDED_ONE;
        say STDERR "set_continue_needed_try_block, clearing TRY_BLOCK_CONTINUE_NEEDED_ONE from line_needs_try_block{$top->{lno}}" if($::debug >= 3);
    } else {
        say STDERR "set_continue_needed_try_block, line_needs_try_block{$top->{lno}} not set - no need to clear TRY_BLOCK_CONTINUE_NEEDED_ONE" if($::debug >= 3);
    }
}

sub continue_needed_try_block           # issue s49
{
    my $at_bottom = shift;

    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($::debug >= 4) {
        no warnings 'uninitialized';
        print STDERR "continue_needed_try_block($at_bottom), top=@{[%$top]} returns ";
    }
    if(exists $line_needs_try_block{$top->{lno}} && 
        ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_CONTINUE_NEEDED_ONE)) {
        say STDERR "1" if($::debug >= 4);
        return 1 
    }
    say STDERR "0" if($::debug >= 4);
    return 0;
}

sub needs_try_block                # issue 94, issue 108
{
    my $at_bottom = shift;

    my $orig_at_bottom = $at_bottom;    # issue s108
    my $check_foreach = 0;          # issue s100
    if($at_bottom == -1) {          # issue s100: Called before generating the 'for' loop
        $check_foreach = 1;
        say STDERR "needs_try_block(-1): statement_starting_lno = $statement_starting_lno, lno = $. top->lno = " . (scalar(@nesting_stack) ? $nesting_stack[-1]->{lno} : 'undef') if($::debug >= 5);
        if($statement_starting_lno != $. && exists $line_needs_try_block{$statement_starting_lno}) {    # issue s108
            $line_needs_try_block{$nesting_stack[-1]->{lno}} = $line_needs_try_block{$statement_starting_lno}; # issue s108
        }                                                                                               # issue s108
        $at_bottom = 0;
    }
    my $top = $nesting_last;
    if(!$at_bottom) {
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
    }
    if($::debug >= 4) {
        no warnings 'uninitialized';
        print STDERR "needs_try_block($orig_at_bottom), top=@{[%$top]} returns ";
    }
    if(!$check_foreach && !$at_bottom && exists $line_needs_try_block{$top->{lno}} &&
        !($line_needs_try_block{$top->{lno}} & TRY_BLOCK_EXCEPTION) &&
        ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_FOREACH)) { # issue s100
        ;                                                           # issue s100: We already handled this one on the 'for'
    } elsif($check_foreach && (!exists $line_needs_try_block{$top->{lno}} ||
        !($line_needs_try_block{$top->{lno}} & TRY_BLOCK_FOREACH))) { # issue s100
        ;                                                            # issue s100: Only gen the 'try' before the 'for' if asked for
    } elsif(exists $line_needs_try_block{$top->{lno}} && 
        ($line_needs_try_block{$top->{lno}} & (TRY_BLOCK_EXCEPTION|TRY_BLOCK_FINALLY))) {
        say STDERR "1" if($::debug >= 4);
        return 1 
    }
    say STDERR "0" if($::debug >= 4);
    return 0;
}

sub clear_foreach_try_block     # issue s252: Don't need a try block for an unrolled foreach loop
# Returns if it was set
{
    return 0 unless exists $line_needs_try_block{$statement_starting_lno};
    my $result = $line_needs_try_block{$statement_starting_lno} & TRY_BLOCK_FOREACH;
    $line_needs_try_block{$statement_starting_lno} &= ~(TRY_BLOCK_FINALLY|TRY_BLOCK_FOREACH);
    return $result;
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
        print STDERR "has_continue($at_bottom), top=@{[%$top]} returns ";
    }
    if(exists $line_needs_try_block{$top->{lno}} && 
        ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_HAS_CONTINUE)) {
        say STDERR "1" if($::debug >= 4);
        return 1;
    }
    say STDERR "0" if($::debug >= 4);
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
        print STDERR "needs_implicit_continue($at_bottom), top=@{[%$top]} returns ";
    }
    if(exists $top->{implicit_continue}) {
        say STDERR $top->{implicit_continue} if($::debug >= 4);
        return $top->{implicit_continue} 
    }
    say STDERR "0" if($::debug >= 4);
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
        print STDERR "needs_redo_loop($at_bottom), top=@{[%$top]} returns ";
    }
    if(exists $line_needs_try_block{$top->{lno}} && 
                ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_REDO_LOOP)) {
        say STDERR "1" if($::debug >= 4);
        return 1;
    }
    say STDERR "0" if($::debug >= 4);
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

sub in_local_do                     # issue s137
# Is this statement in a do{...} (not counting a do surrounding this loop)
# The issue here is that last/next statements inside a 'do' generate code like 'break'
# that operates on the 'do', because we generate a loop for a 'do', and this is not
# what we want to happen - the last/next needs to operate on the enclosing loop like perl does.
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        return 1 if($nesting_stack[$ndx]->{type} eq 'do');
        return 1 if(exists $nesting_stack[$ndx]->{was_do});
        return 0 if($nesting_stack[$ndx]->{is_loop});   # Don't look outside of a loop
    }
    return 0;
}

sub in_aliased_foreach                     # issue s252
# Is this statement in a foreach (list)?
# The issue here is that we are pulling the code of the loop into a sub, so
# the last needs to propagate out via an exception
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        return 1 if(exists $nesting_stack[$ndx]->{was_foreach});
        return 0 if($nesting_stack[$ndx]->{is_loop});   # Don't look outside of a loop
    }
    return 0;
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

sub begin_loop_label                     # issue s30
# Get the label (name) of the current BEGIN-type block, if any.  Returns "BEGIN" for a BEGIN block.
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        next if $nesting_stack[$ndx]->{type} ne 'for _ in range(1)';
        if(exists $nesting_stack[$ndx]->{label}) {
            return $nesting_stack[$ndx]->{label};
        }
        return '';
    }
    return '';
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

sub cur_sub_level                     # issue implicit conditional return
# Get the nesting level of the current sub, if any
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        next if(!$nesting_stack[$ndx]->{is_sub});
        return $nesting_stack[$ndx]->{level};
    }
    return -1;
}

sub in_loop                         # issue implicit conditional return
# return 1 if we're in a loop
{
        return 0 if($nesting_level == 0);
        $top = $nesting_stack[-1];
        return $top->{in_loop};
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
    my $foreach = $line_needs_try_block{$top->{lno}} & TRY_BLOCK_FOREACH;
    gen_statement();
    &Pythonizer::correct_nest(-1,-1);
    &Pythonizer::correct_nest(-1,-1) if($foreach);
    &Pythonizer::correct_nest(-1,-1) if($foreach && ($line_needs_try_block{$top->{lno}} & TRY_BLOCK_EXCEPTION));
    gen_statement('finally:');
    &Pythonizer::correct_nest(1,1);
    my $lno = $top->{lno};
    my $code_generated = 0;
    if(exists $line_locals{$lno}) {                     # issue s100
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
    }
    if($foreach && exists $line_contains_local_for_loop_counter{$lno}) {        # issue s100
        foreach $name (reverse sort keys %{$line_contains_local_for_loop_counter{$lno}}) {
            next if($line_contains_local_for_loop_counter{$lno}{$name} ne 'localdone');
            my $pname = '$' . $name;                    # issue s108
            if(exists $NameMap{$name} && exists $NameMap{$name}{'$'}) {
                $name = $NameMap{$name}{'$'};
            }
            $name = escape_keywords($name);
            if(exists $line_varclasses{$lno}{$pname} && $line_varclasses{$lno}{$pname} =~ /global|local/) {       # issue s108
                $name = cur_package() . '.' . $name;            # issue s108
            }                                                   # issue s108
            gen_statement("$name = $LOCALS_STACK.pop()");
            $code_generated = 1;
        }
    }
    if(!$code_generated) {
        gen_statement('pass');
    }
    &Pythonizer::correct_nest(1,1) if($foreach);
}

sub stack_foreach_var           # issue s100
{
    my $lno = $statement_starting_lno;         # issue s108
    if(exists $line_contains_local_for_loop_counter{$lno}) {        # issue s100
        if($lno != $.) {                    # issue s108
            $line_contains_local_for_loop_counter{$.} = $line_contains_local_for_loop_counter{$lno};    # issue s108
        }
        foreach $name (sort keys %{$line_contains_local_for_loop_counter{$lno}}) {
            next if($line_contains_local_for_loop_counter{$lno}{$name} ne 'localdone');
            my $pname = '$' . $name;                    # issue s108
            if(exists $NameMap{$name} && exists $NameMap{$name}{'$'}) {
                $name = $NameMap{$name}{'$'};
            }
            $name = escape_keywords($name);
            if(exists $line_varclasses{$lno}{$pname} && $line_varclasses{$lno}{$pname} =~ /global|local/) {       # issue s108
                $name = cur_package() . '.' . $name;            # issue s108
            }                                                   # issue s108
            gen_statement("$LOCALS_STACK.append($name)");
        }
    }
}

sub unstack_foreach_var           # issue s252
{
    my $lno = $statement_starting_lno;         # issue s108
    my $code_generated = 0;
    if(exists $line_contains_local_for_loop_counter{$lno}) {        # issue s100
        if($lno != $.) {                    # issue s108
            $line_contains_local_for_loop_counter{$.} = $line_contains_local_for_loop_counter{$lno};    # issue s108
        }
        foreach $name (sort keys %{$line_contains_local_for_loop_counter{$lno}}) {
            next if($line_contains_local_for_loop_counter{$lno}{$name} ne 'localdone');
            my $pname = '$' . $name;                    # issue s108
            if(exists $NameMap{$name} && exists $NameMap{$name}{'$'}) {
                $name = $NameMap{$name}{'$'};
            }
            $name = escape_keywords($name);
            if(exists $line_varclasses{$lno}{$pname} && $line_varclasses{$lno}{$pname} =~ /global|local/) {       # issue s108
                $name = cur_package() . '.' . $name;            # issue s108
            }                                                   # issue s108
            gen_statement("$name = $LOCALS_STACK.pop()");
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
    return 1 if(in_local_do());                       # issue s137
    return 1 if($ValPerl[$pos] eq 'last' && in_aliased_foreach());                # issue s252
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
    # issue s144 update $sub = '__main__';                              # issue s144: Initialize local variables in main, if need be
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
    my $quiet = (scalar @_ ? $_[0] : 0);            # issue s198

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
            logme('W',"Choosing $sel$id ($result) for $perl typeglob") unless $quiet;
            return $package . $result;
        }
    }
    return $package . $NameMap{$id}{$keys[0]};
}

sub choose_glob_and_get_type           # issue s198
# Given a reference (probably an assignment to) a *typeglob, choose one of it's components to assign to
# Give a warning if there was more than one possibility
# arg1 = ValPerl
# arg2 = ValPy = default if not found
# result = (type, ValPy)
{
    my $valpy = choose_glob($_[0], $_[1], (scalar @_ > 2 ? $_[2] : 0));
    my $rdot = rindex($valpy, '.');
    my $basename = substr($valpy, $rdot+1);
    return ('H', $valpy) unless exists $ReverseNameMap{$basename};
    my $id = $ReverseNameMap{$basename};
    return ('H', $valpy) unless exists $NameMap{$id};
    for my $key (keys %{$NameMap{$id}}) {
        if($NameMap{$id}{$key} eq $valpy) {
            return ($SIGIL_MAP{$key}, $valpy);
        }
    }
    return ('H', $valpy);       # Assume it's a filehandle
}

#
# Tokenize line into one string and three arrays @ValClass  @ValPerl  @ValPy
#
sub tokenize
{
my ($l,$m);
   $source=$line=$_[0];
   #say STDERR "tokenize($source) on line $.";       # TEMP
   if(scalar(@_) != 2) {        # 2nd arg means to continue where we left off
       $tno=0;
       @ValClass=@ValCom=@ValPerl=@ValPy=@ValType=(); # "Token Type", token comment, Perl value, Py analog (if exists)
       $TokenStr='';
       $statement_starting_lno = $.;                      # issue 116
       $StatementStartingLno{$.} = $. unless exists $StatementStartingLno{$.};   # issue s275
       capture_statement_starting_varclasses();           # issue s110
   } else {
       $tno = scalar(@ValClass);
       $TokenStr=join('', @ValClass);
       $StatementStartingLno{$.} = $statement_starting_lno unless exists $StatementStartingLno{$.};    # issue s275
   }
   $ExtractingTokensFromDoubleQuotedTokensEnd = -1;     # SNOOPYJC
   $ExtractingTokensFromDoubleQuotedStringEnd = 0;      # SNOOPYJC
   $ExtractingTokensFromDoubleQuotedStringTnoStart = -1; # SNOOPYJC
   $ExtractingTokensFromDoubleQuotedStringXFlag = 0;    # issue s80
   $ExtractingTokensFromDoubleQuotedStringAdjustBrackets = 0;   # issue test coverage
   $ate_dollar = -1;                                    # issue 50
   my $end_br;                  # issue 43
   
   #if( $::debug > 3 && $main::breakpoint >= $.  ){
   #$DB::single = 1;
   #}
   while( defined $source && $source ne ''){    # issue s13
      $had_space = (substr($source,0,1) =~ /\s/);   # issue 50
      if($had_space && $ExtractingTokensFromDoubleQuotedStringEnd > 0) {    # issue test coverage
          $source =~ /^(\s*)/;
          my $spaces = length($1);
          $ExtractingTokensFromDoubleQuotedStringEnd -= $spaces;
          $ExtractingTokensFromDoubleQuotedTokensEnd -= $spaces;
          if($ExtractingTokensFromDoubleQuotedTokensEnd == 0) {
              extract_tokens_from_double_quoted_string('', 0, 0); 
              $source = substr($source,$spaces+1);              # Eat the leading spaces and the trailing delimiter
          }
          say STDERR "ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd, source=$source after removing leading spaces" if($::debug>=5);
      }
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
          $ValPy[$tno-1] = perl_hex_escapes_to_python(sprintf('\'\\x{%x}\'', int(substr($ValPy[$tno-1],1))));
      }
      if($s eq ',' && $tno != 0 && $ValClass[0] eq 't') {        # issue s144
         # issue s144: if this is a top-level comma in a 'my/our/state/local' statement, then
         # end the statement there and the rest is a new non-'my/our/state' statement.
         # issue s144 update: WRONG!!! Note that 'local' statements don't behave like this - we add a new 'local ' for them!
         # Example: my $myVar=1, $globalVar=2, $globalV;
         $balance=0;
         for ($i=0;$i<@ValClass;$i++ ){
            if( $ValClass[$i] eq '(' ){
               $balance++;
            }elsif( $ValClass[$i] eq ')' ){
               $balance--;
            } elsif($ValClass[$i] =~ /[if]/ && $i != 0 && $ValClass[$i-1] eq '=') {
                # Not our comma on: my $cl = substr $s, 14, 7;
                $balance = 99999;
            }
         }
         if($balance == 0) {
             $s = ';';
             my $typ = $ValPerl[0];
             # issue s144 update: if($typ eq 'local') {          # In my testing, local applies to the whole list, but none of the others do this
             # issue s144 update:     substr($source, 1, 0) = 'local ';      # Splice in a new 'local '
             # issue s144 update: } else {
             logme('W', "Remaining declarations after ',' are not '$typ'") if(!$::implicit_global_my && $Pythonizer::PassNo == &Pythonizer::PASS_1);
             # issue s144 update: }
         }
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
         my @tmpBuffer = @BufferValClass;   # SNOOPYJC: Must get a real line even if we're buffering stuff
         @BufferValClass = ();              # SNOOPYJC
         if((2 <= $#ValClass && $ValClass[0] eq 'h' && $ValClass[1] eq '=' && $ValClass[2] eq '(') ||
            (3 <= $#ValClass && $ValClass[0] eq 't' && $ValClass[1] eq 'h' && $ValClass[2] eq '=' && $ValClass[3] eq '(')) {     # issue s228
            # issue s228: In hash assignments only, which could be long, try to keep the comments where they were
            while(defined ($source=Pythonizer::getline(2))) {
                if($source =~ /^\s*$/ || $source =~ /^\s*#/) {            # blank or comment only line
                    $ValCom[$tno-1] .= "\n$source";
                } else {
                    last;
                }
            }
         } else {                                 # issue s228
            $source=Pythonizer::getline();
         }
         $StatementStartingLno{$.} = $statement_starting_lno;    # issue s275
         @BufferValClass = @tmpBuffer;  # SNOOPYJC
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
         $balance = 0 if($Pythonizer::PassNo == &Pythonizer::PASS_0 && $balance < 0);   # issue s239
         {
          no warnings 'uninitialized';
          $Data::Dumper::Indent=0;
          $Data::Dumper::Terse = 1;
          say STDERR "Perlscan got ; balance=$balance, tno=$tno, nesting_last=".Dumper(\$nesting_last) if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
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
            } elsif($tno == 0 && defined $nesting_last && $nesting_last->{type} eq 'do') {      # SNOOPYC
               # if this is a do{...}; we will generate an infinite loop unless we add a False condition here!
               $ValClass[$tno]='c'; $ValPy[$tno]=$ValPerl[$tno]='while'; $tno++;
               $ValClass[$tno]=$ValPy[$tno]=$ValPerl[$tno]='('; $tno++;
               $ValClass[$tno]='d'; $ValPy[$tno]='False'; $ValPerl[$tno]='0'; $tno++;
               $ValClass[$tno]=$ValPy[$tno]=$ValPerl[$tno]=')'; $tno++;
            } elsif($tno == 0 && $delayed_block_closure && scalar(@nesting_stack) && $nesting_stack[-1]->{type} eq 'do') {      # issue s35
                $delayed_do_false = 1;
            } elsif($tno != 0 && $ValClass[0] eq 'c' && $ValPerl[0] ne 'assert' && $Pythonizer::PassNo == &Pythonizer::PASS_1 &&
                    defined $nesting_last && $nesting_last->{type} eq 'try') {    # issue s219: eval {...} if ...;
                $line_contains_stmt_modifier{$nesting_last->{lno}} = 1;      # issue s219 Remember for PASS_2
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
         ($ExtractingTokensFromDoubleQuotedStringEnd == 0 ||                # issue s114
          $ExtractingTokensFromDoubleQuotedStringAdjustBrackets != 0) &&    # issue s114
         index('$@%&*"\'', substr($source,2,1)) < 0) {     # issue 43 - Look for ${...} and delete the brackets
         #-> THIS BREAKS issue 43:  !exists $SPECIAL_VAR{substr($source,2,1)}) {     # issue 43 - Look for ${...} and delete the brackets
                                                        # Don't do this on @{$...}, ${"..."}, etc
         $end_br = matching_curly_br($source, 1);       # issue 43
         if($end_br > 0) {                              # issue 43
            if(index(substr($source,0,$end_br), '(') < 0) {    # issue 43: Don't do this on @{myFunc()}
               substr($source,$end_br,1) = '';          # issue 43
               substr($source,1,1) = '';                # issue 43
               $ValType[$tno] = $ValClass[$tno] . '{';  # issue s250: Handle %{ $vhohash{$vho1}} not as '%' operator
               if($ExtractingTokensFromDoubleQuotedStringAdjustBrackets) {      # issue test coverage
                   $ExtractingTokensFromDoubleQuotedTokensEnd-=2;   # issue test coverage
                   $ExtractingTokensFromDoubleQuotedStringEnd-=2;   # issue test coverage
                   $ExtractingTokensFromDoubleQuotedStringAdjustBrackets = 0;   # issue test coverage
                   say STDERR "ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd, source=$source after ExtractingTokensFromDoubleQuotedStringAdjustBrackets" if($::debug>=5);
               }
            }
         }                                              # issue 43
      }
      if((($tno!=0 && $ValClass[$tno-1] eq 'f' && $ValPerl[$tno-1] eq 'split') ||
         ($tno-2>= 0 && $ValClass[$tno-1] eq '(' && $ValClass[$tno-2] eq 'f' && $ValPerl[$tno-2] eq 'split')) &&
         ($s eq '"' || $s eq "'")) { # issue s138
           $cut=single_quoted_literal($s,1);        # issue s138
           my $str = substr($source, 0, $cut);      # issue s138
           if($s eq '"') {                      # issue s138
               $str = remove_perl_escapes($str, 0); # issue s138
               substr($source, 0, $cut) = $str; # issue s138
           }                                    # issue s138
           if($str !~ $NON_REGEX_CHARS) {       # issue s138
               substr($source, 0, 0) = 'm';     # issue s138
               $s = 'm';                        # issue s138
           }                                    # issue s138
      }                                         # issue s138

      if( $s eq '}' ){
         # we treat '}' as a separate "dummy" statement -- eauvant to ';' plus change of nest -- Aug 7, 2020
         #say STDERR "Got }, tno=$tno, source=$source";
         if( $tno==0  ){
              # we recognize it as the end of the block if '}' is the first symbol
             if($add_comma_after_anon_sub_end && could_be_anonymous_sub_close()) {     # issue s78
                substr($source,1,0) = ',';
                say STDERR "source=$source after add_comma_after_anon_sub_end" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
                $add_comma_after_anon_sub_end = 0;                              # issue s78
             }
             if( length($source)>=1 ){
                exit_block();                 # issue 94
                Pythonizer::getline(substr($source,1)); # save tail
                $source=$s; # this was we artifically create line with one symbol on it;
                if($delayed_do_false && $nesting_last->{type} eq 'do') {                # issue s35
                    # if this is a do{...}; we will generate an infinite loop unless we add a False condition here!
                    $tno++;
                    $ValClass[$tno]='c'; $ValPy[$tno]=$ValPerl[$tno]='while'; $tno++;
                    $ValClass[$tno]=$ValPy[$tno]=$ValPerl[$tno]='('; $tno++;
                    $ValClass[$tno]='d'; $ValPy[$tno]='False'; $ValPerl[$tno]='0'; $tno++;
                    $ValClass[$tno]=$ValPy[$tno]=$ValPerl[$tno]=')'; $tno++;
                    $delayed_do_false = 0;
                }
             }
             last; # we need to process it as a seperate one-symbol line
         }elsif( $tno>0 && (length($source)==1 || $source =~ /^}\s*$/ ||    # issue ddts: Handle spaces at end
                 $source =~ /^}\s*#/ || 
                 could_be_anonymous_sub_close() ||              # SNOOPYJC
                 $source =~ /^}[\s}]+$/ ||                # issue s139: Ok if it's multiple close '}'
                 $source =~ /^}[\s}]+#/ ||                # issue s139: Ok if it's multiple close '}' followed by comment
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
                if($add_comma_after_anon_sub_end && could_be_anonymous_sub_close()) {     # issue s39, issue s78
                    substr($source,1,0) = ',';
                    say STDERR "source=$source after add_comma_after_anon_sub_end" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
                    $add_comma_after_anon_sub_end = 0;                              # issue s39
                }
                Pythonizer::getline($source); # make it a separate statement # issue 45
                popup(); # kill the last symbol
                last; # we truncate '}' and will process it as the next line
             }
             #say STDERR "parens_are_NOT_balanced";
         }
         # this is closing bracket of hash element
     if( $tno > 2 && $ValClass[$tno-1] eq 'i' and $ValPerl[$tno-2] eq '{' ) {   # issue 13
        $ValPy[$tno-1] = "'".$ValPy[$tno-1]."'";                    # issue 13: quote bare word
            $ValClass[$tno-1]='"';                          # issue 13
     }                                      # issue 13
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
          if( $tno==0 && looks_like_anon_hash_def($source)) {   # issue test coverage
              ;                 # Handle below as normal {
          } elsif( $tno==0 ){
             if($s eq '{' ) {    # SNOOPYJC: We swap '{' for '^' the second time around so we know if we need to call enter_block
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
          } elsif($tno == 1 && $ValClass[0] eq 'k' && $ValPerl[0] eq 'return') {       # issue s213: return {...} (hashref)
              ;                                 # issue s213
          }elsif( (length($source)==1 || $source =~ /^{\s*#/) && $ValClass[$tno-1] ne '=' && $ValClass[$tno-1] ne 'f' && # issue 82, issue 60 (map/grep)
                  $ValClass[$tno-1] ne 's' &&                   # SNOOPYJC: $var\n with '{' on next line
                  $ValClass[$tno-1] ne 'A' &&                   # issue s145
                  $ValClass[$tno-1] ne '(' && $ValClass[$tno-1] ne ',') {       # SNOOPYJC
             # $tno>0 but line may came from buffer.
             # We recognize end of statemt only if previous token eq ')' to avod collision with #h{$s}
             enter_block() if($s eq '{');                 # issue 94
             # SNOOPYJC Pythonizer::getline('{'); # make $tno==0 on the next iteration
             if( length($source)>1  ){                  # SNOOPYJC
                 if($source =~ /^{\s*#/ && $#ValClass-1 > 0) {          # issue test comments: tail comment only
                     $ValCom[$#ValClass-1] .= substr($source,1);  # issue test comments
                 } else {                           # issue test comments
                     Pythonizer::getline(substr($source,1)); # save tail
                 }
             }
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
                  ($ValClass[$tno-1] eq 'C' && $ValPerl[$tno-1] eq 'do') ||  # issue s74
                  ($tno == 2 && $ValPerl[0] eq 'sub') ||
                  $ValPerl[$tno-1] eq 'sub' ||          # issue 81
                  ($tno >= 2 && $ValClass[0] eq 'c' && $ValPy[0] eq 'when') ||              # issue s129
                  ($tno == 1 && $ValPerl[0] =~ /BEGIN|END|UNITCHECK|CHECK|INIT/))){ # issue 35, 45
             # $tno>0 this is the case when curvy bracket has comments'
             enter_block() if($s eq '{');                 # issue 94
             # SNOOPYJC Pythonizer::getline('{',substr($source,1)); # make it a new line to be proceeed later
             # issue 42 Pythonizer::getline('^',substr($source,1)); # SNOOPYJC: make it a new line to be proceeed later
             Pythonizer::getline('^');          # issue 42: Send 1 line at a time
             if($source =~ /^{\s*#/ && $#ValClass-1 > 0) {          # issue test comments: tail comment only
                 $ValCom[$#ValClass-1] .= substr($source,1);  # issue test comments
             } else {                           # issue test comments
                Pythonizer::getline(substr($source,1));     # SNOOPYJC: make it a new line to be proceeed later
             }
             popup(); # eliminate '{' as it does not have tno==0
             last;
          }elsif($ValClass[$tno-1] eq 'D') {    # issue 50, issue 93
            popup();                            # issue 50, 37
            $TokenStr=join('',@ValClass);       # issue 50
            $tno--;             # issue 50 - no need to keep arrow operator in python
            $ValPerl[$tno]=$ValPy[$tno]=$s; # issue 50
         } elsif($s eq '{' && $ValClass[$tno-1] eq 'f' && semicolon_in_block($source)) {     # issue s39
             # issue s39: for functions like map with a block of code, if we have multiple statements in that code,
             # then insert an anonymous sub, which we will pull out during code generation.  For example:
             # input line: @files = map { /\A(.*)\z/s; $1 } readdir $d;
             # gen:        @files = map sub {$_ = $_[0]; /\A(.*)\z/s; $1}, readdir $d;
             $add_comma_after_anon_sub_end = 1;         #                ^ Tells us to add this comma later
             say STDERR "Setting add_comma_after_anon_sub_end = 1" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
             if($ValPerl[$tno-1] ne 'sort') {               # issue s78: No need to do this for sort
                substr($source,1,0) = '$_ = $_[0];';       # Grab the default var from the 1st arg
             }
             $ValClass[$tno] = 'k';
             $ValPerl[$tno] = 'sub';
             $ValPy[$tno] = 'def';
             $tno++;
             enter_block();
             Pythonizer::getline('^');
             Pythonizer::getline(substr($source,1));    # make it a new line to be proceeed later
             # Note that if the user enters the code like the above, it won't work (it returns a list of subs),
             # but we check for that during code generation and generate the code to call the function on
             # each list item.
             last;
         }
         $ValClass[$tno]='('; # we treat anything inside curvy backets as expression
         $ValPy[$tno]='[';
         $cut=1;
      # issue 17 }elsif( $s eq '/' && ( $tno==0 || $ValClass[$tno-1] =~/[~\(,k]/ || $ValPerl[$tno-1] eq 'split') ){
      # issue s151 }elsif( $s eq '/' && ( $tno==0 || $ValClass[$tno-1] =~/[~\(,kc=o0!>]/ || $ValPerl[$tno-1] eq 'split' ||   # issue ddts: add '>' to list
      }elsif( $s eq '/' && ( $tno==0 || $ValClass[$tno-1] =~/[~p\(,kc=o0!>M]/ || $ValPerl[$tno-1] eq 'split' ||   # issue ddts: add '>' to list, issue s151 add p but keep ~ in case of 'mistaken' code, issue s251: add 'M' to list for ~~
          $ValPerl[$tno-1] eq 'grep' || $ValClass[$tno-1] eq 'r') ){    # issue 17, 32, 66, 60, range
           # typical cases: if(/abc/ ){0}; $a=~/abc/; /abc/; split(/,/,$text)  split /,/,$text REALLY CRAZY STAFF
           if($ValClass[$tno-1] eq '~' && $Pythonizer::PassNo == &Pythonizer::PASS_2) {     # issue s151
               logme('W', '~ (bitwise complement) operator is most likely not what the programmer intended before a regex pattern');  # issue s151
           }                                # issue s151
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
              $ValPy[$tno]=put_regex_in_quotes( $ValPerl[$tno], '/', $original_regex, 0); # double quotes neeed to be escaped just in case, issue 111, issue s80 FIXME!
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
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);   # issue 39
        popup();                            # issue 39
            popup() if($has_squiggle);
            # issue 39 $cut=length($source);
     }elsif(index($ValPerl[$tno], "\n") >= 0) {     # issue 39 - multi-line string
            $ValPy[$tno]="'''".escape_non_printables(escape_backslash($ValPerl[$tno], "'"),0)."'''"; # only \n \t \r, etc needs to be  escaped # issue 39
         }else{
            $ValPy[$tno]="'".escape_non_printables(escape_backslash($ValPerl[$tno], "'"),0)."'"; # only \n \t \r, etc needs to be  escaped
         }
         $ValPy[$tno] = replace_usage($ValPy[$tno]) if($::replace_usage);
         $ValPy[$tno] = replace_run($ValPy[$tno]) if($::replace_run);   # issue s87
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
            $ValClass[$tno]='"';        # issue 39
            $ValPerl[$tno]=substr($source,1,$cut-2);
        # issue 39 $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno]);
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);   # issue 39
            my $quote = substr($ValPy[$tno],3,length($ValPy[$tno])-6);  # issue 39: remove the """ and """
            interpolate_strings($quote, $quote, 0, 0, 0, 0);     # issue 39, issue s80
            popup();                            # issue 39
            popup() if($has_squiggle);
        $TokenStr=join('',@ValClass);       # issue 39
        # issue 39 $cut=length($source);
     }elsif(index($ValPy[$tno], "\n") >= 0 && substr($ValPy[$tno],0,1) eq 'f' && $ValPy[$tno] !~ /^f"""/) { # issue 39 - multi-line string
            $ValPy[$tno] =~ s/^f"/f"""/;            # issue 39
        $ValPy[$tno] .= '""';               # issue 39
         }
         $ValPy[$tno] = replace_usage($ValPy[$tno]) if($::replace_usage);
         $ValPy[$tno] = replace_run($ValPy[$tno]) if($::replace_run);   # issue s87
         $ValPerl[$tno]=substr($source,1,$cut-2);
      }elsif( $s eq '`'  ){
          $ValClass[$tno]='x';
          $cut=double_quoted_literal('`',1);
          #$ValPy[$tno]=$ValPy[$tno];
          $ValPy[$tno] = replace_run($ValPy[$tno]) if($::replace_run);   # issue s87
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
         }elsif( $source=~/(^\d+(?:[_]\d+)*(?:[.]\d*(?:[_]\d+)*)?(?:[Ee][+-]?\d+(?:[_]\d+)*)?)/  ){ # issue 23, SNOOPYJC: Handle '_'
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
            $ValPy[$tno] = "0o".substr($ValPy[$tno], 1);    # issue 22
         }                          # issue 22
     }elsif( $s=~/\w/  ){
         # SNOOPYJC var $source=~/^(\w+(\:\:\w+)*)/;
         $source=~/^(\w+((?:(?:\:\:)|\')\w+)*)/;         # SNOOPYJC: Old perl used ' in a name instead of ::
         $w=$1;
         $cut=length($w);
         # issue s155 if($tno == 0 && $w eq 'END') {         # SNOOPYJC: END block
         if($tno == 0 && $w =~ /^(?:BEGIN|INIT|CHECK|UNITCHECK|END)$/) {         # issue s155
             $ValClass[$tno]='k';
             $ValPerl[$tno]='sub';
             $ValPy[$tno]='def';
             $ValCom[$tno]='';
             $tno++;
             $w = "__${w}__$.";                  # SNOOPYJC: Special name checked in pythonizer
             if($w =~ /__END/) {                              # issue s155
                push @EndBlocks, $w if($Pythonizer::PassNo == &Pythonizer::PASS_1);         # SNOOPYJC
             } elsif($w =~ /__BEGIN/) {                       # issue s155
                push @BeginBlocks, $w if($Pythonizer::PassNo == &Pythonizer::PASS_1);   # issue s155
             } elsif($w =~ /__CHECK/) {                       # issue s155
                push @CheckBlocks, $w if($Pythonizer::PassNo == &Pythonizer::PASS_1);   # issue s155
             } elsif($w =~ /__INIT/) {                        # issue s155
                push @InitBlocks, $w if($Pythonizer::PassNo == &Pythonizer::PASS_1);    # issue s155
             } elsif($w =~ /__UNITCHECK/) {                   # issue s155
                push @UnitCheckBlocks, $w if($Pythonizer::PassNo == &Pythonizer::PASS_1);   # issue s155
             }                                              # issue s155
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
         # issue s233 if(substr($w,0,5) eq "Carp'" && $w =~ /carp|confess|croak|cluck/) {    # SNOOPYJC
         # issue s233 $w = substr($w,5);
         # issue s233 } elsif(substr($w,0,6) eq 'Carp::' && $w =~ /carp|confess|croak|cluck/) {      # SNOOPYJC
         # issue s233 $w = substr($w,6);
         # issue s233 }
         if(substr($w,0,10) eq "UNIVERSAL'" && $w =~ /isa/) {    # issue s54
             $w = substr($w,10);
         } elsif(substr($w,0,11) eq 'UNIVERSAL::' && $w =~ /isa/) {      # issue s54
             $w = substr($w,11);
         }
         if( exists($keyword_tr{$w}) ){
            $ValPy[$tno]=$keyword_tr{$w};
         }
         if( exists($CONSTANT_MAP{$w}) ) {      # SNOOPYJC
             $ValPy[$tno] = $CONSTANT_MAP{$w};  # SNOOPYJC
         }                                      # SNOOPYJC
         if($Pythonizer::PassNo!=&Pythonizer::PASS_0 && exists $FileHandles{$w}) {      # SNOOPYJC
             if($tno == 0 || $ValClass[$tno-1] ne 'k' || $ValPerl[$tno-1] ne 'sub') {   # SNOOPYJC
                 add_package_name_fh($tno); # SNOOPYJC
             }                  # SNOOPYJC
         }                  # SNOOPYJC
         if( exists($TokenType{$w}) ){
            $class=$TokenType{$w};
            # issue s190 if($class eq 'f' && !$core && (exists $Pythonizer::UseSub{$w} || exists $Pythonizer::LocalSub{$w})) {     # SNOOPYJC
            if($class eq 'F' && !$core && (exists $Pythonizer::UseSub{$w} || exists $Pythonizer::LocalSub{$w})) {     # SNOOPYJC
                $class = 'i';                   # issue s190
                $ValPy[$tno] = $w;              # issue s190
            } elsif($class eq 'F') {            # issue s190: convert weak function back to normal function
                $class = 'f';                   # issue s190
            }
            if($class eq 'f' && !$core && exists $Pythonizer::UseSub{$w}) {     # SNOOPYJC, issue s190: local sub does NOT override a function unless it's in a use subs
                $class = 'i';
                $ValPy[$tno] = $w;
            } elsif($class eq 'q' && $tno != 0 && $ValClass[$tno-1] eq 'q') {   # issue 120: flags!
                $class = 'i';
                $ValPy[$tno] = $w;
            } elsif($class eq '"' && $w eq '__PACKAGE__') {             # issue s3
                $ValPy[$tno] = "'" . escape_keywords(cur_package(), 1) . "'";
            } elsif($class eq 'f' && $core) {           # issue s178: Remove the "CORE." prefix
                $ValPy[$tno] = $ValPerl[$tno] = $w;     # issue s178
                $ValPy[$tno]=$keyword_tr{$w} if exists $keyword_tr{$w}; # issue s178
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
                if($pd < 0 || substr($subname, 0, $pd) eq cur_package()) {  # issue s243
                    replace(1, 'i', substr($ValPerl[0],1), $subname);       # Change the = to the subname (eat the '*')
                    replace(0, $class, $ValPerl[$tno], $ValPy[$tno]);      # Start with the sub
                    popup();                                       # Eat the extra 'sub'
                    remap_conflicting_names($ValPerl[1], '&', '');      # issue 92: sub takes the name from other vars
                    $class = 'i';
                    $tno--;
                    $Pythonizer::LocalSub{$ValPy[$tno]} = 1;
                    $Pythonizer::LocalSub{cur_package() . '.' . $ValPy[$tno]} = 1;          # issue s3
                }
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
                unless(exists $SpecalVarsUsed{'bless'}) {                   # issue s184
                    &Pythonizer::propagate_sub_attributes_for_bless();      # issue s184
                }                                                           # issue s184
                $SpecialVarsUsed{'bless'}{$cs} = 1;
                # issue s241  $Pythonizer::SubAttributes{$cs}{blesses} = 1;
                &Pythonizer::set_sub_attribute($cs, 'blesses', 1);  # issue s241
                # issue s18 $SpecialVarsUsed{'bless'}{cur_package()} = 1;
                $SpecialVarsUsed{'bless'}{cur_raw_package()} = 1;       # issue s18
            # issue s3 } elsif($class eq 'd' && $w eq 'wantarray' && $Pythonizer::PassNo == &Pythonizer::PASS_2) {   # SNOOPYJC: give warning
            } elsif($class eq 'f' && $w eq 'caller') {      # issue s160
                my $cs = cur_sub();                         # issue s160
                $SpecialVarsUsed{'caller'}{$cs} = 1;        # issue s160
            } elsif($class eq 'd' && $w eq 'wantarray') {   # issue s3
                my $cs = cur_sub();
                # issue s3 logme('W',"'wantarray' reference in $cs is hard wired to $ValPy[$tno]");
                $SpecialVarsUsed{'wantarray'}{$cs} = 1;         # issue s3
                # issue s241 $Pythonizer::SubAttributes{$cs}{wantarray} = 1; # issue s3
                &Pythonizer::set_sub_attribute($cs, 'wantarray', 1); # issue s3, issue s241
            } elsif($class eq 'c' && $ValPy[$tno] eq 'when') {  # issue s129
                set_for_given();                                # issue s129: If this 'when' (or 'case') is in a 'for', change the 'for' to a 'given'
                $source = fixup_case_subs($source, $cut);       # issue s129
            } elsif($class eq 'c' && $w eq 'switch') {          # issue s129
                $source = fixup_switch_subs($source, $cut);     # issue s129
            } elsif($class eq 'c' && $ValPy[$tno] eq 'for' && exists $line_contains_for_given{$.}) {   # issue s129
                $ValPy[$tno] = 'given';             # issue s129
                $ValPerl[$tno] = 'given';           # issue s129
                $w = 'given';                       # issue s129
            }
            $ValClass[$tno]=$class;
            if( $class eq 'c' && $tno > 0 && $w ne 'assert' && $Pythonizer::PassNo == &Pythonizer::PASS_1 && ($ValClass[0] ne 'C' || $ValPerl[0] ne 'do')){ # issue 116: Control statement, like if and do
                $line_contains_stmt_modifier{$statement_starting_lno} = 1;      # issue 116: Remember for PASS_2
            }
                
            # issue s231 if( $class eq 'c' && $tno > 0 && $w ne 'assert' && $Pythonizer::PassNo == &Pythonizer::PASS_2 && ($ValClass[0] ne 'C' || $ValPerl[0] ne 'do')){ # Control statement, like if # SNOOPYJC: and do
            if( $class eq 'c' && $tno > 0 && $w ne 'assert' && $Pythonizer::PassNo == &Pythonizer::PASS_2) {        # issue s231
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
               @BufferValType=@ValType; # issue 37
               @ValClass=@ValCom=@ValPerl=@ValPy=();
               @ValType=(); # issue 37
               $tno=0;
               $ValClass[$tno]=$class;
               $TokenStr = $class;      # issue 37
               $ValPy[$tno]=$w;
               if( exists($keyword_tr{$w}) ){
                  $ValPy[$tno]=$keyword_tr{$w};
               }
               $ValPerl[$tno]=$w;
               $ValType[$tno]='P';
            } elsif($class eq 'c' && $Pythonizer::PassNo == &Pythonizer::PASS_1 && ($w eq 'if' || $w eq 'unless' || $w eq 'for' || $w eq 'foreach' || $w eq 'when' || $w eq 'case') &&    # SNOOPYJC, issue s182: also handle for/foreach/when/case
                    defined $nesting_last && $nesting_last->{type} eq 'do' &&
                    $tno == 0 &&                                # issue s147: Make sure this 'if' is the first thing
                    $source =~ /^(\w+)(.*?);/) {                # issue s60
                # We can't do our normal trick to handle STMT if COND; for a do{...} if COND; because 
                # it's more than one statement, so instead we use another trick and rememeber a regex in the
                # first pass that we apply to the 'do' statement to change it into an if/unless statement
                # issue s60 $source =~ /^(\w+)(.*?);/;    # Grab everything up to but not including the ';'
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
#           } elsif( $class eq 'k' && $w eq 'sub' && $tno > 0 && $Pythonizer::PassNo ){ # issue 81: anonymous sub
#               $ValClass[$tno] = 'i';
#               $ValPy[$tno] = $ValPerl[$tno] = "$ANONYMOUS_SUB$.";
#               #$Pythonizer::LocalSub{$ValPerl[$tno]} = 1;
#               @BufferValClass=@ValClass; @BufferValCom=@ValCom; @BufferValPerl=@ValPerl; @BufferValPy=@ValPy;
#          @BufferValType=@ValType; # issue 37
#               @ValClass=@ValCom=@ValPerl=@ValPy=();
#          @ValType=(); # issue 37
#               $tno=0;
#               $ValClass[$tno]=$class;
#               $TokenStr = $class;      # issue 37
#               $ValPy[$tno]=$w;
#               $ValPerl[$tno]=$w;
#               $tno++;
#               $ValClass[$tno] = 'i';
#               $ValPy[$tno] = $ValPerl[$tno] = "$ANONYMOUS_SUB$.";
#               #$ValType[$tno]='P';
            }elsif ( $class eq 'o' ){   # and/or   # issue 93
                  # issue s77: $balance=(join('',@ValClass)=~tr/()//);
                  # issue 93 if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && join('',@ValClass) !~ /^t?[ahs]=/ ){
                  # issue s77 if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && bash_style_or_and_fix($cut)){             # issue 93
                  if( parens_are_balanced() && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && bash_style_or_and_fix($cut)){             # issue 93, issue s77
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
                  $ValPy[$tno] = replace_run($ValPy[$tno]) if($::replace_run);   # issue s87
               }elsif( $w eq 'qq' ){
                  # decompose doublke quote populate $ValPy[$tno] as a side effect
                  $cut=double_quoted_literal($delim,length($w)+1); # side affect populates $ValPy[$tno] and $ValPerl[$tno]
                  $ValClass[$tno]='"';
          if(index($ValPy[$tno], "\n") >= 0 && substr($ValPy[$tno],0,1) eq 'f' && $ValPy[$tno] !~ /^f"""/) { # issue 39 - multi-line string
                      $ValPy[$tno] =~ s/^f"/f"""/;      # issue 39
                  $ValPy[$tno] .= '""';         # issue 39
           }                        # issue 39
                   $ValPy[$tno] = replace_usage($ValPy[$tno]) if($::replace_usage);
                   $ValPy[$tno] = replace_run($ValPy[$tno]) if($::replace_run);   # issue s87
               }elsif( $w eq 'qx' ){
                  #executable, needs interpolation
                  $cut=double_quoted_literal($delim,length($w)+1);
                  #$ValPy[$tno]=$ValPy[$tno];
                  $ValPy[$tno] = replace_run($ValPy[$tno]) if($::replace_run);   # issue s87
                  $ValClass[$tno]='x';
               }elsif( $w eq 'm' || $w eq 'qr' || $w eq 's' ){  # issue bootstrap - change to "||"
                  $source=substr($source,length($w)+1); # cut the word and delimiter
                  $cut=single_quoted_literal($delim,0); # regex always ends before the delimiter
                  # issue 51 $arg1=substr($source,0,$cut-1);
                  $original_regex = substr($source,0,$cut-1);                            # issue 111
                  $arg1=remove_escaped_delimiters($delim, $original_regex);     # issue 51, issue 111
                  $source=substr($source,$cut); #cut to symbol after the delimiter
                  $cut=0;
                  if( ($w eq 'm' || $w eq 'qr') && ($tno>=1 && $ValPerl[$tno-1] eq 'split') ||
                      ($tno>=2 && $ValClass[$tno-1] eq '(' && $ValPerl[$tno-2] eq 'split')) {   # issue s52
                      # in split regex should be  plain vanilla -- no re.match is needed.
                      ($modifier,undef)=is_regex($arg1,0); # modifies $source as a side effect, issue s131
                      if( length($modifier) > 1 ){
                        #regex with modifiers
                         $quoted_regex='re.compile('.put_regex_in_quotes($arg1, $delim, $original_regex, x_flag($modifier))."$modifier)";   # issue 111, issue s80
                      }else{
                        # No modifier
                        $quoted_regex=put_regex_in_quotes($arg1, $delim, $original_regex, 0);       # issue 111, issue s80
                      }
                      $ValPy[$tno]=$quoted_regex;
                  # issue s151 } elsif( $w eq 'm' || ($w eq 'qr' &&  $ValClass[$tno-1] eq '~') ){
                  } elsif( $w eq 'm' || ($w eq 'qr' &&  $ValClass[$tno-1] eq 'p') ){        # issue s151
                     $ValClass[$tno]='q';
                     $ValPy[$tno]=perl_match($arg1, $delim, $original_regex); # it calls is_regex internally, issue 111
                  # issue s52 }elsif( $w eq 'qr' && $tno>=2 && $ValClass[$tno-1] eq '(' && $ValPerl[$tno-2] eq 'split' ){
                  # issue s52    # in split regex should be  plain vanilla -- no re.match is needed.
                  # issue s52    $ValPy[$tno]='r'.$quoted_regex; #  double quotes neeed to be escaped just in case
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
                            my @tmpBuffer = @BufferValClass;    # SNOOPYJC: Must get a real line even if we're buffering stuff
                            @BufferValClass = ();               # SNOOPYJC
                            $line = Pythonizer::getline();      # issue 39
                            $StatementStartingLno{$.} = $statement_starting_lno;    # issue s275
                            @BufferValClass = @tmpBuffer;   # SNOOPYJC
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
                     (undef,$groups_are_present)=is_regex($arg1,1);         # issue s131
                     ($modifier,undef)=is_regex($arg2,0); # modifies $source as a side effect, issue s131
                     my $fake_e_flag = 0;                                       # issue s131
                     if($groups_are_present && index($modifier, 're.E') < 0) {  # issue s131
                         if($modifier eq 'r' || length($modifier) == 0) {       # issue s131
                             $modifier = ',re.E';                               # issue s131
                         } else {                                               # issue s131
                             $modifier .= '|re.E';                              # issue s131
                         }                                                      # issue s131
                         $fake_e_flag = 1;                                      # issue s131
                     }                                                          # issue s131
                     if( length($modifier) > 1 ){
                        #regex with modifiers
                         $quoted_regex='re.compile('.put_regex_in_quotes($arg1, $delim, $original_regex, x_flag($modifier))."$modifier)";   # issue 111, issue s80
                     }else{
                        # No modifier
                        $quoted_regex=put_regex_in_quotes($arg1, $delim, $original_regex, 0);       # issue 111, issue s80
                     }
                     if( length($modifier)>0 ){
                        #this is regex
                        # issue s151 if( $tno>=1 && $ValClass[$tno-1] eq '~'   ){
                        if( $tno>=1 && $ValClass[$tno-1] eq 'p'   ){    # issue s151
                           # explisit s
                            if(index($modifier, 're.E') >= 0) {
                                if($fake_e_flag) {                                                              # issue s131
                                    $ValPy[$tno]='re.sub('.$quoted_regex.",e'''__expand(m$delim".$original_regex2."$delim)''',";    # issue s131
                                } else {
                                    $ValPy[$tno]='re.sub('.$quoted_regex.",e'''".$arg2."''',";
                                }
                            } else {
                                # $arg2 = escape_re_sub($arg2);                   # issue bootstrap
                                $ValPy[$tno]='re.sub('.$quoted_regex.','.put_regex_in_quotes($arg2, $delim, $original_regex2, 0, 1).','; #  double quotes neeed to be escaped just in case; issue 111, issue s80
                            }
                        }else{
                            if(index($modifier, 're.E') >= 0) {
                                if($fake_e_flag) {                                                                          # issue s131
                                    $ValPy[$tno]="re.sub($quoted_regex".",e'''__expand(m$delim".$original_regex2."$delim)''',$DEFAULT_VAR)";    # issue s131
                                } else {
                                    $ValPy[$tno]="re.sub($quoted_regex".",e'''".$arg2."''',$DEFAULT_VAR)";
                                }
                            } else {
                                # $arg2 = escape_re_sub($arg2);                   # issue bootstrap
                                $ValPy[$tno]="re.sub($quoted_regex".','.put_regex_in_quotes($arg2, $delim, $original_regex2, 0, 1).",$CONVERTER_MAP{S}($DEFAULT_VAR))";    # issue 32, issue 78, issue 111, issue s8, issue s80
                            }
                        }
                     }else{
                        # this is string replace operation coded in Perl as regex substitution
                        $ValPy[$tno]='str.replace('.$quoted_regex.','.$quoted_regex.',1)';
                     }
                  } elsif( $w eq 'qr' ) {               # SNOOPYJC: qr in other context
                     ($modifier,$groups_are_present)=is_regex($arg1,0);                           # SNOOPYJC, issue s131
                     $modifier='' if($modifier eq 'r');                                         # SNOOPYJC
                     my $x_flag = x_flag($modifier);                     # issue s80
                     ($arg1, $modifier) = build_in_qr_flags($arg1, $modifier);          # issue s3
                     $ValPy[$tno]='re.compile('.put_regex_in_quotes($arg1, $delim, $original_regex, $x_flag).$modifier.')';       # SNOOPYJC, issue 111
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
                  $arg1 = escape_non_printables(escape_only_backslash($arg1), 1);    # issue s23
                  $arg2 = escape_non_printables(escape_only_backslash($arg2), 1);    # issue s23
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
                         # issue s151 if( $tno>=1 && $ValClass[$tno-1] eq '~' ){
                         if( $tno>=1 && $ValClass[$tno-1] eq 'p' ){     # issue s151
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
                      # issue 44 $ValPy[$tno]='"'.$python.'".split()';  # issue 44: python split doesn't take a regex!
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
              ( $tno>2 && $ValPerl[$tno-1] eq '~' && $ValPerl[$tno-2] eq '<<' && index('sd)', $ValClass[$tno-3]) < 0)) {    # issue 39 - bare HereIs (and not a shift)
            $has_squiggle = ($ValPerl[$tno-1] eq '~');
            $tno--; # overwrite previous token; Dec 20, 2019 --NNB
            $tno-- if($has_squiggle);           # overwrite that one too!
            $ValClass[$tno]='"';        # issue 39
            $ValPerl[$tno]=substr($source,0,$cut);
            $ValPy[$tno]=Pythonizer::get_here($ValPerl[$tno], $has_squiggle);   # issue 39
            my $quote = substr($ValPy[$tno],3,length($ValPy[$tno])-6);  # issue 39: remove the """ and """
            interpolate_strings($quote, $quote, 0, 0, 0, 0);     # issue 39, issue s80
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
            # issue s62 $ValPy[$tno]='pdb.set_trace';
            $::Pyf{_set_breakpoint} = 1;                # issue s62
            $ValPy[$tno]='_set_breakpoint';             # issue s62
            $ValClass[$tno]='f';
            # issue s272 $cut=index($source,';');
            if($source =~ /\s((?:if|unless))\b/) {       # issue s272
                $cut = $-[1];                            # issue s272: start of first capture group
            } else {                                     # issue s272
                $cut=index($source,';');
            }                                            # issue s272
            substr($source,0,$cut)='perl_trace()'; # remove non-tranlatable part.
            $cut=length('perl_trace');
         }else{
            $end_br = 0;                                # issue 43
            #if(substr($source,1,1) eq '{') {       # issue 43: ${...}
            #$end_br = matching_curly_br($source, 1); # issue 43
            #$source = '$'.substr($source,2);   # issue 43: eat the '{'. At this point, $end_br points after the '}'
            #}
            my $s2=substr($source,1,1);                  # issue ws after sigil
            if($s2 eq '' || $s2 =~ /\s/) {               # issue ws after sigil
                $source = get_rest_of_variable_name($source, 0);
            }
            decode_scalar($source,1);
            if($tno!=0 &&                               # issue 50, issue 92
               (($ValClass[$tno-1] eq 's' && $ValPerl[$tno-1] eq '$') || # issue 50
                $ValClass[$tno-1] eq '@' || 
                # issue s246 ($ValClass[$tno-1] eq '%' && !$had_space))) {   # issue 50
                ($ValClass[$tno-1] eq '%' && ($tno-1 == 0 || !&Pythonizer::is_term($tno-2))))) {   # issue s246: depend on the prior token to distinguish MOD from % cast
               # Change $$xxx to $xxx, @$xxx to $xxx and %$yyy to $yyy but NOT % $yyy as that's a MOD operator!
               my $was = $ValClass[$tno-1];
               $TokenStr = join('',@ValClass);             # issue 50: replace doesn't work w/o $TokenStr
               replace($tno-1, $ValClass[$tno], $ValPerl[$tno], $ValPy[$tno]);  # issue 50
               popup();                         # issue 50
               $tno--;              # issue 50 - no need to change hashref to hash or arrayref to array in python
               $ValType[$tno] = $was . 's';         # issue s185: Remember what this was in ValType, e.g. 'ss' means it was a $$
               $ate_dollar = $tno;              # issue 50: remember where we did this
# issue s215               # issue s173: Set the type of the variable appropriately
# issue s215               my $cs = cur_sub();          # issue s173
# issue s215               my $type;                    # issue s173
# issue s215               $type = 'a' if $was eq '@';  # issue s173
# issue s215               $type = 'h' if $was eq '%';  # issue s173
# issue s215               #say STDERR "type was $Pythonizer::VarType{$ValPy[$tno]}{$cs}";   # TEMP
# issue s215               $Pythonizer::VarType{$ValPy[$tno]}{$cs} = &Pythonizer::merge_types($ValPy[$tno], $cs, $type) if(defined $type);   # issue s173, issue s215
               if($was eq '@' && &Pythonizer::in_sub_call($tno)) {      # issue bootstrap
                   $ValPy[$tno] = '*' . $ValPy[$tno];                   # Splat it
               #} elsif($::autovivification && $was eq '%' && $Pythonizer::VarType{$ValPy[$tno]}{$cs} !~ /^h/ && 
                   #(($tno-1 >= 0 && $ValClass[$tno-1] eq 'f') || ($tno-2 >= 0 && $ValClass[$tno-1] eq '(' && $ValClass[$tno-2] eq 'f'))) {  # issue s215
                   ## Passing a %$var to a function like keys with autovivification makes it spring to life as a Hash
                   #$::Pyf{Hash} = 1;                                                # issue s215
                   #$ValPy[$tno] = "($ValPy[$tno] if $ValPy[$tno] else Hash())";     # issue s215
               }
               # issue s224 $line_contained_array_conversion{$statement_starting_lno} = 1 if $ValPy[0] eq 'for' && $was eq '@';  # issue s137
               #$ValPerl[$tno]=$ValPy[$tno]=$s; # issue 50
            } elsif($tno != 0 && $ValClass[$tno-1] eq '*' && !$had_space && ($tno-1 == 0 || $ValClass[$tno-2] !~ /[sdfi)]/)) {  # issue s76
                # issue s76: *$tag = ... - here "$tag" contains the name of the typeglob
                my $name;
                if($::implicit_global_my) {
                    $name = 'globals()';
                } else {
                    $name = cur_package() . '.__dict__';
                }
                $ValType[$tno-1] = "X";
                $ValPy[$tno-1] = $name;
                $TokenStr = join('',@ValClass);             # insert/replace doesn't work w/o $TokenStr
                # Change it to *{$var}
                append(')', '}', ']');
                insert($tno, '(', '{', '[');
                $tno += 2;
            } elsif($tno != 0 && $ValClass[$tno-1] eq '\\' && $Pythonizer::PassNo==&Pythonizer::PASS_2 && !nonScalarRef() && !inRefOkFunction() &&
                !inRefOkSub($tno-1)) { # issue s169, issue s173, issue s185
                logme("W", "Reference to scalar $ValPerl[$tno] replaced with scalar value");
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
         $source = handle_use_english($source, \%ENGLISH_ARRAY) if $::uses_english;    # use English
         if( substr($source,1)=~/^(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)/ ){       # SNOOPYJC: Allow ' from old perl
            $arg1=$1;
            my $cs = cur_sub();
            if( $arg1 eq '_' ){
               $ValPy[$tno]="$PERL_ARG_ARRAY";  # issue 32
               $ValType[$tno]="X";
               $SpecialVarsUsed{'@_'}{$cs} = 1;                       # SNOOPYJC
            }elsif( $arg1 eq 'INC' || $arg1 eq '::INC' || $arg1 eq 'main::INC'  ){      # SNOOPYJC, issue s188
                  $ValPy[$tno]='sys.path';
                  $ValType[$tno]="X";
                  $SpecialVarsUsed{'@INC'}{$cs} = 1;                       # SNOOPYJC
            }elsif( $arg1 eq 'ARGV' || $arg1 eq '::ARGV' || $arg1 eq 'main::ARGV' ){    # issue s188
            # issue 49 $ValPy[$tno]='sys.argv';
                  $ValPy[$tno]='sys.argv[1:]';  # issue 49
                  $ValType[$tno]="X";
                  $SpecialVarsUsed{'@ARGV'}{$cs} = 1;                       # SNOOPYJC
            }else{
               my $arg2 = $arg1;
               $arg2=~tr/:/./s;
               $arg2=~tr/'/./s;          # SNOOPYJC
               $arg2 = remap_conflicting_names($arg2, '@', substr($source,length($arg1)+1,1));      # issue 92
               $arg2 = escape_keywords($arg2);      # issue 41
               if( $tno>=2 && $ValClass[$tno-2] =~ /[sd'"q]/  && $ValClass[$tno-1] eq '>'  ){
                  $ValPy[$tno]='len('.$arg2.')'; # scalar context   # issue 41
                  # SNOOPYJC: causes $i < @arr to make @arr into 'myfile' instead of 'global':  $ValType[$tno]="X";
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
         $source = handle_use_english($source, \%ENGLISH_HASH) if $::uses_english;    # use English
         # SNOOPYJC if( substr($source,1)=~/^(\:?\:?[_a-zA-Z]\w*(\:\:[_a-zA-Z]\w*)*)/ ){
         if( substr($source,1)=~/^(\:?\:?\'?[_a-zA-Z]\w*((?:(?:\:\:)|\')[_a-zA-Z]\w*)*)/ && # old perl used ' for ::
             ($tno == 0 || index('dsha)"', $ValClass[$tno-1]) == -1)){                 # issue s246: "...) % scalar(..." is a mod operator
            $cut=length($1)+1;
            $ValClass[$tno]='h'; #hash
            $ValPerl[$tno]=substr($source,0,1).$1;      # SNOOPYJC
            $ValPy[$tno]=$1;
            $ValPy[$tno] = 'ENV' if($ValPy[$tno] eq 'main::ENV' || $1 eq '::ENV');  # issue s188
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
         } elsif(substr($source,1,2) eq '::') {           # issue s176: This is %:: which is a main symbol table reference
             $cut = 1;
             $ValClass[$tno] = 'h';  # hash
             $ValPerl[$tno] = '%main';
             $ValPy[$tno] = 'builtins.main';
             $ValType[$tno] = "X";
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
         my $s2=substr($source,1,1);        # issue s246
         if($s2 eq '' || $s2 =~ /\s/) {     # issue s246
            $source = get_rest_of_variable_name($source,0); # issue s246
         }                                  # issue s246
         if( substr($source,1)=~/^(\:?\:?\'?[_a-zA-Z]\w*((?:(?:\:\:)|\')[_a-zA-Z]\w*)*)/){
            if(ampersand_is_sub_sigil()) {      # issue s152: distinguish & from &Sub
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
                $w = $1;                                    # issue s58
                my $core = 0;                          # SNOOPYJC
                if(substr($w,0,5) eq "CORE'") {        # SNOOPYJC
                    $w = substr($w,5);
                    $core = 1;
                } elsif(substr($w,0,6) eq 'CORE::') {  # SNOOPYJC
                    $w = substr($w,6);
                    $core = 1;
                }
                # issue s233 if(substr($w,0,5) eq "Carp'" && $w =~ /carp|confess|croak|cluck/) {    # SNOOPYJC, issue test coverage
                # issue s233 $w = substr($w,5);
                # issue s233 } elsif(substr($w,0,6) eq 'Carp::' && $w =~ /carp|confess|croak|cluck/) {      # SNOOPYJC, issue test coverage
                # issue s233 $w = substr($w,6);
                # issue s233 }
                if(substr($w,0,10) eq "UNIVERSAL'" && $w =~ /isa/) {    # issue s54, issue test coverage
                    $w = substr($w,10);
                } elsif(substr($w,0,11) eq 'UNIVERSAL::' && $w =~ /isa/) {      # issue s54, issue test coverage
                    $w = substr($w,11);
                }
                if( exists($TokenType{$w}) ){       # issue s58: Handle &Carp::cluck
                   $class=$TokenType{$w};
                   if($class eq 'F' && !$core && (exists $Pythonizer::UseSub{$w} || exists $Pythonizer::LocalSub{$w})) {     # SNOOPYJC, issue s190
                       $class = 'i';
                   } elsif($class eq 'F') {            # issue s190: convert weak function back to normal function
                        $class = 'f';                  # issue s190
                   }
                   if($class eq 'f' && !$core && exists $Pythonizer::UseSub{$w}) {     # issue s190: local sub does NOT override a function unless it's in a use subs
                        $class = 'i';
                   } elsif($class eq 'f' && exists $keyword_tr{$w}) {        # issue s190
                       $ValPy[$tno] = $keyword_tr{$w};
                   }
                   $ValClass[$tno] = $class;
               } else {
                    # We set a bit so LocalSub is True (and we don't change it to a string) but we can 
                    # still check if it's actually defined locally in add_package_name_sub
                    $Pythonizer::LocalSub{$ValPy[$tno]} |= 8;   
                    if(index($ValPy[$tno], cur_package()) != 0) {                           # issue s18: Don't store Child.Child.subname
                        $Pythonizer::LocalSub{cur_package() . '.' . $ValPy[$tno]} |= 8;          # issue s3
                    }
                    # issue 117 - if this is "&sub" with no parens, then pass along @_ (but not if it's a reference to the sub, and not in main)
                    if(cur_sub() ne '__main__' && ($tno == 0 || ($ValClass[$tno-1] ne "\\" && $ValPerl[$tno-1] ne 'defined')) && 
                       !($tno-2 >= 0 && $ValClass[$tno-1] eq '(' && $ValPerl[$tno-2] eq 'defined') &&
                       substr($source,$cut) !~ /^\s*\(/) {  # issue 117
                        if(($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) || $::debug >= 6){
                            say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
                        }
                        $tno++;
                        $ValClass[$tno]=$ValPerl[$tno]=$ValPy[$tno]='(';
                        if(($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) || $::debug >= 6){
                            say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
                        }
                        $tno++;
                        $ValClass[$tno]='a';
                        $ValPerl[$tno]='@_';
                        $ValType[$tno]="X";
                        $ValPy[$tno]="$PERL_ARG_ARRAY";
                        if(($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) || $::debug >= 6){
                            say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
                        }
                        $tno++;
                        $ValClass[$tno]=$ValPerl[$tno]=$ValPy[$tno]=')';
                    }
                }
            } else {                    # issue s152
                $cut = 1;               # issue s152
                if($Pythonizer::PassNo == &Pythonizer::PASS_2) {   # issue s152
                    logme('W', '& (bitwise and) operator is most likely not what the programmer intended before a bare word');  # issue s152
                }                       # issue s152
            }                           # issue s152
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

            # issue s188: Handle a few special cases:
            if($1 =~ /^(?:(?:main)?::)?(STD(?:IN|OUT|ERR))$/) {        # issue s188: Match like *STDIN *::STDIN *main::STDIN
                $ValPy[$tno] = $keyword_tr{$1};     # Note - this $1 is from the new match!
            }
            if( substr($ValPy[$tno],0,1) eq '.' ){
               $ValCom[$tno]='X';
               $ValPy[$tno]="$MAIN_MODULE$ValPy[$tno]";
            }
         } elsif(substr($source,1,1) eq '{') {           # issue s31
            # issue s31: Handle *{'name'} or *{"stuff"}
            my $name;
            if($::implicit_global_my) {
                $name = 'globals()';
            } else {
                $name = cur_package() . '.__dict__';
            }
            $ValClass[$tno]='s';
            $ValType[$tno] = "X";
            $ValPy[$tno]=$name;
            $cut=1;
         }else{
           $cut=1;
         }
      }elsif( $s eq '[' || $s eq '(' ){
         if($tno != 0 && $ValClass[$tno-1] eq 'D') {    # issue 50, issue 93
        popup();                            # issue 50
        $tno--;             # issue 50 - no need to keep arrow operator in python
            $ValPerl[$tno]=$ValPy[$tno]=$s; # issue 50
            $ValClass[$tno]='('; # we treat anything inside curvy backets as expression
            $cut=1;
         }elsif($s eq '(' && ($tno == 2 && $ValClass[0] eq 'k' && $ValPerl[0] eq 'sub' && $ValClass[1] eq 'i') ||
             $tno != 0 && $ValClass[$tno-1] eq 'k' && $ValPerl[$tno-1] eq 'sub') {                      # issue s26: handle sub () { ... }
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
            if($ValClass[$tno] eq '0'){     # && or ||
               # issue s77 $balance=(join('',@ValClass)=~tr/()//);
               # issue 93 if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && join('',@ValClass) !~ /^t?[ahs]=/ )  # SNOOPYJC
               # issue s77 if( ( $balance % 2 == 0 ) && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && bash_style_or_and_fix(3)){  # issue 93
               if( parens_are_balanced() && $ValClass[0] ne 'c' && $ValClass[0] ne 'C' && bash_style_or_and_fix(3)){  # issue 93, issue s77
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
           if( exists $DASH_X{$s2} && substr($source,2,1)=~/\s/ && substr($source,2) !~ /\s+=>/ ){  # issue s221 - don't do this for a hash key!
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
                   $FileHandles{$fh} = $. unless($fh eq '' || exists $keyword_tr{$fh} || exists $FileHandles{$fh}); # SNOOPYJC
               }                                # issue 66
               #
               # Let's try to determine the context
               #
           # issue 62 if( $tno==2 && $ValClass[0] eq 'a' && $ValClass[1] eq '='){
               if( $tno>=2 && $ValClass[$tno-2] eq 'a' && $ValClass[$tno-1] eq '='){    # issue 62: handle "my @a=<FH>;" and "chomp(my @a=<FH>);"
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
                       my $escaped = escape_keywords($fh);              # issue s25
                       $ValPy[$tno]="$rl($escaped)";                         # issue 66, issue s25
                   }
               }else{           # we're just reading one line so we can't use the context manager as it closes the file handle
                   if(length($fh)==0){         # issue 66
               # issue bootstrap $ValPy[$tno]="next(fileinput.input(), None)";        # issue 66: Allows for $.
               $::Pyf{_fileinput_next} = 1;     # issue bootstrap
               $::Pyf{'_fileinput_next()'} = 1;     # issue bootstrap - this line is so that _fileinput_next() is replaced with perllib.fileinput_next()
                       $ValPy[$tno]="_fileinput_next()";        # issue bootstrap, issue 66: Allows for $.
                   }elsif($fh eq 'STDIN' ){     # issue 66
                       # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                       # issue 66 $ValPy[$tno]='sys.stdin().readline()';
                       my $rl = select_readline();                      # issue 66
                       $ValPy[$tno]="$rl(sys.stdin)";                 # issue 66: support $/, issue s188: Remove the extra ()
                       # $ValPy[$tno]="next(with fileinput.input('-'), None)";        # issue 66: Allows for $.
                   }else{
                       # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                       # issue 66 $ValPy[$tno]="$fh.readline()";
                       my $rl = select_readline();                      # issue 66
                       my $escaped = escape_keywords($fh);              # issue s25
                       $ValPy[$tno]="$rl($escaped)";           # issue 66: support $/, issue s25
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
               if( $tno>=2 && $ValClass[$tno-2] eq 'a' && $ValClass[$tno-1] eq '='){    # issue 62: handle "my @a=<FH>;" and "chomp(my @a=<FH>);"
                   $ValPy[$tno]="$1.readlines()";
               }elsif($ValClass[0] eq 'c' and $ValPerl[0] eq 'while') { # issue 66
                   # issue 66 insert(0, 'W', "<$1>", qq{with fileinput.input("<$1>",openhook=lambda _,__:$1) as $DIAMOND:});    # issue 66
                   # issue 66 $tno++;                                     # issue 66
                   # issue 66 $ValPy[$tno]="next($DIAMOND, None)";        # issue 66: Allows for $.
                   my $rl = select_readline();                      # issue 66
                   my $mapped_name = remap_conflicting_names($1, '$', '');      # issue s25
                   my $escaped = escape_keywords($mapped_name);                 # issue s25
                   $ValPy[$tno]="$rl($escaped)";                # issue 66: Support $/, $., issue s25
               }else{
                   # Here we choose between not supporting $. and possibly getting an error for trying use fileinput twice
                   # issue 66 $ValPy[$tno]="$1.readline()";
                   my $rl = select_readline();                      # issue 66
                   my $mapped_name = remap_conflicting_names($1, '$', '');      # issue s25
                   my $escaped = escape_keywords($mapped_name);                 # issue s25
                   $ValPy[$tno]="$rl($escaped)";                # issue 66: Support $/, $., issue s25
                   # issue 66: use a context manager so it's automatically closed
                   #insert(0, 'W', "<$1>", qq{with fileinput.input("<$1>",openhook=lambda _,__:$1) as $DIAMOND:});    # issue 66
                   #$tno++;                                     # issue 66
                   #$ValPy[$tno]=qq{next(with fileinput.input("<$1>",openhook=lambda _,__:$1), None)};        # issue 66: Allows for $.
               }
            }elsif($tno > 0 && (index("(.=,", $ValClass[$tno-1]) >= 0 || bracketed_function_end($tno-1)) && $source =~ /^<[^>]+>/) {    # issue 66 <glob>, issue s135, ussye s249: add ',' to list of possible prev tokens
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
              $ValClass[$tno] = 'd';            # issue 23
          $ValPy[$tno] = $ValPerl[$tno] = $1;       # issue 23
          $cut=length($1);              # issue 23
                  # SNOOPYJC: If this is the second string of digits, merge it with the first
                  if($tno != 0 && $ValClass[$tno-1] eq 'd' && $ValPy[$tno-1] =~ /^(\d+)\.(\d+)$/) { # e.g. 102.111 .112
                      $ValClass[$tno-1] = '"';
                      $ValPerl[$tno-1] .= $ValPerl[$tno];
                      $ValPy[$tno-1] = perl_hex_escapes_to_python(sprintf('\'\\x{%x}\\x{%x}', int($1), int($2)));
                      $ValPy[$tno-1] .= perl_hex_escapes_to_python(sprintf('\\x{%x}\'', int(substr($ValPy[$tno],1))));
                      popup();
                      $tno--;
                  } elsif($tno != 0 && $ValClass[$tno-1] eq '"') {      # e.g. v1 .20
                      $ValPy[$tno-1] = substr($ValPy[$tno-1],0,length($ValPy[$tno-1])-1) . 
                        perl_hex_escapes_to_python(sprintf('\\x{%x}\'', int(substr($ValPy[$tno],1))));
                      $ValPerl[$tno-1] .= $ValPerl[$tno];
                      popup();
                      $tno--;
                  }
               } elsif( $source =~ /^[.][.][.]/ ) {             # issue elipsis
                   $ValClass[$tno] = 'k';
                   $ValPerl[$tno] = '...';
                   $ValPy[$tno] = "raise NotImplementedError('Unimplemented')";
                   $cut = 3;
           } elsif( $source =~ /^[.][.]/ ) {        # issue range
          $ValClass[$tno] = 'r';            # issue range
          $ValPerl[$tno] = '..';            # issue range
          $ValPy[$tno] = '..';              # issue range - not quite right but we have to handle specially
          $cut = 2;
           } else {                     # issue 23
          $cut=1;                   # issue 23
           }                        # issue 23
            }elsif( $s eq '<'  ){
               $ValClass[$tno]='>';
           $cut=1;                      # issue 23
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
           $cut=1;                      # issue 23
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
          # issue s173: Set the type of the variable appropriately
          my $cs = cur_sub();          # issue s173
          my $type;                    # issue s173
          $type = 'a' if defined $ValType[$tno] && $ValType[$tno] eq '@s';  # issue s173
          $type = 'h' if defined $ValType[$tno] && $ValType[$tno] eq '%s';  # issue s173
          #say STDERR "type was $Pythonizer::VarType{$ValPy[$tno]}{$cs}";   # TEMP
          $Pythonizer::VarType{$ValPy[$tno]}{$cs} = &Pythonizer::merge_types($ValPy[$tno], $cs, $type) if(defined $type);   # issue s173, issue s215
          if($::autovivification && defined $type && $type eq 'h' && $Pythonizer::VarType{$ValPy[$tno]}{$cs} !~ /^h/ && 
              (($tno-1 >= 0 && $ValClass[$tno-1] eq 'f') || ($tno-2 >= 0 && $ValClass[$tno-1] eq '(' && $ValClass[$tno-2] eq 'f'))) {  # issue s215
              # Passing a %$var to a function like keys with autovivification makes it spring to life as a Hash
              $::Pyf{Hash} = 1;                                                # issue s215
              my $perllib = $::import_perllib ? "$PERLLIB." : '';              # issue s215
              $ValPy[$tno] = "($ValPy[$tno] if $ValPy[$tno] is not None else ${perllib}Hash())";     # issue s215
          }
      } elsif($ValClass[$tno] eq 'j') {     # SNOOPYJC
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
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'use' && $ValPerl[1] eq 'Switch') {       # issue s129
            handle_use_Switch();                                                                # issue s129
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'use' && $ValPerl[1] eq 'parent') {       # issue s18
            handle_use_parent();                                                                # issue s18
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'use' && $ValPerl[1] eq 'utf8') {         # issue s70
            handle_use_utf8() if($Pythonizer::PassNo == &Pythonizer::PASS_1);                   # issue s70
        } elsif($ValClass[0] eq 'k' && ($ValPerl[0] eq 'use' || $ValPerl[0] eq 'require')) {    # issue names
            handle_use_require(0);                                                              # issue names
        } elsif($ValClass[0] eq 'C' && $ValPerl[0] eq 'do' && $#ValClass != 0) {    # issue s231
           handle_use_require(0);                                                   # issue s231
        # issue s18 } elsif($#ValClass == 3 && $ValClass[0] eq 't' && $ValClass[1] eq 'a' && $ValPerl[1] eq '@ISA' && $ValClass[2] eq '=' && $ValClass[3] eq 'q' && cur_sub() eq '__main__') { # issue s3
        # issue s18     $SpecialVarsUsed{'@ISA'}{__main__} = $ValPy[3];             # issue s3
        } elsif($ValClass[0] eq 't' && $ValClass[1] eq 'a' && $ValPerl[1] eq '@ISA' && $ValClass[2] eq '=' && cur_sub() eq '__main__') { # issue s3, issue s18
            handle_ISA_assignment(2);               # issue s18
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'return') {
            handle_return();    # issue s30
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
            } elsif($ValClass[0] eq 'c' && $ValPerl[0] eq 'while' && $ValClass[$i] eq 'f' && exists $WHILE_MAGIC_FUNCTIONS{$ValPerl[$i]}) {       # issue s40
                $i = handle_while_magic_function($i);                                            # issue s40
            } elsif($ValClass[$i] eq 'C' && $ValPerl[$i] eq 'do' && $i+1 <= $#ValClass) {       # issue s231
                handle_use_require($i);                                                         # issue s231
            }
        }
        $TokenStr=join('',@ValClass);
        # issue s151 my $pgx = index($TokenStr, 's~q');      # SNOOPYJC: Possible 'pos' generator
        my $pgx = index($TokenStr, 'spq');      # SNOOPYJC: Possible 'pos' generator, issue s151
        if($pgx >= 0) {
            $scalar_pos_gen_line{$ValPerl[$pgx]} = $.;
        }
   }

   $TokenStr=join('',@ValClass);
   my $f = substr($TokenStr,0,1);               # issue implicit conditional return
   if($f eq 'C') {                      # issue implicit conditional return
       ;            # Do nothing on else/elsif
   } elsif($f =~ /[ck]/ && $ValClass[0] =~ /^(?:if|unless|given|when|return)$/) {    # issue implicit conditional return, issue s263
       my $csn = cur_sub_level();
       if($nesting_level == $csn+1 && $Pythonizer::PassNo == &Pythonizer::PASS_1) { # issue s79
           my $cs = cur_sub();
           delete $sub_lines_contain_potential_last_expression{$cs};
           $last_expression_lno = 0;
       }
       $last_expression_lno = 0 if($last_expression_level == $nesting_level || $last_expression_level+1 == $nesting_level);
       say STDERR "Deleting level_block_lnos{".($nesting_level+1)."} on |$TokenStr|" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0); # issue s79
       delete $level_block_lnos{$nesting_level+1};                                                      # issue s79
   } elsif($TokenStr ne '' && $TokenStr ne '}' && $TokenStr ne '{') { # issue implicit conditional return
       if(in_loop()) {
           $last_expression_lno = 0;
       } else {
           $last_expression_lno = $statement_starting_lno;
           $last_expression_level = $nesting_level;
       }
       say STDERR "Deleting level_block_lnos{".($nesting_level+1)."} on |$TokenStr|" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
       delete $level_block_lnos{$nesting_level+1};
       my $expr_level = $nesting_level;         # issue s263
       if($f eq 'c' && $ValPerl[0] =~ /^(?:foreach|for|while|until)$/) {       # issue s263
           # issue s263: On a loop start, we already entered the block, so we also need to delete the
           # level_block_lnos for the prior nesting level
           say STDERR "Deleting level_block_lnos{".($nesting_level)."} on |$TokenStr| with $ValClass[0]" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);   # issue s263
           delete $level_block_lnos{$nesting_level};        # issue s263
           $expr_level--;                                   # issue s263
       }
       my $cs = cur_sub();
       my $csn = cur_sub_level();
       # issue s263 if($nesting_level == $csn+1 && $Pythonizer::PassNo == &Pythonizer::PASS_1) { # issue s79
       if($expr_level == $csn+1 && $Pythonizer::PassNo == &Pythonizer::PASS_1) { # issue s79, issue s263
           if($last_expression_lno == 0) {
               delete $sub_lines_contain_potential_last_expression{$cs};
           } else {
               #$sub_lines_contain_potential_last_expression{$cs} = $last_expression_lno;
           }
           my $next_t = &Pythonizer::next_same_level_tokens('0oc', 0, $#ValClass);   # issue s79
           if($next_t < 0 || $ValPy[$next_t] =~ /while|for/) {       # issue s79
               # issue s79: Don't track this expression as a "last expression" unless it contains a top-level and/or
               # or contains a trailing if/unless
               $last_expression_lno = 0;                    # issue s79
           }
       }
   }
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
       my @tmpBuffer = @BufferValClass; # Issue 7
       @BufferValClass = ();        # Issue 7
       if((2 <= $#ValClass && $ValClass[0] eq 'h' && $ValClass[1] eq '=' && $ValClass[2] eq '(') ||
          (3 <= $#ValClass && $ValClass[0] eq 't' && $ValClass[1] eq 'h' && $ValClass[2] eq '=' && $ValClass[3] eq '(')) {     # issue s228
          # issue s228: In hash assignments only, which could be long, try to keep the comments where they were
          while(defined ($source=Pythonizer::getline(2))) {
              if($source =~ /^\s*$/ || $source =~ /^\s*#/) {            # blank or comment only line
                  $ValCom[$#ValClass] .= "\n$source";
              } else {
                  last;
              }
          }
       } else {                                 # issue s228
           $source=Pythonizer::getline();
       }
       $StatementStartingLno{$.} = $statement_starting_lno;    # issue s275
       @BufferValClass = @tmpBuffer;    # Issue 7
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
   if(($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) || $::debug >= 6){
     say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
   }
   $tno++;
   if($ExtractingTokensFromDoubleQuotedStringEnd > 0) {               # SNOOPYJC
       $ExtractingTokensFromDoubleQuotedTokensEnd -= $cut;
       $ExtractingTokensFromDoubleQuotedStringEnd -= $cut;
       say STDERR "finish2: ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd, source=$source" if($::debug>=5);
       if($ExtractingTokensFromDoubleQuotedTokensEnd <= 0) {
           $ValClass[$tno] = '"';
           if(defined $source) {
                my $quote=substr($source,0,$ExtractingTokensFromDoubleQuotedStringEnd);
                my $p_tno = $tno;                                           # issue s114
                $cut = extract_tokens_from_double_quoted_string($quote, 0, 0);      # issue s80
                $ExtractingTokensFromDoubleQuotedStringEnd -= $cut;
                if($ExtractingTokensFromDoubleQuotedStringEnd <= 0 && $cut != 0 && ($p_tno == $tno || $ValClass[$tno-1] eq '"')) {       # issue s114
                    $tno--;
                    $cut = length($source) if $cut > length($source);   # Don't cut past the end
                    say STDERR "finish2: recursing" if($::debug>=5);
                    finish();           # Try again as we may read in another line
                } else {
                    say STDERR "finish2: source=$source, cut=$cut" if($::debug>=5);
                    substr($source,0,$cut)='';
                    say STDERR "finish2: source=$source (after cut)" if($::debug>=5);
                    if($p_tno != $tno && $ValClass[$tno-1] ne '"' && $ExtractingTokensFromDoubleQuotedStringEnd <= 0) { # issue s114
                        $cut = extract_tokens_from_double_quoted_string('', 0, 0);          # issue s114, issue s80
                        substr($source,0,$cut)='';                                          # issue s114
                        say STDERR "finish3: source=$source (after cut)" if($::debug>=5);   # issue s114
                    }                                                                       # issue s114
                }
                say STDERR "finish2: ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd (after cut)" if($::debug>=5);
            } else {
                say STDERR "finish2: no source - calling extract_tokens_from_double_quoted_string('', 0)" if($::debug>=5);
                $cut = extract_tokens_from_double_quoted_string('', 0, 0);      # issue s80
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
my $split=$_[0];                # Position in source!!
   return 0 if($Pythonizer::PassNo!=&Pythonizer::PASS_2); # SNOOPYJC
   my $cs = cur_sub();                                                      # issue s79
   #say STDERR "bash_style_or_and_fix $cs line $statement_starting_lno $sub_lines_contain_potential_last_expression{$cs}";
   if(exists $sub_lines_contain_potential_last_expression{$cs}) {     # issue s79: don't split return a || b
       my @lnos = split /,/, $sub_lines_contain_potential_last_expression{$cs};   # issue s79
       foreach my $l (@lnos) {                                              # issue s79
           return 0 if($l == $statement_starting_lno);                      # issue s79
       }                                                                    # issue s79
   }                                                                        # issue s79
   return 0 if exists $line_modifies_foreach_counter{$.};                   # issue s252: We can't handle the array assignment if the line is split up
   # bash-style conditional statement, like ($debug>0) && ( line eq ''); Aug 10, 2020 --NNB
   $is_or = ($ValPy[-1] =~ /or/);   # issue 12
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
   # $split is a position in $source, not an index in @ValClass!!
   # issue s137 if($split > $#ValClass) {              # issue ddts: no code before the || (was an eval)
   if(@ValClass == 1) {     # issue s137, issue ddts: no code before the || (was an eval)
       # issue s137 say STDERR "bash_style_or_and_fix($split) returning 0 - split is past the end!" if($::debug>=3);
       say STDERR "bash_style_or_and_fix($split) returning 0 - nothing before the or/and!" if($::debug>=3);
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
   # issue s207: Don't transform it if we're in the midst of an unparenthesized function call like bless $self, $this || $that;
   $TokenStr=join('',@ValClass); # replace or end_of_function will not work without $TokenStr
   for(my $p = 0; $p < $#ValClass; $p++) {                      # issue s207
       if($ValClass[$p] eq 'f') {
           my $eof = &Pythonizer::end_of_function($p);
           if($eof >= $#ValClass) {
              say STDERR "bash_style_or_and_fix($split) returning 0 - operator is in a function call" if($::debug>=3);
              return 0;
           }
       }
   }

   Pythonizer::getline('{');
   # issue 86 $delayed_block_closure=1;
   $delayed_block_closure++;            # issue 86
   if( $split<length($source) ){
      Pythonizer::getline(substr($source,$split)); # at this point processing contines untill th eend of the statement
   }
   $source='';
   if( $ValClass[0] eq '(' && $ValClass[-2] ){
      destroy(-1);
   }else{
      replace($#ValClass,')',')',')'); # we need to do this befor insert as insert changes size of array and makes $tno invalid
      insert(0,'(','(','(');
   }
   if($is_or) {             # issue 12
      insert(0,'n','not','not');    # issue 12, issue 93
      insert(0,'(','(','(');        # issue 12
      append(')',')',')');      # issue 12
   }                    # issue 12
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
my $in_regex=(scalar(@_) >= 4 ? $_[3] : 0);     # issue bootstrap
my $rc=-1;
   if ( $update  ){
      $ValClass[$tno]='s'; # we do not need to set it if we are analysing double wuoted literal
   }
   my $cut_adjust = 0;      # use English
   ($source, $cut_adjust) = handle_use_english($source, \%ENGLISH_SCALAR) if $::uses_english;
   my $s2=substr($source,1,1);
   my $specials = q(!?<>()!;]&`'+-"@$|/,\\%=~^:*);             # issue 50, SNOOPYJC, issue s140
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
       $cut=2+$cut_adjust;                  # use English
   }elsif( $s2 eq '^'  && substr($source,2,1) =~ /[A-Z]/ ){     # SNOOPYJC
       $s3=substr($source,2,1);
       $cut=3+$cut_adjust;      # use English
       $ValType[$tno]="X";
       my $vn = substr($source,0,3);                    # SNOOPYJC
       my $full = 0;
       if($source =~ /^..(\w+)/ && exists $SPECIAL_VAR_FULL{$1}) {                      # issue s23
           $ValPy[$tno] = $SPECIAL_VAR_FULL{$1};
           $vn = '$^' . $1;
           $cut = length($vn)+$cut_adjust;      # use English
           $full = 1;
       }
       my $cs = cur_sub();
       $SpecialVarsUsed{$vn}{$cs} = 1;                       # SNOOPYJC
       $ValPerl[$tno]=$vn if($update);                  # SNOOPYJC
       if( !$full && $s3=~/\w/  ){              # issue s23
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
   }elsif( index($specials,$s2) > -1 && substr($source,1,2) ne '::' ){  # issue 46, issue 50, SNOOPYJC ($:: is not $:)
      $ValPy[$tno]=$SPECIAL_VAR{$s2};
      $cut=2+$cut_adjust;       # use English
      $ValType[$tno]="X";
      my $vn = substr($source,0,2);                     # SNOOPYJC
      my $svar = $vn;                                   # SNOOPYJC
      my $nxc = length($source) >= 2 ? substr($source,2,1) : '';                    # SNOOPYJC
      $svar = '@' . substr($svar,1) if($nxc eq '[');    # SNOOPYJC
      $svar = '%' . substr($svar,1) if($nxc eq '{');    # SNOOPYJC
      if($svar eq '%+') {          # issue s16
          $ValPy[$tno] = "$DEFAULT_MATCH.group";        # issue s16: %+ is different than @+
      } elsif($svar eq '$+') {      # issue s274: $+ is different than @+
          $ValPy[$tno] = "$DEFAULT_MATCH.group($DEFAULT_MATCH.lastindex)";  # issue s274
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
          $ValPy[$tno]="$DEFAULT_MATCH.group($1)";      # issue 32
       }
       $cut=length($1)+1+$cut_adjust;   # use English
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
          if( $1 eq 'ARGV' || $1 eq '::ARGV' || $1 eq 'main::ARGV'  ){     # SNOOPYJC: Generate proper code for $#ARGV, issue s188
              $ValType[$tno]="X";                   # issue 14
              $ValPy[$tno] ='(len(sys.argv)-2)';    # SNOOPYJC
          } elsif( $1 eq 'INC' || $1 eq '::INC' || $1 eq 'main::INC' ){                  # SNOOPYJC, issue s188
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
              my $sig = '@';            # issue s222
              # issue s222 my $mapped_name = remap_conflicting_names($name, '@', '');      # issue 92, issue s14
              if($source =~ /^..\$/ || $source =~ /^..\{\$/) {  # issue s222
                  $sig = '$';                                   # issue s222
                  $ate_dollar = $tno;                           # issue s222
              }                                                 # issue s222
              my $mapped_name = remap_conflicting_names($name, $sig, '');      # issue 92, issue s14, issue s222
              $mapped_name = escape_keywords($mapped_name); # issue bootstrap
              $ValPy[$tno]='(len('.$mapped_name.')-1)';       # SNOOPYJC
          }
          # SNOOPYJC $cut=length($1)+2;
          $cut=length($&);                          # SNOOPYJC
      }
  # SNOOPYJC }elsif( $source=~/^.(\w*(\:\:\w+)*)/ ){
  }elsif(substr($source,1,3) eq '::{') {            # issue s176: $::{key} is a reference to the package symbol table
      $cut=1;
      if($::implicit_global_my) {
          $cut = 3;                 # Cut out the '.__dict__' coming up
          $name = 'globals()';
      } else {
          $name = 'builtins.main';
      }
      $ValType[$tno] = "X";
      $ValPy[$tno] = $name;
      if($update) {
          $ValPerl[$tno] = '$';
      }
      $rc = 1;
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
      } elsif($name =~ /^(?:main)?::(ENV|ARGV|INC)$/) {            # issue s188
          $name = $1;       # Note: This $1 is from this new match
      }
      $ValPy[$tno]=$name;

      if( $update ){
         $ValPerl[$tno]=substr($source,0,$cut);
      }
      my $next_c = '';
      if($ate_dollar == $tno || ($tno!=0 &&                               # issue 50, issue 92
           ($ValClass[$tno-1] eq '@' ||               # issue bootstrap: handle @$arrref[0]
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
         } elsif(substr($source,$cut,3) eq '::{') {        # issue s176: Symbol Table reference coming up next!
            $name=~tr/:/./s;            # SNOOPYJC
            $name = escape_keywords($name); 
            $ValPy[$tno] = 'builtins.' . $name;
            $ValType[$tno]="X";
            $rc=1 #regular var
         }else{
            # SNOOPYJC substr($name,$k,2)='.';
            #
            # issue s150: We took this fix out in favor of doing an _init_package('Getopt.Long') in _preprocess_arguments
            #             because it broke the Data.Dumper.xxx options initialization in issue_bootstrap
            #
            #my $rk = rindex($name, '::');                   # issue s150
            #my $prefix = substr($name, 0, $rk);             # issue s150
            #if(exists $BUILTIN_LIBRARY_SET{$prefix}) {      # issue s150: like $Getopt::Long::ignorecase
            #if($tno != 0) {                             # issue s150
            #$ValClass[$tno] = 'd' if($update);      # issue s150
            #$ValPy[$tno] = '0';                     # issue s150
            #} elsif($nesting_level != 0) {              # issue s150
            #$ValPy[$tno] = "pass     #SKIPPED $name"; # issue s150
            #} else {                                    # issue s150
            #$ValPy[$tno] = "#SKIPPED $name";        # issue s150
            #}                                           # issue s150
            #} else {                                        # issue s150
            $name=~tr/:/./s;            # SNOOPYJC
            $name=~tr/'/./s;            # SNOOPYJC
            $ValPy[$tno]=$name;         # issue s252: for_loop_local_ctr checks this
            $name = remap_conflicting_names($name, '$', $next_c);      # issue 92
            $name = escape_keywords($name);
            $ValPy[$tno]=$name;
            #}                                               # issue s150
            $rc=1 #regular var
         }
     } elsif( ($k=index($name,"'")) > -1 ){             # Old perl uses ' for ::
         # SNOOPYJC $ValType[$tno]="X";
         if( $k==0 || substr($name,$k) eq 'main' ){
            substr($name,0,1)="$MAIN_MODULE.";
            $name=~tr/:/./s;            # SNOOPYJC
            $name=~tr/'/./s;            # SNOOPYJC
            $ValPy[$tno]=$name;         # issue s252: for_loop_local_ctr checks this
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
               $ValPy[$tno]="$PERL_ARG_ARRAY".'['.$2.']';   # issue 32
               $cut=length($1)+$cut_adjust;     # use English
               $SpecialVarsUsed{'@_'}{$cs} = 1;                      # SNOOPYJC
            }elsif(substr($source,2,1) eq '[' && (!$in_regex || substr($source,3,1) =~ m'[\d$]')) { # issue 107: Vararg, issue bootstrap
               $ValPy[$tno]=$PERL_ARG_ARRAY;                    # issue 107
               $cut=2+$cut_adjust;                                          # issue 107, use English
               $SpecialVarsUsed{'@_'}{$cs} = 1;                      # issue 107
            }else{
               $ValPy[$tno]="$DEFAULT_VAR";         # issue 32
               $cut=2+$cut_adjust;      # use English
               $SpecialVarsUsed{'$_'}{$cs} = 1;                      # SNOOPYJC
            }
         }elsif( $s2 eq 'a' || $s2 eq 'b' ){
            # SNOOPYJC $ValType[$tno]="X";
        # issue 32 $ValPy[$tno]='perl_sort_'.$s2;
            $ValPy[$tno]="$PERL_SORT_$s2";  # issue 32
            $cut=2;
         }else{
            $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '$', $next_c);      # issue 92
            $rc=1 #regular var
         }
     } elsif(substr($source,$cut,3) eq '::{') {        # issue s176: Symbol Table reference coming up next!
            $name = escape_keywords($name); 
            $ValPy[$tno] = 'builtins.' . $name;
            $ValType[$tno]="X";
            $rc=1 #regular var
      }else{
        # this is a "regular" name with the length greater then one
        # $cut points to the next symbol after the scanned part of the scapar
           # check for Perl system variables
           my $cs = cur_sub();
           if( $name eq 'ENV'  ){       # issue s188
              $ValType[$tno]="X";
              $ValPy[$tno]='os.environ';
              $SpecialVarsUsed{'%ENV'}{$cs} = 1;                       # SNOOPYJC
           }elsif( $name eq 'INC' ) {                # SNOOPYJC        # issue s188
              $ValType[$tno]="X";
              $SpecialVarsUsed{'@INC'}{$cs} = 1;                       # SNOOPYJC
              $ValPy[$tno]='sys.path';
           }elsif( $name eq 'ARGV'  ){     # issue s188
              $ValType[$tno]="X";
              if($cut < length($source) && substr($source,$cut,1) eq '[') {    # $ARGV[...] is a reference to @ARGV
                  $SpecialVarsUsed{'@ARGV'}{$cs} = 1;                       # SNOOPYJC
              $ValPy[$tno]='sys.argv[1:]';
              } else {
                  $SpecialVarsUsed{'$ARGV'}{$cs} = 1;                       # SNOOPYJC
                  $ValPy[$tno]='fileinput.filename()';  # issue 49: Differentiate @ARGV from $ARGV, issue 66
              }
           }else{
             $ValPy[$tno] = remap_conflicting_names($ValPy[$tno], '$', $next_c);      # issue 92
             $ValPy[$tno] = escape_keywords($ValPy[$tno]);  # issue 41
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
# Arg1: regex
# Arg2: 1 if this is the first part of a s/.../.../ 
{
my $myregex=$_[0];
my $first_s = $_[1];                                # issue s131
my (@temp,$sym,$prev_sym,$i,$modifier,$meta_no);
   $modifier='r';
   if( !$first_s && $source=~/^(\w+)/ ){            # issue s131
     $source=substr($source,length($1)); # cut modifier
     $modifier='';
     @temp=split(//,$1);
      for( $i=0; $i<@temp; $i++ ){
         # issue 11 $modifier.=',re.'.uc($temp[$i]);
         next if($temp[$i] eq 'o');             # issue s3 - ignore the 'o' flag (compile once)
         $modifier.='|re.'.uc($temp[$i]);   # issue 11
     }#for
     if( $modifier ne '' ) { $modifier =~ s/^\|/,/; } # issue 11
     $regex=1;
     $cut=0;
   }
   my $cs = cur_sub();              # issue s140
   if(exists $SpecialVarsUsed{'$*'} && exists $SpecialVarsUsed{'$*'}{$cs}) {    # issue s140
       if($modifier eq '' || $modifier eq 'r') {                                # issue s140
           $modifier = ",re.M|re.S if $SPECIAL_VAR{'*'} else 0";                # issue s140
       } else {                                                                 # issue s140
           $modifier = "$modifier|re.M|re.S if $SPECIAL_VAR{'*'} else " . substr($modifier,1);  # issue s140
       }                                                                        # issue s140
       if(!exists $Pythonizer::initialized{$cs}{$SPECIAL_VAR{'*'}}) {           # issue s140
           $Pythonizer::NeedsInitializing{$cs}{$SPECIAL_VAR{'*'}} = 'I';        # issue s140
       }                                                                        # issue s140
   }                                                                            # issue s140
   @temp=split(//,$myregex);
   $prev_sym='';
   $meta_no=0;
   # issue s140 my $cs = cur_sub();          # issue s3
   for( $i=0; $i<@temp; $i++ ){
      $sym=$temp[$i];
      if( $prev_sym ne '\\' && $sym eq '(' && !($temp[$i+1] eq '?' && $temp[$i+2] eq ':')){    # issue s131: (?:...) is not capturing
         if ($modifier eq '') { $modifier = 'r'; } # Issue s230
         say STDERR "is_regex($myregex,$first_s) = ($modifier, 1)" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
         return($modifier,1);
      }elsif($prev_sym eq '$' && substr($myregex,$i) =~ /^(\w+)/) {         # issue GPT regex: assume any variable can contain groups!!
          # issue GPY regex:  && exists $Pythonizer::VarType{$1} &&  # issue s3 - if this contains a variable ref, and that is a regex var, then assume it has groups
          # issue GPY regex:       ((exists $Pythonizer::VarType{$1}{$cs} &&  $Pythonizer::VarType{$1}{$cs} eq 'R') ||
          # issue GPY regex:       (exists $Pythonizer::VarType{$1}{__main__} &&  $Pythonizer::VarType{$1}{__main__} eq 'R'))) { 
         if ($modifier eq '') { $modifier = 'r'; } # Issue s230
         say STDERR "is_regex($myregex,$first_s) = ($modifier, 1)" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
         return($modifier,1);           # issue s3
      # issue s230 }elsif( $prev_sym ne '\\' && index('.*+()[]?^$|',$sym)>=-1 ){
      }elsif( $prev_sym ne '\\' && index('.*+()[]?^$|',$sym)>-1 ){      # issue s230
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
      if ($modifier eq '') { $modifier = 'r'; } # Issue 10
      say STDERR "is_regex($myregex,$first_s) = ($modifier, 0)" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
      return ($modifier, 0);    # issue 11
   }
   # issue 11 return('',0);
   say STDERR "is_regex($myregex,$first_s) = ($modifier, 0)" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
   return($modifier,0);     # issue 11
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
   ($modifier,$groups_are_present)=is_regex($myregex,0);          # Returns 'r' for modifier for regex with no flags, issue s131
   my $cs = cur_sub();
   if((exists $SpecialVarsUsed{'@-'} && exists $SpecialVarsUsed{'@-'}{$cs}) ||
      (exists $SpecialVarsUsed{'@+'} && exists $SpecialVarsUsed{'@-'}{$cs})) {  # SNOOPYJC
       $groups_are_present = 1          # SNOOPYJC: Enable so we set _m:=...  We don't want to set it if it's not needed because
                                        # there could be a prior search with it set, and a reference to like $1 below THIS search.
   }
   if($::debug > 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
       say STDERR "perl_match($myregex, $delim, $original_regex): modifier=$modifier, groups_are_present=$groups_are_present";
   }
   my $s_rhs = 0;                               # issue s131
   if($tno>=2 && $ValClass[$tno-1] eq '(' && $ValClass[$tno-2] eq 'f' && $ValPerl[$tno-2] eq '__expand') {  # issue s131
       $s_rhs = 1;                              # issue s131
   }                                            # issue s131
   if( length($modifier) > 1 ){
      #regex with modifiers
      $quoted_regex='re.compile('.put_regex_in_quotes($myregex, $delim, $original_regex, x_flag($modifier), $s_rhs).$modifier.')';  # issue 111, issue s80, issue s131
      return $quoted_regex if($ValClass[0] eq 'c' && $ValPy[0] eq 'when');           # issue s129
      return $quoted_regex if $tno >= 1 && $ValClass[$tno-1] eq 'M';                # issue s251: ~~
   }else{
      # No modifier
      $quoted_regex=put_regex_in_quotes($myregex, $delim, $original_regex, 0, $s_rhs);      # issue 111, issue s131
      if($ValClass[0] eq 'c' && $ValPy[0] eq 'when') {           # issue s129
          return "re.compile($quoted_regex)";                    # issue s129
      }                                                          # issue s129
      return "re.compile($quoted_regex)" if $tno >= 1 && $ValClass[$tno-1] eq 'M';          # issue s251: ~~
   }
   if( length($modifier)>0 ){
      #this is regex
      # issue s151 if( $tno>=1 && $ValClass[$tno-1] eq '~' ){
      if( $tno>=1 && $ValClass[$tno-1] eq 'p' ){        # issue s151
         # explisit or implisit '~m' can't be at position 0; you need the left part
         if( $groups_are_present ){
            return "($DEFAULT_MATCH:=re.search(".$quoted_regex.','; #  we need to have the result of match to extract groups.   # issue 32, 75
         }else{
           return '(re.search('.$quoted_regex.','; #  we do not need the result of match as no groups is present. # issue 75
         }
      # issue 93 }elsif( $ValClass[$tno-1] eq '0'  ||  $ValClass[$tno-1] eq '(' ){
      # issue 124 }elsif( $tno>=1 && ($ValClass[$tno-1] =~ /[0o]/  ||  $ValClass[$tno-1] eq '(' || $ValClass[$tno-1] eq '=') ){      # issue 93, SNOOPYJC: Handle assignment of regex with default var and groups
      } elsif($s_rhs) {                         # issue s131
          return $quoted_regex;                 # issue s131
      } else {          # issue 124
            # this is calse like || /text/ or while(/#/)
         if( $groups_are_present ){
                return "($DEFAULT_MATCH:=re.search(".$quoted_regex.",$CONVERTER_MAP{S}($DEFAULT_VAR)))"; #  we need to have the result of match to extract groups. # issue 32, issue s8
         }else{
           return 're.search('.$quoted_regex.",$CONVERTER_MAP{S}($DEFAULT_VAR))"; #  we do not need the result of match as no groups is present.    # issue 32, 75, issue s8
         }
      # issue 124 }else{
         # issue 124 return 're.search('.$quoted_regex.",$DEFAULT_VAR)"; #  we do not need the result of match as no groups is present. # issue 32, 75
      }
   }else{
      # this is a string
      $ValClass[$tno]="'";
      # issue s230 return '.find('.escape_quotes(escape_non_printables($myregex,0)).')';
      if( $tno>=1 && $ValClass[$tno-1] eq 'p' ){        # issue s230
         return escape_quotes(escape_non_printables(remove_perl_escapes($myregex,0),0));  # issue s230: change \. to . etc
      } else {
         return escape_quotes(escape_non_printables(remove_perl_escapes($myregex,0),0)) . " in $CONVERTER_MAP{S}($DEFAULT_VAR)";  # issue s230: change \. to . etc
      }
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
       pop(@ValType);   # issue 37
   }
}

sub single_quoted_literal
# ATTENTION: returns position after closing bracket
# A backslash represents a backslash unless followed by the delimiter or another backslash,
# in which case the delimiter or backslash is interpolated.
{
# issue 39 ($closing_delim,$offset)=@_;
my ($closing_delim,$offset)=@_;     # issue 39
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
      $start_line = $.;         # issue 39
      while (1) {           # issue 39
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
           if( $sym eq $closing_delim ) {           # issue 39, issue 83
               if($nest <= 0) {                 # issue 83
                   return $m+1; # this is first symbol after closing quote      # issue 39
               }                                # issue 83
               $nest--;                         # issue 83
       }                                        # issue 39
        }
    # issue 39: if we get here, we ran out of road - grab the next line and keep going!
        my @tmpBuffer = @BufferValClass;    # SNOOPYJC: Must get a real line even if we're buffering stuff
        @BufferValClass = ();               # SNOOPYJC
        $line = Pythonizer::getline(2);     # issue 39, issue s73: 2 means we're in a string
        $StatementStartingLno{$.} = $statement_starting_lno;    # issue s275
        @BufferValClass = @tmpBuffer;           # SNOOPYJC
        # issue s149 if(!$line) {                # issue 39
        if(!defined $line) {                # issue 39, issue s149
            logme('S', "Unterminated string starting at line $start_line");     # issue 39
            return $m+1;            # issue 39
        }                   # issue 39
        $source .= "\n" . $line;        # issue 39
        $offset = $m;               # issue 39
      }                     # issue 39
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
   return interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, 0, 0);     # issue 39, issue s80
}

use constant {l_mode => 1, u_mode=>2, L_mode=>4, U_mode=>8, F_mode=>16, Q_mode=>32};    # issue s28
my $max_special_mode = 32;                                                              # issue s28
my %SPECIAL_ESCAPE_MODES = (l=>l_mode, u=>u_mode, L=>L_mode, U=>U_mode, F=>F_mode, Q=>Q_mode, E=>0); # issue s28
use constant {Bracketed=>1, InString=>2, NeedConcat=>4};    # issue s28
my %SPECIAL_ESCAPE_FUNCTIONS = (l=>'_lcfirst', u=>'_ucfirst', L=>'.lower()', U=>'.upper()', 
                                F=>'.casefold()', Q=>'_quotemeta', E=>'');               # issue s28
my %SPECIAL_ESCAPES = ("'"=>'chr(39)', "\\"=>'chr(92)', '"'=>'chr(34)', "\n"=>'chr(10)');         # issue s28: backslashes are not allowed in f strings

sub interpolate_strings                                         # issue 39
# Interpolate variable references in strings
{
# Args:
   my $quote = shift;                   # The value WITHOUT the quotes
   my $pre_escaped_quote = shift;       # Same but with any \" inside not escaped
   my $close_pos = shift;               # First position AFTER the closing quotes
   my $offset = shift;                  # How long the opening is, e.g. 1 for ", 3 for qq/
   my $in_regex = shift;                # 1 if we're in a regex and \$ needs to remain as \$
   my $x_flag = shift;                  # if in regex, do we have the x flag set?       # issue s80
# Result = normally $close_pos, but can point earlier in the string if we need to tokenize part of it
# in order to check for references (in the first pass only).
#
# Also $ValPy[$tno] is set to the code to be generated for this string

   my @special_escape_stack = ();                               # issue s28: Push the *_flags
   my $special_escape_mode = 0;                                 # issue s28: | of the current mode
   my $special_escape_flags = 0;                                # issue s28: | of the current flags

   if($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
       say STDERR ">interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex, $x_flag)";
   }
   my ($l, $k, $ind, $result, $pc, $prev);
   local $cut;                  # Save the global version of this!
   $prev = '';
   # issue s28 $quote = perl_hex_escapes_to_python(escape_non_printables($quote,0));                     # SNOOPYJC: Replace \x{ddd...} with python equiv
   $quote = escape_non_printables($quote,0, 0);         # issue s28: We do the perl_hex_escapes_to_python inside remove_perl_escapes now
   #
   # decompose all scalar variables, if any, Array and hashes are left "as is"
   #
   $k=index($quote,'$');
   if( $Pythonizer::PassNo == &Pythonizer::PASS_0 || (($k==-1 || $k == length($quote)-1) && index($quote, '@') == -1)){             # issue 47, SNOOPYJC: Skip if first '$' is the last char, like in a regex
      # case when double quotes are used for a simple literal that does not reaure interpolation
      # Python equvalence between single and doble quotes alows some flexibility
      $ValPy[$tno]=escape_quotes(remove_perl_escapes($quote,$in_regex),2); # always generate with quotes --same for Python 2 and 3
      if($Pythonizer::PassNo != &Pythonizer::PASS_0) {
         say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex, $x_flag)=$close_pos, ValPy[$tno]=$ValPy[$tno]" if($::debug >=3);
      }
      return $close_pos;
   }
   if($Pythonizer::PassNo==&Pythonizer::PASS_1 && $last_varclass_lno != $. && $last_varclass_lno) {     # issue s114: Move this code up!
    # We don't capture regex's or here_is documents so just grab the last line_varclasses and propagate it down here
        # If we don't do this and there ARE variable references in the string, we won't properly map them if
        # they need the package name added.
        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
        $last_varclass_lno = $.;
   }
   # SNOOPYJC: In the first pass, extract all variable references and return them as separate tokens
   # so we can mark their references, and add things like initialization.
   # If we're handling a here_is document, or a regex, we don't do this (but we probably should: $close_pos == 0)
   if($Pythonizer::PassNo == &Pythonizer::PASS_1 && $close_pos != 0) {                       # SNOOPYJC
       my $pos = extract_tokens_from_double_quoted_string($pre_escaped_quote,1,$x_flag)+$offset;    # issue s80
       if($ExtractingTokensFromDoubleQuotedStringEnd > 0) {
          $ExtractingTokensFromDoubleQuotedStringEnd += $offset;
          say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex, $x_flag)=$pos (begin extract mode)" if($::debug >=3);
          return $pos;
       }
# issue s114    } elsif($Pythonizer::PassNo==&Pythonizer::PASS_1 && $last_varclass_lno != $. && $last_varclass_lno) {
# issue s114    # We don't capture regex's or here_is documents so just grab the last line_varclasses and propagate it down here
# issue s114        # If we don't do this and there ARE variable references in the string, we won't properly map them if
# issue s114        # they need the package name added.
# issue s114        $line_varclasses{$.} = dclone($line_varclasses{$last_varclass_lno});
# issue s114        $last_varclass_lno = $.;
   }

   #    # issue bootstrap
   #decode each part. Double quote literals in Perl are ver difficult to decode
   # This is a parcial implementation of the most common cases
   # Full implementation is possible only in two pass scheme
my  $outer_delim;
    $quote = preprocess_regex_x_flag_refs_in_comments($quote) if($x_flag);       # issue s80
    $quote = escape_curly_braces($quote);        # issue 51
    # issue 47 $k=index($quote,'$');                        # issue 51 - recompute in case it moved
    $k = -1;                            # issue 47
    if($quote =~ m'[$@\\]') {           # issue 47, issue s28
        $k = $-[0];                     # issue 47: Match pos
    }

    if (index($quote,'"')==-1 && index($quote, "\n")==-1){      # issue multi-line here
       $outer_delim='"'
    # issue 53: we use single quotes in our 'bareword' so we can't use them here if we have {...}
    }elsif(index($quote,"'")==-1 && index($quote,'{')==-1 && index($quote,"\n")==-1     # issue 53, multi-line here
        && index($quote, "\\")==-1){                            # issue s23: Don't enclose in single quotes if we have possible \Q \U, etc
      $outer_delim="'";
    }else{
      $outer_delim='"""';
    }
   $result='f'.$outer_delim; #For python 3 we need special opening quote
   $prev = '';
   my ($sig, $dot);                     # issue 47
   my ($next_c, $next_3, $func_1, $prior_semode, $new_semode, $func);
   while( $k > -1  ){
      $sig = substr($quote,$k,1);       # issue 47
      if($sig eq "\\") {                # issue s28
          # we have the first literal string  before the escape
          if($special_escape_mode == 0 && ($special_escape_flags == 0 || !($special_escape_flags & Bracketed))) {
              $result.=remove_perl_escapes(substr($quote,0,$k),$in_regex,1); # issue bootstrap, issue s28
          } else {              # We are bracketed, so put these chars in one by one
              for(my $i = 0; $i < $k; $i++) {
                  my $ch = substr($quote,$i,1);
                  if(exists $SPECIAL_ESCAPES{$ch}) {      # a char like ' that we have to escape
                      if($special_escape_flags & InString) {     # first clean up what we have here
                          $result.="'";
                          $special_escape_flags &= ~InString;
                          $special_escape_flags |= NeedConcat;
                      }
                      if($special_escape_flags & NeedConcat) {
                          $result.="+";
                          $special_escape_flags &= ~NeedConcat;
                      }
                      $result.=$SPECIAL_ESCAPES{$ch};
                      $special_escape_flags |= NeedConcat;
                  } else {                      # we have some other character to add in to the mix
                      if(!($special_escape_flags & InString)) {
                          if($special_escape_flags & NeedConcat) {
                              $result.="+";
                              $special_escape_flags &= ~NeedConcat;
                          }
                          $result.="'";
                          $special_escape_flags |= InString;
                      }
                      $result.=$ch;
                  }
              }
          }
          $quote=substr($quote,$k);
          $k=0;
          while($k > -1) {              # issue s28
              $sig = substr($quote,$k,1);
              if($sig ne "\\") {
                  if(($sig eq '$' || $sig eq '@') && $k+1 < length($quote)) {      # We need to go and interpolate something good
                      if($special_escape_flags & InString) {     # first clean up what we have here
                          $result.="'";
                          $special_escape_flags &= ~InString;
                          $special_escape_flags |= NeedConcat;
                      }
                      if($special_escape_flags & NeedConcat) {
                          $result.="+";
                          $special_escape_flags &= ~NeedConcat;
                      }
                      last;
                  } elsif(exists $SPECIAL_ESCAPES{$sig}) {      # a char like ' that we have to escape
                      if($special_escape_flags & InString) {     # first clean up what we have here
                          $result.="'";
                          $special_escape_flags &= ~InString;
                          $special_escape_flags |= NeedConcat;
                      }
                      if($special_escape_flags & NeedConcat) {
                          $result.="+";
                          $special_escape_flags &= ~NeedConcat;
                      }
                      $result.=$SPECIAL_ESCAPES{$sig};
                      $special_escape_flags |= NeedConcat;
                  } else {                      # we have some other character to add in to the mix
                      if(!($special_escape_flags & InString)) {
                          if($special_escape_flags & NeedConcat) {
                              $result.="+";
                              $special_escape_flags &= ~NeedConcat;
                          }
                          $result.="'";
                          $special_escape_flags |= InString;
                      }
                      $result.=$sig;
                      $sig = '';
                  }
                  $quote = substr($quote,1);    # Eat a char
                  $k = -1 if(length($quote) == 0);      # Done
                  next;
              }

              # At this point we have a \ character

              if(exists $SPECIAL_ESCAPE_MODES{$next_c = substr($quote,$k+1,1)}) {
                  $quote = substr($quote,1);    # Eat the \ char
              } else {
                  last if($special_escape_mode == 0 && $special_escape_flags == 0);   # We're done or don't belong here
                  if($special_escape_flags & Bracketed) {        # Escapes are not allowed in brackets, so we have to do something else
                      if($special_escape_flags & InString) {
                          $result.="'";
                          $special_escape_flags &= ~InString;
                          $special_escape_flags |= NeedConcat;
                      }
                      if($special_escape_flags & NeedConcat) {
                          $result.="+";
                          $special_escape_flags &= ~NeedConcat;
                      }
                      ($func, $quote) = replace_escape_with_chr($quote, $in_regex);
                      $result.=$func;
                      $special_escape_flags |= NeedConcat;
                  } else {
                      $result.=remove_perl_escapes(substr($quote,0,$k+1),$in_regex,1);
                      $quote = substr($quote,$k+1);
                      $k = -1 if(length($quote) == 0);      # Done
                      $sig = '';
                      next;
                  }
                  $k = -1 if(length($quote) == 0);      # Done
                  $sig = '';
                  next;
              }

              # At this point we have an special escape sequence

              if(($next_3 = substr($quote,$k,3)) eq "L\\u" || $next_3 eq "U\\l") {    # Swap these special cases
                  substr($quote,$k,1) = substr($next_3,2,1);
                  substr($quote,$k+2,1) = substr($next_3,0,1);
                  $next_c = substr($quote,$k,1);
              }
              $prior_semode = $special_escape_mode;
              $new_semode = $SPECIAL_ESCAPE_MODES{$next_c};
              $special_escape_mode |= $new_semode;
              if(!($special_escape_flags & Bracketed)) {
                  $result.='{';
                  $special_escape_flags |= Bracketed;
              }
              if($special_escape_flags & InString) {
                  $result.="'";
                  $special_escape_flags &= ~InString;
                  $special_escape_flags |= NeedConcat;
              }
              $func = $SPECIAL_ESCAPE_FUNCTIONS{$next_c};
              if($func eq '') {         # \E has no function because it's the end
                  do {          # only \L \U \F and \Q have corresponding \E, if anything else, keep popping
                      my $stacked = pop @special_escape_stack;
                      ($special_escape_mode, $new_semode, $func) = split /,/, $stacked;
                      $result.=$func;
                  } until($new_semode & (L_mode|U_mode|F_mode|Q_mode));
                  if(scalar(@special_escape_stack)) {
                      my $stacked = $special_escape_stack[-1];
                      my ($sem, $new_s, $f) = split /,/, $stacked;
                      if($new_s & (l_mode|u_mode)) {    # if we have a \l or \u just before the \L \U \F or \Q, then we can process that too
                          pop @special_escape_stack;
                          $special_escape_mode = $sem;
                          $result.=$f;
                      }
                  }
                  if(!scalar(@special_escape_stack) & ($special_escape_flags & Bracketed)) {
                      # if the stack is empty and we are bracketed, then we can end them
                      if($special_escape_flags & InString) {
                          $result.="'";
                          $special_escape_flags &= ~InString;
                      }
                      $result.='}';
                      $special_escape_flags &= ~NeedConcat;
                      $special_escape_flags &= ~Bracketed;
                      $quote = substr($quote,1);    # Eat a char
                      $k = -1;
                      last;
                  }
              } else {
                  if($special_escape_flags & NeedConcat) {
                      $result.="+";
                      $special_escape_flags &= ~NeedConcat;
                  }
                  if(($func_1 = substr($func,0,1)) eq '_') {
                      if($::import_perllib) {
                          $func = $PERLLIB . '.' . substr($func,1);
                      } else {
                          $::Pyf{$func} = 1;
                      }
                  }

                  if($func_1 eq '.') {              # This is a tail function
                      $result.='(';
                      push @special_escape_stack, ($prior_semode . ','. $new_semode . ",)$func");
                  } else {
                      $result.="$func(";
                      push @special_escape_stack, ($prior_semode . ','. $new_semode . ",)");
                  }
              }
              $quote = substr($quote,1);    # Eat a char
              $k = -1 if(length($quote) == 0);      # Done
          } # while  issue s28
      } # if  issue s28
      if($sig eq "\\") {                        # issue s28
          my $pos = 0;
          if($k >= 0 && substr($quote,$k,1) eq $sig) {                        # issue s28
              $pos = end_of_escape(substr($quote,$k), 1)+$k+1;   # issue s28: Skip the escape sequence which could be like \c@ \123 or \N{name...}
          } else {                              # if we processed an escape sequence, then just start at the beginning of $quote
              $k = 0 if $k < 0;
          }
          if(substr($quote,$pos) =~ m'[$@\\]') {
              my $kk = $-[0] + $pos;                       # match pos
              $result.=remove_perl_escapes(substr($quote,$k,$kk-$k),$in_regex,1);   # Put the chars in the output
              $quote = substr($quote,$kk);       # We just put these chars in the output
              $k=0;
          } else {
              $result.=remove_perl_escapes(substr($quote,$k),$in_regex,1);   # Put the chars in the output
              $quote='';
              $k=-1;
          }
          next;
      }
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
            $result.=remove_perl_escapes(substr($quote,0,$k),$in_regex,1); # issue bootstrap
         }
      }
      $quote=substr($quote,$k);
      if($quote eq $sig || (substr($quote,0,1) eq $sig && substr($quote,1) =~ /^\s+$/)) {   # issue 111: Handle "...$"
          if($special_escape_flags & Bracketed) {       # issue s28
              if(!($special_escape_flags & InString)) {
                  if($special_escape_flags & NeedConcat) {
                      $result.="+";
                      $special_escape_flags &= ~NeedConcat;
                  }
                  $result.="'";
                  $special_escape_flags |= InString;
              }
          }
          $result.=$quote;
          $quote = '';
          last;
      }
      if(!($special_escape_flags & Bracketed)) {         # issue s28
          $result.='{';  # we always need '{' for f-strings
          $special_escape_flags |= Bracketed;
      }
      #say STDERR "quote1=$quote\n";
      my $end_br = -1;              # issue 43
      if(length($quote) != 0 && substr($quote,1,1) eq '{') {        # issue 43: ${...}
         $end_br = matching_curly_br($quote, 1); # issue 43
         if(substr($quote,2,2) eq "\\(" && $end_br != -1) {
             $result .= handle_expr_in_string($quote, 3);        # ${\(expr_in_scalar_context)}
             $cut = $end_br;
             $end_br++;
             $sig = '';
         } else {
            $quote = $sig . substr($quote,2);   # issue 43: eat the '{'. At this point, $end_br points after the '}', issue 47
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
            $special_escape_flags &= ~Bracketed;   # issue s28
            substr($quote,$end_br-1,1) = '' if($end_br >= 0);
            $quote=substr($quote,$cut);
            $k = -1;                            # issue 47
            if($quote =~ m'[$@\\]') {             # issue 47, issue s28
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
            $special_escape_flags &= ~Bracketed;   # issue s28
            substr($quote,$end_br-1,1) = '' if($end_br >= 0);
            $quote=substr($quote,$cut);
            $k = -1;                            # issue 47
            if($quote =~ m'[$@\\]') {             # issue 47, issue s28
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
         $next_c = substr($quote,$cut,1);       # SNOOPYJC
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
            my $cs = cur_sub();          # issue s3
            my $et = 'm';
            $et = $Pythonizer::VarType{$ValPy[$tno]}{$cs} if(exists $Pythonizer::VarType{$ValPy[$tno]} && exists $Pythonizer::VarType{$ValPy[$tno]}{$cs});
            if($next_c eq '{' || $next_c eq '[' || $et =~ /[SFIR]/) {       # issue s117
                $result.=$ValPy[$tno]; # copy string provided by decode_scalar. ValPy[$tno] changes if Perl contained :: like in $::debug
            } else {                                  # issue s117
                $result.='_bn(' . $ValPy[$tno] . ')'; # issue s117: convert None to '', else grab the value as is
            }
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
        } elsif($end_br > 0 && substr($quote,0,4) eq '@ [%' && substr($quote,4,1) =~ /[\w:]/) {  # issue test coverage: @{ [%hash] }
            $quote = substr($quote, 3);
            decode_hash($quote);
            add_package_name(substr($quote,0,$cut));            # SNOOPYJC
            # SNOOPYJC $ValPy[$tno] = 'functools.reduce(lambda x,y:x+y,'.$ValPy[$tno].'.items())';
            $ValPy[$tno] = "map(_str,itertools.chain.from_iterable($ValPy[$tno].items()))";     # SNOOPYJC
            $end_br -= 3;    # 3 to account for the 2 we ate
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
                $special_escape_flags &= ~Bracketed;   # issue s28
                substr($quote,$end_br-1,1) = '' if($end_br >= 0);
                $quote=substr($quote,$cut);
                $k = -1;                            # issue 47
                if($quote =~ m'[$@\\]') {             # issue 47, issue s28
                    $k = $-[0];                     # issue 47: Match pos
                }
                if($k == 0) {             # SNOOPYJC: If we have @$, then just eat the '@', but remember for the next round
                    $prev = '@';
                } else {
                    $result .= '@'
                }
                next;
            } elsif(substr($quote,$cut,1) eq '[') {         # issue s120: Handle @array[ndx] like they wrote $array[ndx]
                $sig = '$';
            }
            add_package_name(substr($quote,0,$cut));            # SNOOPYJC
         }
         #does not matter what type of variable this is: regular or special variable
         if($sig eq '$') {                                  # issue s120
             $result.=$ValPy[$tno];                         # issue s120
         } else {                                           # issue s120
             my $ls = 'LIST_SEPARATOR';
             $ls = $PERLLIB . '.' . $ls if($::import_perllib);
             $result.="$ls.join(map(_str,$ValPy[$tno]))"; # copy string provided by decode_array. ValPy[$tno] changes if Perl contained :: like in $::debug
         }                                                  # issue s120
      }

      $quote=substr($quote,$cut); # cure the nesserary number of symbol determined by decode_scalar.
      $end_br -= $cut;          # issue 43
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
             #say STDERR "examining $ind on line $.";      # TEMP
             #say STDERR "what follows is " . substr($quote, $ind_cut);  # TEMP
             my $in_subscript = 0;                  # issue s123
             for(my $i = 0; $i < length($ind); $i++) {  # issue 53: change hash ref {...} to use .get(...) instead
                 my $c = substr($ind,$i,1);                 # issue 109
                 if($c eq '-' && substr($ind,$i+1,1) eq '>') {  # issue refs in strings
                     substr($ind,$i,2) = '';    # eat '->'
                     $c = substr($ind,$i,1);
                 }
                 if($c eq '{') {        # issue 53
                     $in_subscript = 0;                         # issue s123
                     $l = matching_curly_br($ind, $i);  # issue 53
                     #say "found '{' in $ind at $i, l=$l";
                     next if($l < 0);           # issue 53
                     # Issue s107: only use .get for the last hash key in a chained sequence of key fetches
                     my $next_ch = substr($quote, $ind_cut, 1);     # issue s107
                     if($next_ch eq '{') {                          # issue s107
                         if(substr($ind,$i+1,1) =~ /\d/) {          # issue s123: Hash with integer key
                            $ind = substr($ind,0,$i)."['".substr($ind,$i+1,$l-($i+1))."']".substr($ind,$l+1);   # issue s123
                         } else {                                   # issue s123
                            $ind = substr($ind,0,$i).'['.substr($ind,$i+1,$l-($i+1))."]".substr($ind,$l+1); # issue s107 splice in [...] instead
                         }                                          # issue s123
                     } else {
                         if(substr($ind,$i+1,1) =~ /\d/) {          # issue s123: Hash with integer key
                            $ind = substr($ind,0,$i).".get('".substr($ind,$i+1,$l-($i+1))."','')".substr($ind,$l+1);    # issue s123
                         } else {                                   # issue s123
                            $ind = substr($ind,0,$i).'.get('.substr($ind,$i+1,$l-($i+1)).",'')".substr($ind,$l+1);  # issue 53: splice in the call to get
                         }                                          # issue s123
                     }                                              # issue s107
                 } elsif($c eq '[') {                               # issue s123
                     $in_subscript = 1;                             # issue s123
                     $l = matching_square_br($ind, $i);             # issue s123
                     #say "found '[' in $ind at $i, l=$l";
                     next if($l < 0);                               # issue s123
                     if(substr($ind,$i+1,1) eq "'") {               # issue s123: Array with string key
                        $ind = substr($ind,0,$i).'['.substr($ind,$i+2,$l-($i+3))."]".substr($ind,$l+1); # issue s123: Strip off the quotes
                     }                                          # issue s123
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
                     my $index_type = 'm';                  # issue s123
                     my $cs = cur_sub();                    # issue s123
                     $index_type = $Pythonizer::VarType{$ValPy[$tno]}{$cs} if(exists $Pythonizer::VarType{$ValPy[$tno]} && exists $Pythonizer::VarType{$ValPy[$tno]}{$cs});
                     my $expected_type = 'S';               # issue s123
                     $expected_type = 'I' if($in_subscript);    # issue s123
                     $converter = $CONVERTER_MAP{$expected_type};        # issue s123
                     $::Pyf{$converter} = 1 if($expected_type ne 'S');  # issue s123
                     $converter = "$PERLLIB.int_" if($expected_type eq 'I' && $::import_perllib);    # issue s123
                     my $next_ch = substr($var, $cut, 1);     # issue s123
                     my $j = $i + $cut;                       # issue s123
                     if($next_ch eq '-') {                    # issue s123: Assume it's a '->'
                         $j += 2;                             # issue s123
                         $next_ch = substr($var, $cut+2, 1);    # issue s123
                     }
                     if($next_ch eq '[' || $next_ch eq '{') {   # issue s123
                        while($next_ch eq '[' || $next_ch eq '{') {     # issue s123
                            if($next_ch eq '[') {
                                $l = matching_square_br($ind, $i);              # issue s123
                            } else {
                                $l = matching_curly_br($ind, $i);               # issue s123
                            }
                            last if($l < 0);
                            $j = $l+1;
                            $next_ch = substr($ind, $j);
                        }
                        substr($ind,$j,0) = ')';                # issue s123
                        substr($ind,$i,$cut) = "$converter($ValPy[$tno]";   # issue s123
                        $i += length($converter) + 1;       # issue s123
                     } elsif($index_type eq $expected_type) {  # issue s123
                        substr($ind,$i,$cut) = $ValPy[$tno];   # issue 109
                     } else {                               # issue s123
                        substr($ind,$i,$cut) = "$converter($ValPy[$tno])";   # issue s123
                        $i += length($converter) + 2;       # issue s123
                     }                                      # issue s123
                     $i += (length($ValPy[$tno])-$cut);     # issue 109
                 }
             }                      # issue 53
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
             $end_br -= $ind_cut;           # issue 43
             #say STDERR "quote4=$quote, end_br=$end_br";        # TEMP
          }
          if($prev eq '@') {
              $result.='))';     # Close the join/map operator inserted above
          }
          $prev = '';
      }
      #say STDERR "quote5=$quote, end_br=$end_br";
      $quote = substr($quote, $end_br) if($end_br > 0); # issue 43
      if($special_escape_flags == Bracketed && $special_escape_mode == 0) { # issue s28: we have Bracketed but no other flags so it's ok to end the bracket here
          $result.='}'; # end of variable
          $special_escape_flags &= ~Bracketed;   # issue s28
      } else {
          $special_escape_flags |= NeedConcat;  # issue s28
      }
      # issue 47 $k=index($quote,'$'); #next scalar
      $k = -1;                            # issue 47
      if($quote =~ m'[$@\\]') {           # issue 47, issue s28
          $k = $-[0];                     # issue 47: Match pos
      }
   } # while

   if( length($quote)>0  ){
      #the last part
      if($special_escape_mode == 0 && ($special_escape_flags == 0 || !($special_escape_flags & Bracketed))) {
          $result.=remove_perl_escapes($quote,$in_regex,1); # issue bootstrap
      } else {              # We are bracketed, so put these chars in one by one
          for(my $i = 0; $i < length($quote); $i++) {
              my $ch = substr($quote,$i,1);
              if(exists $SPECIAL_ESCAPES{$ch}) {      # a char like ' that we have to escape
                  if($special_escape_flags & InString) {     # first clean up what we have here
                      $result.="'";
                      $special_escape_flags &= ~InString;
                      $special_escape_flags |= NeedConcat;
                  }
                  if($special_escape_flags & NeedConcat) {
                      $result.="+";
                      $special_escape_flags &= ~NeedConcat;
                  }
                  $result.=$SPECIAL_ESCAPES{$ch};
                  $special_escape_flags |= NeedConcat;
              } else {                      # we have some other character to add in to the mix
                  if(!($special_escape_flags & InString)) {
                      if($special_escape_flags & NeedConcat) {
                          $result.="+";
                          $special_escape_flags &= ~NeedConcat;
                      }
                      $result.="'";
                      $special_escape_flags |= InString;
                  }
                  $result.=$ch;
              }
          }
      }
   }
   if($special_escape_flags & InString) {        # issue s28
       $result.="'";
       $special_escape_flags &= ~InString;
   }
   while(scalar(@special_escape_stack)) {       # issue s28
       my $stacked = pop @special_escape_stack;
       ($special_escape_mode, $new_semode, $func) = split /,/, $stacked;
       $result.=$func;
   }
   if($special_escape_flags & Bracketed) {       # issue s28
       $result.='}'; # end of variable
   }

   if($outer_delim eq '"""') {
      if(substr($result,-1,1) eq '"' && !is_escaped($result, length($result)-1)) {  # SNOOPYJC: quote at end - we have to fix this!
          $result = substr($result,0,length($result)-1)."\\".'"';
      }
      $result = 'f"""' . escape_triple_doublequotes(substr($result,4));
   }
   $result.=$outer_delim;
   #say STDERR "double_quoted_literal: result=$result";
   $result = postprocess_regex_x_flag_refs_in_comments($result) if($x_flag);       # issue s80
   $ValPy[$tno]=$result;
   say STDERR "<interpolate_strings($quote, $pre_escaped_quote, $close_pos, $offset, $in_regex, $x_flag)=$close_pos, ValPy[$tno]=$ValPy[$tno]" if($::debug >=3);
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
        $convert_to_arr = 0;                # issue s249
        if(!$was_hash && substr($string, 0, 1) eq '@') {        # issue s249
            $::force_list_context = 1;      # issue s249
            if(&Pythonizer::expr_type($t_start, $#ValClass, cur_sub()) !~ /^[ah]/) { # issue s249: Handle @{[scalar @$left]}
                $convert_to_arr = 1;            # issue s249
                gen_chunk('[');                 # issue s249
            }
        }
        $::TrStatus = &::expression($t_start, $#ValClass, 0);
        if($convert_to_arr) {  # issue s249
            gen_chunk(']'); 
        }
        $::force_list_context = 0;      # issue s249
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
    my $x_flag = shift;         # issue s80: is this a regex with the x flag? (only checked if $initial)

    say STDERR ">extract_tokens_from_double_quoted_string($quote,$initial,$x_flag)" if($::debug>=3);
    $ExtractingTokensFromDoubleQuotedStringTnoStart = $tno if($initial);
    $ExtractingTokensFromDoubleQuotedStringXFlag = $x_flag if($initial);        # issue s80
    if($ExtractingTokensFromDoubleQuotedStringXFlag) {      # issue s80
        $quote = preprocess_regex_x_flag_refs_in_comments($quote);       # issue s80
    }
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
            # issue test coverage $adjust = 1;
            if(substr($quote,$pos+2,2) eq '\\(') {      # ${\(...)}
                $sigil = '';
                # issue test coverage $cut = 3;
                $cut = $end_br+1;               # issue test coverage
                # issue test coverage substr($quote,$end_br,1) = '';  # Eat the }
                $end_br = -1;
                $ExtractingTokensFromDoubleQuotedStringAdjustBrackets = 1;      # issue test coverage
            } elsif(substr($quote,$pos+2,1) eq '[') {   # @{[...]}
                $sigil = '';
                # issue test coverage $cut = 2;
                $cut = $end_br+1;               # issue test coverage
                # issue test coverage substr($quote,$end_br,1) = '';
                $end_br = -1;
                $ExtractingTokensFromDoubleQuotedStringAdjustBrackets = 1;      # issue test coverage
            } elsif(substr($quote,$pos+2,2) eq ' [') {  # @{ [...] }
                $sigil = '';
                # issue test coverage $cut = 3;
                $cut = $end_br+1;               # issue test coverage
                # issue test coverage substr($quote,$end_br,1) = '';
                $end_br = -1;
                $ExtractingTokensFromDoubleQuotedStringAdjustBrackets = 1;      # issue test coverage
            } elsif(substr($quote,$pos+2,1) eq '$') {   # @{$...}
                $sigil = '';
                # issue test coverage $cut = 2;
                $cut = $end_br+1;               # issue test coverage
                # issue test coverage $end_br--;
                $end_br = -1;
                # issue test coverage substr($quote,$end_br,1) = '';
                $ExtractingTokensFromDoubleQuotedStringAdjustBrackets = 1;      # issue test coverage
            } else {
                # issue s114 $adjust = 0;
                $adjust = 1;            # issue s114: Account for the '{' we ate
                $quote = '$'.substr($quote,2);      # issue 43: eat the '{'. At this point, $end_br points after the '}'
            }
        }
        if($sigil eq '$') {
            my $s2=substr($quote,1,1);                   # issue ws after sigil
            my $len_ws = 0;                             # issue test coverage
            my $orig_quote = $quote;                    # issue test coverage
            if($s2 eq '' || $s2 =~ /\s/) {               # issue ws after sigil
               my $q2 = get_rest_of_variable_name($quote, 1);
               if($q2 ne $quote) {
                   $len_ws = length($quote) - length($q2);      # issue test coverage
                   $ExtractingTokensFromDoubleQuotedStringEnd+=$len_ws;   # issue test coverage
                   say STDERR "putting ExtractingTokensFromDoubleQuotedStringEnd back to $ExtractingTokensFromDoubleQuotedStringEnd" if($::debug >= 5);
                   if($end_br > 0) {
                       $end_br -= $len_ws;                          # issue test coverage
                   }
               }
               $quote = $q2;
            }
            decode_scalar($quote, 1,1);
            if($len_ws != 0) {                          # issue test coverage
                $quote = $orig_quote;                   # issue test coverage
                $cut += $len_ws;                        # issue test coverage
            }                                           # issue test coverage
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
            $ExtractingTokensFromDoubleQuotedTokensEnd = $cut if $ExtractingTokensFromDoubleQuotedStringAdjustBrackets == 0;    # issue s114
            $cut = $end_br;
        } else {
            $ExtractingTokensFromDoubleQuotedTokensEnd = $cut;
        }
        $ExtractingTokensFromDoubleQuotedStringEnd = length($quote) + $adjust;
        if($end_br != -1) {         # issue s114
            $pos = $ExtractingTokensFromDoubleQuotedTokensEnd+2;    # issue s114: point past the '}'
            $ExtractingTokensFromDoubleQuotedTokensEnd = -1;        # issue s114
            if( $::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0 ){
                say STDERR "Lexem $tno Current token='$ValClass[$tno]' perl='$ValPerl[$tno]' value='$ValPy[$tno]'", " Tokenstr |",join('',@ValClass),"| translated: ",join(' ',@ValPy);
            }
            $tno++;
        }                                                           # issue s114
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
    my $c2;
    for(my $k = 0; $k < length($str); $k++) {
        my $c = substr($str,$k,1);
        if($c eq '\\' && (($c2 = substr($str,$k+1,1)) eq '$' || $c2 eq '\\')) {    # issue s227: skip \$ and \\ but not \{
            $k++;               # issue s227
            next;               # issue s227
        }
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

    my $result = $str;                  # issue s131: Don't change the original
    for(my $k = index($result, "\\"); $k >= 0; $k = index($result, "\\", $k+1)) {
        if($k+1 < length($result) && substr($result, $k+1, 1) eq $delim) {
            substr($result, $k, 1) = '';           # change \' to '
        }
    }
    return $result;
}

sub decode_array                # issue 47
{
    my $source = shift;
    my $cut_adjust = 0;
    ($source, $cut_adjust) = handle_use_english($source, \%ENGLISH_ARRAY) if $::uses_english;    # use English
     if( substr($source,1)=~/^(\:?\:?\'?\w+((?:(?:\:\:)|\')\w+)*)/ ){
        $arg1=$1;
        if($arg1 =~ /^\d/ && $Pythonizer::PassNo == &Pythonizer::PASS_2) {            # like @2017
            logme('W', "Numeric array variable \@$arg1 detected - please check this is what you want here!");
        }
        if( $arg1 eq '_' ){
           $ValPy[$tno]="$PERL_ARG_ARRAY";  # issue 32
           #$ValType[$tno]="X";
        }elsif( $arg1 eq 'INC' || $arg1 eq '::INC' || $arg1 eq 'main::INC'  ){      # SNOOPYJC, issue s188
              $ValPy[$tno]='sys.path';
              my $cs = cur_sub();
              $SpecialVarsUsed{'@INC'}{$cs} = 1;                       # SNOOPYJC
              #$ValType[$tno]="X";
        }elsif( $arg1 eq 'ARGV' || $arg1 eq '::ARGV' || $arg1 eq 'main::ARGV' ){    # issue s188
                # issue 49 $ValPy[$tno]='sys.argv';
              $ValPy[$tno]='sys.argv[1:]';  # issue 49
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
           $ValPy[$tno] = escape_keywords($ValPy[$tno]);        # issue 41
        }
        $cut=length($arg1)+1+$cut_adjust;       # use English
        #$ValPerl[$tno]=substr($source,$cut);
        #$ValClass[$tno]='a'; #array
     }else{
        $cut=1;
     }
}

sub decode_hash                 # issue 47
{
    my $source = shift;
    my $cut_adjust = 0;
    ($source, $cut_adjust) = handle_use_english($source, \%ENGLISH_HASH) if $::uses_english;    # use English

     if( substr($source,1)=~/^(\:?\:?\'?[_a-zA-Z]\w*((?:(?:\:\:)|\')[_a-zA-Z]\w*)*)/ ){
        $cut=length($1)+1;
        #$ValClass[$tno]='h'; #hash
        #$ValPerl[$tno]=$1;
        $ValPy[$tno]=$1;
        $ValPy[$tno] = 'ENV' if($ValPy[$tno] eq 'main::ENV' || $1 eq '::ENV');  # issue s188
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

sub perl_hex_escapes_to_python
# For strings that contain perl hex escapes (\x{HHH...}), change them to python hex escapes (of 3 varieties)
# Also handles \c escapes and \o escapes.  The string passed can have multiple escapes and other string sequences in it.
# issue s28: in f"..." strings, the {...} brackets are doubled to {{...}} so we have to handle that here
{
    my $str = shift;
    my $has_double_brackets = (scalar(@_) == 0 ? 0 : $_[0]);   # issue s28

    print STDERR "perl_hex_escapes_to_python($str, $has_double_brackets) = " if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);


    if($has_double_brackets) {
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\c(.)/sprintf "\\x{{%x}}", (ord(uc $1) ^ 64)/eg;

        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\o\{\{\s*([0-7]+)\s*\}\}/sprintf "\\x{{%x}}", oct($1)/eg;

        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{\s*([A-Fa-f0-9])\s*\}\}/\\x0$1/g;
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{\s*([A-Fa-f0-9]{2})\s*\}\}/\\x$1/g;
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{([A-Fa-f0-9]{3})\}\}/\\u0$1/g;
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{([A-Fa-f0-9]{4})\}\}/\\u$1/g;
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{([A-Fa-f0-9]{5})\}\}/\\U000$1/g;
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{([A-Fa-f0-9]{6})\}\}/\\U00$1/g;
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{([A-Fa-f0-9]{7})\}\}/\\U0$1/g;
        $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x\{\{([A-Fa-f0-9]{8})\}\}/\\U$1/g;
    } else {
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
    }
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x([A-Fa-f0-9])$/\\x0$1/g;                      # issue s125
    $str =~ s/(?:(?<=[\\][\\])|(?<![\\]))\\x([A-Fa-f0-9])([^A-Fa-f0-9])/\\x0$1$2/g;       # issue s125

    say STDERR "$str" if($::debug >= 5 && $Pythonizer::PassNo != &Pythonizer::PASS_0);

    return $str;
}

sub escape_non_printables               # SNOOPYJC: Escape non-printable chars
{
    my $string = shift;
    my $escape_all = shift;             # if 1, then escape them all
    my $escape_to_python = (@_ >= 1 ? $_[0] : 1);

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
       if($escape_to_python) {
           $string = perl_hex_escapes_to_python($new)
       } else {
           $string = $new;
       }
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

   if(index($string,"\n") >= 0) {   # issue 39 - need to escape newlines
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
# issue s28 $allowed_escapes = "\n\\'\"abfnrtv01234567xNuU";
$allowed_escapes = "\n\\'\"abfnrtv01234567xNoc";         # issue s28: \u and \U in perl are not the same as \U in python!  We allow o and c because we remove them at the end in perl_hex_escapes_to_python
# ref https://docs.python.org/3/library/re.html
# issue s28 $allowed_escapes_in_regex = q/.^$*+?{}[]|()\\'"&ABdDsSwWZgabfnrtv0123456789xNuU/;
# issue s81 $allowed_escapes_in_regex = q/.^$*+?{}[]|()\\'"&ABdDsSwWZgabfnrtv0123456789xNoc/;        # issue s28: remove \u and \U
# issue s267 $allowed_escapes_in_regex = q/.^$*+?{}[]|()\\'"&ABdDGsSwWZgabfknrtvz0123456789xNocpP/;        # issue s28: remove \u and \U, issue s81 allow \k and \z
$allowed_escapes_in_regex = q/.^$*+?{}[]|()\\'"&ABdDGsSwWZgabfknrtvz0123456789xNocpP-/;        # issue s28: remove \u and \U, issue s81 allow \k and \z, issue s267: allow \- esp in character classes

sub remove_perl_escapes         # issue bootstrap
# Remove any escape sequences allowed by perl but not allowed by python, e.g. \[ \{ \$ \@ etc
# otherwise the '\' gets sent thru to the output.
{
    my $string = shift;
    my $in_regex = shift;
    my $has_double_brackets = (scalar(@_) == 0 ? 0 : $_[0]);   # issue s28

    return $string if($string !~ /\\/); # quickly scan for an escape char

    my $result = '';
    my $allowed = ($in_regex ? $allowed_escapes_in_regex : $allowed_escapes);
    my $mode = 0;               # issue s28
    my @stack = ();             # issue s28

    for(my $i =0; $i < length($string); $i++) {
        my $ch = substr($string,$i,1);
        if($ch eq "\\") {
            my $ch2 = substr($string,$i+1,1);
            if(index($allowed, $ch2) >= 0) {
                $result .= $ch . $ch2;
            } elsif(exists $SPECIAL_ESCAPE_MODES{$ch2}) {       # issue s28
                my $next_3 = substr($string,$i+1,3);
                if($next_3 eq "u\\L" || $next_3 eq "l\\U") {    # swap \u\L to \L\u and \l\U to \U\l
                    substr($string,$i+1,1) = substr($next_3,2,1);
                    substr($string,$i+3,1) = substr($next_3,0,1);
                    $ch2 = substr($string,$i+1,1);
                }
                my $m = $SPECIAL_ESCAPE_MODES{$ch2};
                if($m == 0) {   # \E
                    if(scalar(@stack) == 0) {
                        $mode = 0;
                    } else {
                        $mode = pop @stack;
                    }
                } else {
                    if($m & L_mode) {           # these modes are mutually exclusive
                        $mode &= ~U_mode;
                        $mode &= ~F_mode;
                    } elsif($m & U_mode) {
                        $mode &= ~L_mode;
                        $mode &= ~F_mode;
                    } elsif($m & F_mode) {
                        $mode &= ~U_mode;
                        $mode &= ~L_mode;
                    }
                    push @stack, $mode;
                    $mode |= $m;
                }
            } else {
                $result .= $ch2;
            }
            $i++;
            next;
        }
        if($mode & L_mode) {            # issue s28
            $ch = lc $ch;
        } elsif($mode & U_mode) {
            $ch = uc $ch;
        } elsif($mode & F_mode) {
            $ch = fc $ch;
        }
        if($mode & l_mode) {
            $ch = lc $ch;
            $mode = (scalar(@stack) ? pop @stack : 0);
        } elsif($mode & u_mode) {
            $ch = uc $ch;
            $mode = (scalar(@stack) ? pop @stack : 0);
        }
        if($mode & Q_mode) {
            $ch = quotemeta $ch;
            if(!$is_regex && substr($ch,0,1) eq "\\") {  # we need to double the escapes so the "\" character comes thru as we are not generating a 'r' string in python
                $ch = "\\" . $ch;
            }
        }

        $result .= $ch;
    }
    # issue s28 return $result;
    return perl_hex_escapes_to_python($result, $has_double_brackets); # issue s28: We interpolate after now to handle perl \u and \U properly
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
my $x_flag=$_[3];       # issue s80
my $s_rhs = (scalar(@_) > 4 ? $_[4] : 0);       # issue bootstrap: Is this on the RHS of a s/// ?
   if($::debug > 4 && $Pythonizer::PassNo != &Pythonizer::PASS_0) {
       say STDERR "put_regex_in_quotes($string, $delim, $original_regex)";
   }
   if($x_flag == 2) {           # double 'x' flag
       $string = squash_double_x_flag_regex($string);
   }
   if($delim ne "'") {  # issue 111
       $string =~ s/\$\&/\\g<0>/g if $s_rhs;  # issue 11, issue s192: only on RHS on s///
       $string =~ s/\$([1-9])/\\g<$1>/g if $s_rhs; # issue 11, SNOOPYJC: Not for $0 !!!, issue s192: only on RHS of s///
       # SNOOPYJC if( $string =~/\$\w+/ ){
       # issue 111 if( $string =~/^\$\w+/ ){    # SNOOPYJC: We have to interpolate all $vars inside!! e.g. /DC_$year$month/ gen rf"..."
       # issue 111 return substr($string,1); # this case of /$regex/ we return the variable.
       # issue 111 }
       # issue s81 $string = perl_regex_to_python($string) unless($s_rhs);          # issue 111, issue bootstrap
       $ValPy[$tno] = $string;                           # issue 111
       interpolate_strings($string, $original_regex, 0, 0, 1, $x_flag);          # issue 111, issue s80
       $ValPy[$tno] = escape_re_sub($ValPy[$tno],$delim) if($s_rhs);   # issue bootstrap
       $ValPy[$tno] = perl_regex_to_python($ValPy[$tno], 1) unless($s_rhs);          # issue 111, issue bootstrap, issue s81
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
    my $quoted = scalar(@_) ? $_[0] : 0;        # issue s81

    return $regex if(exists $Pass0::line_no_convert_regex{$.});        # issue s64

    # issue s64: Don't convert these 2 regexes from perl to python while bootrapping:
    # pragma pythonizer no convert regex
    $regex =~ s'\\Z'$'g;
    # pragma pythonizer no convert regex
    $regex =~ s'\\z'\\Z'g;
    $regex =~ s/\(\?<(\w)/(?P<$1/g;           # Named capture group
    $regex =~ s/\\g([1-9])/\\$1/g;            # issue s192
    $regex =~ s/\\g\{([1-9])\}/\\$1/g;        # issue s192
    $regex =~ s/\\[gk]\{([A-Za-z_]\w*)\}/(?P=$1)/g;           # Backreference to a named capture group
    $regex =~ s/\\k<([A-Za-z_]\w*)>/(?P=$1)/g;           # Backreference to a named capture group
    $regex =~ s/\\k'([A-Za-z_]\w*)'/(?P=$1)/g;           # Backreference to a named capture group
    # Handle some of the unicode properties:
    if($regex =~ /\\[pP]/) {                    # issue s240
        $regex = handle_pP_unicode($regex);     # issue s240
    }                                           # issue s240
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
    # issue s81 $regex =~ s'\[:punct:\]'!"\#%&\'()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$'g;
    $regex =~ s'\[:punct:\]'!"\#%&\x27()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$'g;         # issue s81: escape the '
    $regex =~ s'\[:space:\]' \t\r\n\x0b\f'g;
    $regex =~ s/\[:upper:\]/A-Z/g;
    $regex =~ s/\[:word:\]/A-Za-z0-9_/g;
    $regex =~ s/\[:xdigit:\]/A-Fa-f0-9/g;
    
    # issue bootstrap - escape '{' and '}' unless a legit repeat specifier
    $regex =~ s/^\{/\\{/;
    $regex =~ s/^(['"]{1,3})\{/$1\\{/ if($quoted);              # issue s81
    $regex =~ s/\|\{/|\\{/g unless $quoted && $regex =~ /^f/;   # issue s81
    $regex =~ s/\(\{/(\\{/g unless $quoted && $regex =~ /^f/;   # issue s81
    $regex =~ s/\(\?:\{/(?:\\{/g unless $quoted && $regex =~ /^f/;      # issue s81

    if($Pythonizer::PassNo==&Pythonizer::PASS_2) {
        if($regex =~ /(?:(?<=[\\][\\])|(?<![\\]))\\G/) {
            logme('S', "Sorry, the \\G regex assertion (match at pos) is not supported");
        } elsif($regex =~ /\(\?R\)/ || $regex =~ /\(\?[+-]\d+\)/) {
            logme('S', "Sorry, regex recursion '$&' is not supported");
        } elsif($regex =~ /\(\?&\w+\)/) {
            logme('S', "Sorry, regex subroutines '$&' are not supported");
        } elsif($regex =~ /\\p/) {
            logme('S', "Sorry, not all \\p unicode regex properties are supported");
        } elsif($regex =~ /\\P/) {
            logme('S', "Sorry, not all \\P complement unicode regex properties are supported, and they are only handled outside of a character class or the first thing in a character class");
        }
    }

    return $regex;
}

sub escape_only_backslash               # issue s23
# Escape only the backslach character in the given string
{
    my $string = shift;
    return $string =~ s/\\/\\\\/gr;
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
        $line =~ s/\(r?f"\{_bn\(([\w.]+)\)\}"/($1 if isinstance($1, re.Pattern) else _str($1)/;     # issue s117
    } else {
        $line =~ s/\(r?f"\{([\w.]+)\}"/(_str($1)/;
    }

    # Change "[v1,v2,v3] = perllib.list_of_n(perllib.Array(), N)" -to-
    #        v1 = v2 = v3 = None
    if($line =~ /^\s*\[([\w.]+(?:,[\w.]+)*)\] = perllib\.list_of_n\(perllib.Array\(\), \d+\)/) {
        $line = ($1 =~ s/,/ = /gr) . " = None";
    }

    # Change "not len(X)" -to- "not X"
    $line =~ s/\bnot\s+len\(([A-Za-z0-9_]+)\)/not $1/g;
    
    # Can't do this here because the list can contain an array value which we won't know.
    # Instead, we check when we generate the code and don't put the _list_of_n in in the first place.
    #
    # Change "_list_of_n((7, 7, 7), 3" to "(7, 7, 7)"
    # Change: 'perllib.list_of_n(("", "", ""), 3)' to '("", "", "")'
    # 
    # if($line =~ /\b_list_of_n\(\(.*\), (\d+)\)/) {
    #    if($line =~ /list_of_n\(/) {
    #        $line = optimize_list_of_n($line, $-[0]);
    #    }

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

=pod
sub optimize_list_of_n                                          # SNOOPYJC
# See if we can optimize out this _list_of_n call
{
    my $line = shift;   # Line of python code
    my $pos = shift;    # Points to start of "list_of_n("

    return $line if in_string($line, $pos);
    my $open = $pos + length('list_of_n');        # Point to '('
    return $line if substr($line, $open+1, 1) ne '(';    # We must have list_of_n((...), N)
    my $close = python_matching_paren($line, $open);
    return $line if $close < 0;
    my $tuple_start = $open+1;
    my $tuple_end = python_matching_paren($line, $tuple_start);
    return $line if $tuple_end < 0;
    return $line if substr($line, $tuple_end+1, 2) ne ', ';
    my $count = substr($line, $tuple_end+3, ($close-($tuple_end+3)));
    return $line if $count !~ /\d+/;
    # LOL it's never that easy:
    #my $commas = substr($line, $tuple_start, ($tuple_end+1-$tuple_start)) =~ tr/,//;
    my $tuple_contents = substr($line, $tuple_start+1, ($tuple_end-1-$tuple_start));
    $tuple_contents = &Pythonizer::eat_strings($tuple_contents);
    my $commas = 0;
    for(my $i = 0; $i < length($tuple_contents); $i++) {
        my $ch = substr($tuple_contents,$i,1);
        if($ch eq '(') {
            my $end = python_matching_paren($tuple_contents, $i);
            return $line if($end < 0);
            $i = $end;
        } elsif($ch eq ',') {
            $commas++;
        }
    }
    return $line if $count != ($commas+1);

    if(substr($line, $pos-1, 1) eq '_') {       # _list_of_n
        $pos--;
    } elsif(substr($line, $pos-(length($PERLLIB)+1), length($PERLLIB)+1) eq "$PERLLIB.") {
        $pos -= (length($PERLLIB)+1);
    }
    # remove the list_of_n call and just leave the prefix, the tuple, and the suffix
    return substr($line, 0, $pos-1) . substr($line, $tuple_start, ($tuple_end+1-$tuple_start)) . substr($line, $close+1);
}
=cut

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
      my $indent=' ' x $::TabSize x $Pythonizer::CurNest;               # issue s228
      for( my $i=1; $i<@PythonCode; $i++  ){
         next unless(defined($PythonCode[$i]));
         next if( $PythonCode[$i] eq '' );
         if(substr($PythonCode[$i],-1,1) eq "\n") {             # issue s228
             $PythonCode[$i] .= $indent;                        # issue s228
         }                                                      # issue s228
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
              $chu = escape_keywords(substr($chu,1), 2);       # SNOOPYJC: remove the initial '_' but change keywords like import to import_, issue s200: don't change stat
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

sub ok_to_break_line            # issue s228
# Is it OK to break the python line here and put in a comment?
{
    my $balance = 0;
    for(my $i = $#PythonCode; $i; $i--) {
        my $c = $PythonCode[$i];
        $balance-- if($c eq ']' || $c eq '}' || $c eq ')');
        $balance++ if($c eq '[' || $c eq '{' || $c eq '(');
        next if $c =~ /^['"]/ || $c =~ /^[fr]+['"]/;
        $balance-- if($c =~ /[})\]]/);
        $balance++ if($c =~ /[{(\[]/);
        return 1 if $balance > 0;
    }
    return 0;
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
   if($pos <= $#ValType) {      # issue 37 - sometimes it's not set
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
   if($pos <= $#ValCom) {               # issue s228
       splice(@ValCom,$pos,0,'');       # issue s228
   }                                    # issue s228
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
    if(scalar(@ValType) >= $from+$howmany) {    # issue 37
        splice(@ValType,$from,$howmany);    # issue 37
    }
    if(scalar(@ValCom) >= $from+$howmany) {    # issue s228: don't lose comments
        for(my $i = $from; $i < ($from+$howmany); $i++) {
            if(defined $ValCom[$i] && length($ValCom[$i]) > 1) {
                if($from+$howmany <= $#ValClass) {      # Try moving it later if possible
                    $ValCom[$from+$howmany] .= $ValCom[$i];
                } elsif($from-1 > 1) {                  # Else try moving it earlier
                    $ValCom[$from-1] .= $ValCom[$i];
                }
            }
        }
        splice(@ValCom,$from,$howmany);    # issue s228
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

sub matching_curly_br           # issue 43
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

sub matching_square_br          # issue 43
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

my %reverse_escaped_names = ();     # issue s18
sub unescape_keywords {             # issue s18
    my $escaped = $_[0];

    if(exists $reverse_escaped_names{$escaped}) {
        return $reverse_escaped_names{$escaped};
    }
    return $escaped;
}

sub escape_keywords     # issue 41
# Accepts a name and escapes any python keywords in it by appending underscores.  The name can
# be a period separated list of names.  Returns the escaped name.
# Note: We also escape the names of the built-in functions like len, etc
{
    my $name = $_[0];
    my $is_package_name = (scalar(@_) >= 2) ? $_[1] : 0;        # issue s200
    state %Pyf;             # issue s126

    if(!keys %Pyf) {                    # issue s126
        if(!$::import_perllib) {
            my @py_files = glob("$::Pyf_dir/*.py");
            foreach my $py (@py_files) {
                my $bn = basename($py);
                $bn =~ s/\.py$//;
                $Pyf{$bn} = 1;
            }
        }
        $Pyf{_str} = 1; $Pyf{_bn} = 1; $Pyf{_pb} = 1;
    }

    my @ids = split /[.]/, $name;
    my @result = ();
    for(my $i=0; $i<scalar(@ids); $i++) {
           $id = $ids[$i];
       if($is_package_name == 2) {
          if($PYTHON_RESERVED_SET{$id} && !exists $PYTHON_PACKAGES_SET{$id}) {       # issue s200 
             $id = $id.'_';
          }
       } elsif(exists $PYTHON_RESERVED_SET{$id} || ($id eq $DEFAULT_PACKAGE && ($i != 0 || $id eq $name) && !$is_package_name && !$::implicit_global_my)) {
           if(scalar(@ids) == 1 || !exists $PYTHON_PACKAGES_SET{$id}) {           # issue s200: Don't change sys. to sys_., don't change perllib.stat to perllib.stat_
               $id = $id.'_';
           }
       } elsif(substr($id,0,1) =~ /\d/) {   # issue ddts: @1234 => _1234
           $id = '_'.$id;
       } elsif($i == 0 && substr($id,0,1) eq '_' && substr($id,0,5) ne '__END' && $id !~ /^_f\d/ && exists $Pyf{$id}) {    # issue s126
           $id = $id.'_';                   # issue s126
       }
       $reverse_escaped_names{$id} = $ids[$i];      # issue s18
       push @result, $id;
       if($i != 0) {
           $reverse_escaped_names{join('.', @result)} = join('.', @ids[0..$i]);
       }
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
    # issue s172 $NameMap{$name}{$sigil} = escape_keywords($package_name, 1) . '.' . $py_name;
    my $new_name = escape_keywords($package_name, 1) . '.' . $py_name;          # issue s172
    $NameMap{$name}{$sigil} = $new_name;            # issue s172
    $ReverseNameMap{$new_name} = $name;             # issue s172
    return $new_name;                               # issue s18
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
    # issue s172 return array_var_name($name) if($sigil eq '@');
    # issue s172 return hash_var_name($name) if($sigil eq '%');
    # issue s172 return scalar_var_name($name) if($sigil eq '$');
    my $result = $name;                     # issue s172
    if($sigil eq '@') {                     # issue s172
        $result = array_var_name($name)     # issue s172
    } elsif($sigil eq '%') {                # issue s172
        $result = hash_var_name($name)      # issue s172
    } elsif($sigil eq '$') {                # issue s172
        $result = scalar_var_name($name)    # issue s172
    } else {                                # issue s172
        return $name;                       # issue s172: No sigil means we need to leave the name alone
    }                                       # issue s172
    while(exists $ReverseNameMap{$result} && $ReverseNameMap{$result} ne $name) { # issue s172
        $result .= substr($result,-1,1);    # issue s172: Add another of the last char until we find one not used
    }                                       # issue s172
    return $result;                         # issue s172
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
    # issue s172 return $name if($id =~ /_[avh]$/ && exists $NameMap{($i=substr($id,0,length($id)-2))} && $NameMap{$i}{$sigil} eq $id);
    if(exists $ReverseNameMap{$id} && exists $NameMap{($i=$ReverseNameMap{$id})}{$sigil} && $i ne $id && $NameMap{$i}{$sigil} eq $id) { # issue s172
        return $name            # issue s172: Already mapped properly
    }                           # issue s172

    # If a package name is present and it's not a package defined in this file, then attempt to find
    # the Python file containing that package, see how the names are mapped in there, and mirror that to the
    # variable reference here.
    my $mid = mapped_name($id, $sigil, $trailer);       # e.g. name_a, name_h, name_v if we need to remap it
    if(scalar(@ids) > 1) {              # we have a package
        if(exists $NameMap{$name} && exists $NameMap{$name}{$sigil}) {  # we have a mapping for the full name already
            my $mapping = $NameMap{$name}{$sigil};
            if($sigil eq '$') {                         # issue s252: Handle for loop with fully qualified index
                my $ctr_type;                           # issue s252
                if(($ctr_type = for_loop_local_ctr($name, $trailer))) {         # issue s252
                    $mapping = remap_loop_var($name, $ctr_type);       # issue s252
                }                                       # issue s252
            }
            say STDERR "remap_conflicting_names($name,$s,$trailer) = $mapping (p0)" if($::debug >= 5);
            return $mapping;
        }
        # issue names: Just assume any name with a package is mapped
        $ids[-1] = $mid;
        my $mapping = join('.', @ids);
        $NameMap{$name}{$sigil} = $mapping;
        $ReverseNameMap{$mapping} = $name;              # issue s172
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
    if($sigil eq '$') {                         # issue s100
        my $ctr_type;                           # issue s100
        if(($ctr_type = for_loop_local_ctr($name, $trailer))) {         # issue s100, issue s235
            $mid = remap_loop_var($name, $ctr_type);       # issue s100
            $ids[-1] = $mid;                    # issue s100
        }                                       # issue s100
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
        my $was_mapped = exists $NameMap{$id} && exists $NameMap{$id}{$sigil};      # issue s215
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
        $ReverseNameMap{$ids[-1]} = $id;              # issue s172
        if(scalar(@ids) > 1 && index($ids[-1],'.') >= 0) {
            # We have a name we imported that we have referenced with the fully qualified name, 
            # remove the extra package name
            my $p_dot = rindex($ids[-1], '.');
            $ids[-1] = substr($ids[-1], $p_dot+1);
        }
        # issue s215: If we change a name we already mapped differently, then we have to change our Pythonizer variables for it
        my $nam = $id;                      # issue s215
        my $mnp = join('.', @ids);          # issue s215
        if($was_mapped && $nam ne $mnp) {                  # issue s215
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
        say STDERR "remap_conflicting_names($name,$s,$trailer) = " . join('.', @ids) . ' (2)' if($::debug >= 5);
        return (join('.', @ids));
    }
    # We have a sub or a FH at this point - map other names and leave him alone
    $NameMap{$id}{$sigil} = $id;
    $ReverseNameMap{$id} = $id;              # issue s172
    for $sig (('@', '%', '$')) {
        if($sig ne $sigil) {
            last if(!exists $NameMap{$id});
            next if(!exists $NameMap{$id}{$sig});
            if($NameMap{$id}{$sig} eq $id) {
                my $mn = mapped_name($id, $sig, '');
                say STDERR "remap_conflicting_names($name,$s,$trailer): Remapping old $sig$id to $mn due to $sigil$id" if($::debug >= 3);
                $NameMap{$id}{$sig} = $mn;
                $ReverseNameMap{$mn} = $id;              # issue s172
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

sub for_loop_local_ctr      # issue s100
# is this name the loop counter that needs to be localized within the loop?
# next_c is the next character to be lexxed
{
    my $name = shift;
    my $next_c = shift;

    # Cases to match:
    # for $name (...)
    # for my $name (...)
    # foreach $name (...)
    # foreach my $name (...)
    # for(my $name=...; ...; ...)
    return 0 if $#ValClass < 1;
    return 0 if $ValClass[0] ne 'c';
    return 0 if $ValPy[0] ne 'for';
    # We can't use this here!!  return 0 if &Pythonizer::for_loop_uses_default_var(0);       # issue s235
    if($ValClass[1] eq '(') {
        if(exists $line_contains_local_for_loop_counter{$statement_starting_lno} && exists $line_contains_local_for_loop_counter{$statement_starting_lno}{$name}) {     # issue s108
            return $line_contains_local_for_loop_counter{$statement_starting_lno}{$name};   # issue s108
        }
        for(my $i = 2; $i < $#ValClass; $i++) {
            return 0 if($ValClass[$i] eq ';');
            return 'my' if($ValClass[$i] eq 't' && $#ValClass == $i+1 && $ValClass[$i+1] eq 's' && $ValPy[$i+1] eq $name);     # for(my $name=...
        }
        return 0;
    } elsif($ValClass[1] eq 't' && $#ValClass >= 2 && $ValClass[2] eq 's' && $ValPy[2] eq $name) { # foreach my $name
        return 'my';
    } elsif($ValClass[1] eq 's' && $ValPy[1] eq $name && ($next_c eq '(' || $next_c eq ' ' || $next_c eq '') ) {    # foreach $name, issue s235
        return 'local';
    }
    return 0;
}

sub remap_loop_var          # issue s100
# If necessary, remap the loop var to be loop_var_l so it is distinct from scalars of the same name
# Returns the new python name, if need be, else returns the original name
{
    my $name = shift;
    my $type = shift;           # 'local' or 'my'

    my $original_name = $name;
    my $sigil = '$';
    if(substr($name,-1,1) eq '_') {             # if we have like 'in_' which used to be 'in', then get us 'in'
        my $without_escape = substr($name,0,length($name)-1);
        my $esc = escape_keywords($without_escape);
        $name = $without_escape if($esc eq $name);
    # issue s172 } elsif(substr($name,-2,2) eq '_v') {       # if we have like 'var_v' which used to be 'var', then get us 'var'
    # issue s172     $name = substr($name,0,length($name)-2);
    } elsif(exists $ReverseNameMap{$name}) {            # issue s172
        $name = $ReverseNameMap{$name};                 # issue s172
    }

    my $remap = 0;
    if($Pythonizer::PassNo == &Pythonizer::PASS_1) {
        if(in_sub() ||                                      # issue s108
           (exists $NameMap{$name} && exists $NameMap{$name}{$sigil})) {  # we have a mapping for the full name already
            if(!exists $line_contains_local_for_loop_counter{$statement_starting_lno} ||
               (exists $line_contains_local_for_loop_counter{$statement_starting_lno} && !exists $line_contains_local_for_loop_counter{$statement_starting_lno}{$name})) {     # only do it once, issue s108
                my $pname = $sigil . $name;
                my $vc = 'unknown';
                if(exists $line_varclasses{$last_varclass_lno}{$pname}) {
                    $vc = $line_varclasses{$last_varclass_lno}{$pname};
                }
                #say STDERR "For $name with $type on line $., varclass = $vc";
                $type = 'my' if($type eq 'local' && ($vc eq 'myfile' || $vc eq 'my'));
                $line_contains_local_for_loop_counter{$statement_starting_lno}{$name} = $type;  # issue s108
                if($type eq 'local') {
                    my $esc = escape_keywords($original_name);                              # issue s106
                    $esc = $NameMap{$esc}{$sigil} if exists $NameMap{$esc}{$sigil};         # issue s106
                    if(!exists $Pythonizer::NeedsInitializing{__main__}{$esc}) {            # issue s106
                         $Pythonizer::NeedsInitializing{__main__}{$esc} = 'm';              # issue s106
                    }                                                                       # issue s106
                    $Pythonizer::VarSubMap{$esc}{__main__} = '+';                           # issue s108
                    $line_needs_try_block{$statement_starting_lno} |= TRY_BLOCK_FINALLY|TRY_BLOCK_FOREACH;  # issue s108
                }
                $remap = 1 if $type eq 'my';
            }
        }
    } elsif($Pythonizer::PassNo == &Pythonizer::PASS_2) {
        if(exists $line_contains_local_for_loop_counter{$statement_starting_lno} && exists $line_contains_local_for_loop_counter{$statement_starting_lno}{$name}) {     # issue s108
            if(($type = $line_contains_local_for_loop_counter{$statement_starting_lno}{$name}) !~ /done/) {     # issue s108
                $remap = 1 if $type eq 'my';
                $line_contains_local_for_loop_counter{$statement_starting_lno}{$name} .= 'done';   # only do it once per name, issue s108
            }
        }
    }
    if($remap) {
        my $mapped = $NameMap{$name}{$sigil};
        $NameMap{$name}{'!'} = $mapped;             # Save the old name
        my $loop_name = loop_var_name($name);
        while(exists $ReverseNameMap{$loop_name} && $ReverseNameMap{$loop_name} ne $name) { # issue s172
            $loop_name .= substr($loop_name,-1,1);  # issue s172: Add another of the last char until we find one not used
        }                                           # issue s172
        $NameMap{$name}{$sigil} = $loop_name;
        $ReverseNameMap{$loop_name} = $name;        # issue s172
        say STDERR "remap_loop_var($name) = $loop_name" if($::debug >= 5);
        return $NameMap{$name}{$sigil};
    }
    my $esc = escape_keywords($original_name);                              # issue s252
    return $NameMap{$esc}{$sigil} if exists $NameMap{$esc}{$sigil};         # issue s252
    return $original_name;
}

sub unmap_loop_var          # issue s100
# Undo any loop var mapping at the end of the loop
# arg = perl name of loop var
{
    my $perl_name = shift;
    my @perl_names = split(/,/, $perl_name);        # issue s252: We now keep all nested loops listed in order inner..outer
    $perl_name = $perl_names[0];                    # issue s252: So just grab the inner-most one

    my $sigil = substr($perl_name, 0, 1);
    my $name = substr($perl_name, 1);
    if(exists $NameMap{$name} && exists $NameMap{$name}{'!'}) { # We saved the original mapping
        if(defined $NameMap{$name}{'!'}) {                  # issue s108
            $NameMap{$name}{$sigil} = $NameMap{$name}{'!'};
        } else {                                            # issue s108
            delete $NameMap{$name}{$sigil};                 # issue s108
        }                                                   # issue s108
        delete $NameMap{$name}{'!'};
        delete $ReverseNameMap{loop_var_name($name)};       # issue s172
        say STDERR "unmap_loop_var($name) = $NameMap{$name}{$sigil}" if($::debug >= 5);
    }
}

sub perl_name_to_py                 # issue s252
# Convert a perl name to a python name
{
    my $name = shift;
    my $sigil = substr($name, 0, 1);
    if(index('*@$%&', $sigil) != -1) {
        $name = substr($name, 1);
    } else {
        $sigil = '';
    }
    $name=~tr/:/./s;            # SNOOPYJC
    $name=~tr/'/./s;            # SNOOPYJC
    $name = remap_conflicting_names($name, $sigil, '');
    $name = escape_keywords($name);
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

    my $orig_source_length = length($source);   # issue test coverage

    while(1) {
        return $source if($source =~ /^%\s*\$/);        # Don't mess up mod (%) operator
        $source =~ s/(.)\s*(?!#)/$1/;       # Allow whitespace but not $ # (see end of test_ws_after_sigil.pl for example)
        last if($in_string);                    # That's all you get!
        $source =~ s/(.)\s*#.*$/$1/;
        last if length($source) > 1;
        # if we get here, we ran out of road - grab the next line and keep going!
        my @tmpBuffer = @BufferValClass;    # Must get a real line even if we're buffering stuff
        @BufferValClass = ();
        my $line = Pythonizer::getline();
        $StatementStartingLno{$.} = $statement_starting_lno;    # issue s275
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
    my $new_source_length = length($source);    # issue test coverage
    if($new_source_length < $orig_source_length) {      # issue test coverage
        my $diff = $orig_source_length - $new_source_length;
        $ExtractingTokensFromDoubleQuotedTokensEnd-=$diff;   # issue test coverage
        $ExtractingTokensFromDoubleQuotedStringEnd-=$diff;   # issue test coverage
        say STDERR "ExtractingTokensFromDoubleQuotedTokensEnd=$ExtractingTokensFromDoubleQuotedTokensEnd, ExtractingTokensFromDoubleQuotedStringEnd=$ExtractingTokensFromDoubleQuotedStringEnd, source=$source after get_rest_of_variable_name" if($::debug>=5 && $Pythonizer::PassNo == &Pythonizer::PASS_1);
    }
    say STDERR "get_rest_of_variable_name(".substr($source,0,1).", $in_string), lno=$., source='$source'" if($::debug >= 3 && $Pythonizer::PassNo != &Pythonizer::PASS_0);
    return $source;
}

my %ch_escapes = (t=>"\t", n=>"\n", r=>"\r", f=>"\f", b=>"\b", a=>"\a", e=>"\e", v=>"\013");

sub end_of_escape               # issue s28
# Given a string that starts with an escape sequence, return the index to the last char of
# that escape sequence.
{
    my $arg = shift;
    my $has_double_brackets = shift;

    my $i = 0;
    # Code skeleton stolen from unescape_string

    my $ch2 = substr($arg,$i+1,1);
    if(exists $ch_escapes{$ch2}) {
        $i++;
    } elsif($ch2 eq 'x') {
        my $ch3 = substr($arg,$i+2,1);
        if($ch3 eq '{') {
            my $end_br = matching_curly_br($arg, $i+2);
            if($has_double_brackets) {          # issue s28
                $i++;
                $end_br--;
            }
            $i = $end_br;
            $i++ if $has_double_brackets;
        } else {
            if(substr($arg,$i+2) =~ /([0-9a-fA-F]+)/) {
                $i += length($1)+1;
            } else {
                $i++;
            }
        }
    } elsif($ch2 eq 'c') {
        $i+=2;
    } elsif($ch2 eq 'o' && substr($arg,$i+2,1) eq '{') {
        my $end_br = matching_curly_br($arg, $i+2);
        if($has_double_brackets) {          # issue s28
            $i++;
            $end_br--;
        }
        $i = $end_br;
        $i++ if $has_double_brackets;
    } elsif($ch2 eq 'N' && substr($arg,$i+2,1) eq '{') {
        my $end_br = matching_curly_br($arg, $i+2);
        if($has_double_brackets) {          # issue s28
            $i++;
            $end_br--;
        }
        $i = $end_br;
        $i++ if $has_double_brackets;
    } elsif(substr($arg,$i+1) =~ /([0-7]+)/) {
        $i += length($1);
    } elsif($ch2 eq '-') {
        $i++;
    } elsif($ch2 eq "\\") {     # issue s27
        $i++
    } else {
        $i++;
    }
    say STDERR "end_of_escape($arg) = $i" if($::debug >= 5);
    return $i;
}

sub unescape_string             # SNOOPYJC
# Given a string remove all escapes in it, except for \-, issue s27: and \\
{
    my $arg = shift;
    my $has_double_brackets = (@_ >= 1 ? $_[0] : 0);    # issue s28
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
                    if($has_double_brackets) {          # issue s28
                        $i++;
                        $end_br--;
                    }
                    $ch = chr(hex(substr($arg,$i+3,$end_br-($i+3))));
                    $i = $end_br;
                    $i++ if $has_double_brackets;
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
                if($has_double_brackets) {          # issue s28
                    $i++;
                    $end_br--;
                }
                $ch = chr(oct(substr($arg,$i+3,$end_br-($i+3))));
                $i = $end_br;
                $i++ if $has_double_brackets;
            } elsif($ch2 eq 'N' && substr($arg,$i+2,1) eq '{') {
                my $end_br = matching_curly_br($arg, $i+2);
                if($has_double_brackets) {          # issue s28
                    $i++;
                    $end_br--;
                }
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
                $i++ if $has_double_brackets;
            } elsif(substr($arg,$i+1) =~ /([0-7]+)/) {
                $ch = chr(oct($1));
                $i += length($1);
            } elsif($ch2 eq '-') {
                $ch = "\\-";
                $i++;
            } elsif($ch2 eq "\\") {     # issue s27
                $ch = "\\\\";           # issue s27 - this is 2 backslashes
                $i++
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
                # issue s23 $result .= $ch;
                $ch = substr($arg,$i+1,1);      # issue s23
                $i++;                           # issue s23
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
    # issue s23 return escape_non_printables($result, 1);
    return $result;             # issue s23
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
    # issue s86: Also replace strings that exactly contain the filename and nothing else
    $py =~ s/^'$fname'$/'$pyname'/;     # issue s86
    $py =~ s/^"$fname"$/"$pyname"/;     # issue s86

    return $py;
}

sub replace_run                       # issue s87
# For the -y flag, replace "any_path.pl -flags" with "any_path.py --flags"
{
    my $py = shift;

    if(index($py, '://') >= 0) {        # Don't do this to URLs
        return $py;
    }
    if($ValClass[0] eq 'k' && $ValPerl[0] eq 'require') {       # Don't do this on require statements because we need to import the perl code at translation time, and the extension is ignored in perllib.import_
        return $py;
    }
    if($py eq "'.pl'") {        # issue s112
        return $py;             # issue s112
    }                           # issue s112

    my $term = "'";
    # if($py =~ m(^(f?(?:'''|"""|'|")(?:[A-Za-z]:)?)((?:(?:[\\/])?[A-Za-z0-9_.-]*)*)[.]pl\b(.*)$)) {
    # issue bootstrapping if($py =~ m(^(f?(?:'''|"""|'|")(?:[A-Za-z]:)?)((?:(?:[\\/])?(?:[{][^}]+[}])*|[A-Za-z0-9_.-]*)*)[.]pl\b(.*)$)) {
    if($py =~ m(^(f?(?:'''|""\"|'|")(?:[A-Za-z]:)?)((?:{[^}]+}|[A-Za-z0-9_\\/.-])*)\.pl\b(.*)$)) {   # issue bootstrapping
        my $prefix = $1;
        my $path = $2;
        my $rest = $3;
        $rest =~ s/ -([A-Za-z][A-Za-z0-9_-]+)/ --$1/g;          # fix up single dash long options
        $py = $prefix . $path . '.py' . $rest;
        logme('W', "Replacing $path.pl with $path.py - use -Y if this is incorrect") if $Pythonizer::PassNo==&Pythonizer::PASS_2;
    }

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
               $result .= "\\" if(index("abfntr", $ch2) >= 0 && $delim eq "'");       # issue s115
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
    my $dir = dirname($Pythonizer::fname);                  # issue s133
    for(my $i=$pos+2; $i<=$#ValClass; $i++) {
        if($ValClass[$i] eq '"') {          # Plain String
            my $lib = $ValPy[$i];                                   # issue s133
            if($lib eq 'f""""""' && $i+1 <= $#ValClass && $ValPerl[$i+1] eq '$FindBin::Bin') {    # issue s133
                # In PASS_1, "..." are expanded, so handle FindBin here
                $lib = '"' . $dir;                                  # issue s133
                $i++;                                               # issue s133
                if($i+1 <= $#ValClass && $ValClass[$i+1] eq '"') {  # issue s133
                    $lib .= &::unquote_string($ValPy[$i+1]);        # issue s133
                    $i++;                                           # issue s133
                }                                                   # issue s133
                $lib .= '"';                                        # issue s133
            } else {                                                # issue s133
                $lib =~ s/\{_bn\(FindBin\.Bin_v\)\}/$dir/;          # issue s133
            }                                                       # issue s133
            push @libs, $lib;                                       # issue s133
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
        } elsif($ValClass[$i] eq 's' && $ValPerl[$i] eq '$FindBin::Bin') {  # issue s133
            push @libs, ('"' . $dir . '"');                                 # issue s133
        }
    }
    say STDERR "For @ValPerl, using @libs (after stripping the '')" if($::debug);
    unshift @UseLib, map {&::unquote_string($_)}  @libs;
}

sub handle_use_overload                         # issue s3
# use overload key => \&sub, ...
{
    my $pos = 0;
    for(my $i=$pos+2; $i<=$#ValClass; $i++) {
        if($ValClass[$i] eq 'i') {          # sub
            # issue s241 $Pythonizer::SubAttributes{$ValPy[$i]}{overloads} = 1;
            &Pythonizer::set_sub_attribute($ValPy[$i], 'overloads', 1); # issue s241
        }
    }
}

sub handle_use_Switch
# use Switch;
# use Switch LIST;
{
    my $pos = 0;
    if($Pythonizer::PassNo!=&Pythonizer::PASS_1) {
        return;
    }
    my @sw = ();
    for(my $i=$pos+2; $i<=$#ValClass; $i++) {
        if($ValClass[$i] eq '"') {          # Plain String
            push @sw, $ValPy[$i];
        } elsif($ValClass[$i] eq 'q') {     # qw(...) or the like
            if(index(q('"), substr($ValPy[$i],0,1)) >= 0) {
                push @sw, $ValPy[$i];
            } else {
                push @sw, map {'"'.$_.'"'} split(' ', $ValPy[$i]);         # qw(...) on use stmt doesn't generate the split
            }
        } elsif($ValClass[$i] eq 'f') {     # Handle dirname($0) only
            if($ValPerl[$i] eq 'dirname' && $ValPerl[$i+1] eq '$0') {
                push @sw, '"' . dirname($Pythonizer::fname) . '"';
                $i++;
            } elsif($ValPerl[$i] eq 'dirname' && $ValPerl[$i+1] eq '(' && $ValPerl[$i+2] eq '$0') {
                push @sw, '"' . dirname($Pythonizer::fname) . '"';
                $i += 3;
            } else {
                logme('W', "use lib $ValPerl[$i]() not handled!");
            }
        }
    }
    say STDERR "For @ValPerl, using @sw (after stripping the '')" if($::debug);
    %UseSwitch = map {&::unquote_string($_) => 1}  @sw;
    $TokenType{switch} = $TokenType{given};
    $TokenType{case} = $TokenType{when};
    $keyword_tr{switch} = 'given';
    $keyword_tr{case} = 'when';
}

sub handle_use_utf8       # issue s70
# issue s70: for the use utf8 pragma in pass 1, change the decode method we are using for the input file to force utf8
{
    $Pythonizer::f_encoding = 'utf8';
    $Pythonizer::f_decodobj = find_encoding('utf8') if !defined $Pythonizer::f_decodobj || $Pythonizer::f_decodobj->name ne 'utf8';
    $Pythonizer::f_encodobj = find_encoding('utf8') unless defined $Pythonizer::f_encodobj;
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

sub handle_use_parent           # issue s18
# use parent qw/this that/;
# use parent 'this', 'that';
# use parent '-norequire', 'this', 'that';
# use parent -norequire=>'this', 'that';
{
    my $norequire = 0;
    for(my $i = 2; $i <= $#ValClass; $i++) {
        if($ValClass[$i] eq '-') {
            $norequire = 1;
            $i++;
            last;
        }
    }
    unless($norequire) {
        my $saved_tokens = &::package_tokens();
        $TokenStr = join('', @ValClass);   # Required to use the Pythonizer functions
        destroy(0);
        insert(0, 'k', 'require', $keyword_tr{require});
        insert(1, 'i', '', '');
        for(my $i = 2; $i < scalar(@{$saved_tokens->{class}}); $i++) {
            my $class = $saved_tokens->{class}->[$i];
            next if $class eq ',' || $class eq 'A';
            if($class eq 'q') {
                my $perl = $saved_tokens->{perl}->[$i];
                $perl =~ s/\s+/ /g;             # Change newlines or multiple spaces to single spaces
                $perl =~ s/^\s+//;              # Remove leading spaces
                $perl =~ s/\s+$//;              # Remove trailing spaces
                foreach my $p (split ' ', $perl) {
                    my $python = $p;
                    $python =~ tr/::/./s;
                    $python =~ tr/'/./s;
                    replace(1, 'i', $p, $python);
                    $Pythonizer::UsePackage{$python} = $. unless exists $Pythonizer::UsePackage{$python};
                    handle_use_require(0);
                }
            } elsif($class eq '"' && $saved_tokens->{perl}->[$i] =~ /^[A-Za-z0-9:_]+$/) {
                my $python = $saved_tokens->{perl}->[$i];
                $python =~ tr/::/./s;
                $python =~ tr/'/./s;
                replace(1, 'i', $saved_tokens->{perl}->[$i], $python);
                $Pythonizer::UsePackage{$python} = $. unless exists $Pythonizer::UsePackage{$python};
                handle_use_require(0);              # Handle like a require statement
            } else {
                my $python = $saved_tokens->{py}->[$i];
                replace(1, $saved_tokens->{class}->[$i], $saved_tokens->{perl}->[$i], $python);
                $Pythonizer::UsePackage{$python} = $. if $class eq 'i' && !exists $Pythonizer::UsePackage{$python};
                handle_use_require(0);              # Handle like a require statement
            }
        }
        &::unpackage_tokens($saved_tokens);
    }
    for(my $i = 2; $i <= $#ValClass; $i++) {
        next if $ValClass[$i] eq ',' || $ValClass[$i] eq 'A';
        if($ValClass[$i] eq '-') {
            $i++;
            next;
        } elsif($ValClass[$i] eq 'q') {       # We don't expand qw for use statements, so do that here
            my $python = $ValPerl[$i];
            $python =~ s/\s+/ /g;             # Change newlines or multiple spaces to single spaces
            $python =~ s/^\s+//;              # Remove leading spaces
            $python =~ s/\s+$//;              # Remove trailing spaces
            append_ISA(&Perlscan::escape_quotes($python) . '.split()');
        } else {
            append_ISA($ValPy[$i]);
        }
    }
}

sub handle_ISA_assignment       # issue s18
# Handle an assignment to @ISA by grabbing the RHS for use on _init_package calls
{
    my $eq = shift;

    for(my $i = $eq+1; $i <= $#ValClass; $i++) {
        next if($ValClass[$i] eq '(' || $ValClass[$i] eq ',' || $ValClass[$i] eq ')');
        next if($ValClass[$i] =~ /[shaG]/);
        append_ISA($ValPy[$i]);
    }
}

sub append_ISA              # issue s18
# Append a value to the current @ISA -  for use on _init_package calls
{
    my $value = shift;

    my $package = cur_raw_package();
    my $key = $package . '.ISA';
    if(!exists $SpecialVarsUsed{$key}) {
        if($value =~ /\.split\(\)$/) {
            $value =~ s/\.split\(\)$//;
        }
        $value = &::unquote_string($value);
        $value =~ tr/::/./s;
        $value =~ tr/'/./s;
        my @oldvalue = ();
        foreach my $old (split ' ', $value) {
            if(exists $SpecialVarsUsed{'bless'} && exists $SpecialVarsUsed{'bless'}{$old}) {
                $SpecialVarsUsed{'bless'}{$package} = 1;
            }
            if(exists $SpecialVarsUsed{'bless'} && exists $SpecialVarsUsed{'bless'}{$package}) {
                $SpecialVarsUsed{'bless'}{$old} = 1;
            }
            push @oldvalue, $old unless exists $BUILTIN_LIBRARY_SET{$old};
        }
        return if !@oldvalue;
        $SpecialVarsUsed{$key}{__main__} = "'" . join(' ', @oldvalue) . "'.split()";
    } else {
        my $oldvalue = $SpecialVarsUsed{$key}{__main__};
        if($oldvalue =~ /\.split\(\)$/) {
            $oldvalue =~ s/\.split\(\)$//;
        }
        $oldvalue = &::unquote_string($oldvalue);
        $oldvalue =~ tr/::/./s;
        $oldvalue =~ tr/'/./s;
        
        if($value =~ /\.split\(\)$/) {
            $value =~ s/\.split\(\)$//;
        }
        $value = &::unquote_string($value);
        $value =~ tr/::/./s;
        $value =~ tr/'/./s;
        my @newvalue = ();
        foreach my $new (split ' ', $value) {
            next if $oldvalue =~ /\b$new\b/;
            if(exists $SpecialVarsUsed{'bless'} && exists $SpecialVarsUsed{'bless'}{$new}) {
                $SpecialVarsUsed{'bless'}{$package} = 1;
            }
            if(exists $SpecialVarsUsed{'bless'} && exists $SpecialVarsUsed{'bless'}{$package}) {
                $SpecialVarsUsed{'bless'}{$new} = 1;
            }
            push @newvalue, $new unless exists $BUILTIN_LIBRARY_SET{$new};
        }
        if(@newvalue) {
            $SpecialVarsUsed{$key}{__main__} = "'" . $oldvalue . ' ' . join(' ', @newvalue). "'.split()";
        } else {
            $SpecialVarsUsed{$key}{__main__} = "'" . $oldvalue . "'.split()";
        }
    }
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
         if($ValPerl[$pos+1] eq 'English') { # use English
            handle_block_scope_pragma($::uses_english, 'english',
                sub { $::uses_english = $_[0]; }, 
                ($ValPerl[$pos] eq 'no' ? 0 : 1));
         } elsif($ValPerl[$pos+1] eq 'integer') { # use integer
            handle_block_scope_pragma($::uses_integer, 'integer',
                sub { $::uses_integer = $_[0];
                      $CONVERTER_MAP{N} = ($::uses_integer ? '_int' : '_num');
                    }, 
                ($ValPerl[$pos] eq 'no' ? 0 : 1));
         }
         return;
     } elsif($pos+1 <= $#ValClass && $ValClass[$pos+1] eq 'i' && ($ValPerl[$pos+1] eq 'constant' || $ValPerl[$pos+1] eq 'open' || $ValPerl[$pos+1] eq 'overload')) {    # issue s3
         return;
     }

     # issue s4: return;             # issue names - had to map them all

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

     # issue s4
     my ($desired_version, @desired_imports);
     for(my $i = $pos+2; $i <= $#ValClass; $i++) {   # See what we have next
         if($ValClass[$i] eq 'i' && $ValPerl[$i] =~ /^v\d/) {
             $desired_version .= $ValPerl[$i];
         } elsif($ValClass[$i] eq 'd') {
             $desired_version .= $ValPerl[$i];
         } elsif($ValClass[$i] eq '"') {
             push @desired_imports, $ValPerl[$i];
         } elsif($ValClass[$i] eq 'q') {        # qw
            if(index(q('"), substr($ValPy[$i],0,1)) >= 0) {
                push @desired_imports, &::unquote_string($ValPy[$i]);   # test coverage
            } else {
                push @desired_imports, split(' ', $ValPy[$i]);         # qw(...) on use stmt doesn't generate the split
            }
        }
    }
    $desired_version = substr($desired_version,1) if($desired_version && substr($desired_version,0,1) eq 'v');

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
    # issue s4/issue bootstrap if(! -f $fullfile) {     # Can't find it
    # issue s4/issue bootstrap     say STDERR "handle_import($fullfile): file not found" if($::debug);
    # issue s4/issue bootstrap     return;
    # issue s4/issue bootstrap }

    # issue s4 - do an import of the module to see what names we have to care about.  
    # import_perl_to_python has the side-effect of calling add_package_to_mapped_name,
    # which is what we need to get the s4 issue fixed.
    my ($fmap, $extras, $version) = &::expand_extras(\@desired_imports, $fullfile);
    %found_map = %{$fmap};
    my %actual_imports = map { $_ => 1 } @{$extras};
    my @py_export = map { &::import_perl_to_python(\%found_map, $_) } keys %actual_imports;
    say STDERR "For @ValPerl, found ($path, " . join(', ', @py_export) . ")" if($debug);

=pod    # issue s4 - we don't need this any more that we default -R
    my $dir = dirname(__FILE__);
    #say STDERR "before: tell(STDIN)=" . tell(STDIN) . ", eof(STDIN)=" . eof(STDIN);
    say STDERR "\@export_info = `perl $dir/pythonizer_importer.pl $fullfile`;" if($::debug >= 3);
    @export_info = `perl $dir/pythonizer_importer.pl $fullfile`;
    #say STDERR "after:  tell(STDIN)=" . tell(STDIN) . ", eof(STDIN)=" . eof(STDIN);
    say STDERR "handle_import($fullfile): got @export_info" if($::debug>=3);
    if ($export_info[-3] !~ /\@global_vars=qw/) {       # issue s4 - we added @overloads and @wantarrays
        logme('W', "Could not import $fullfile for $ValPerl[$pos] " . $ValPerl[$pos+1]);
        return;
    }
    chomp(my $pkg = $export_info[0]);
    chomp(my $vars = $export_info[-3]);         # issue s4 - we added @overloads and @wantarrays
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
=cut
}

=pod    # issue s4 - we don't need this any more that we default -R
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
    #return if(scalar(%UseRequireVars) == 0);    # Don't do anything if we have no vars to take care of
    return if(!keys %UseRequireVars);       # Don't do anything if we have no vars to take care of
    
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
=cut

my %regex_flag_map = (A=>'a', I=>'i', L=>'L', M=>'m', S=>'s', U=>'u', X=>'x');

sub build_in_qr_flags           # issue s3
# issue s3: for a qr not used directly in a regex, build the flags into the regex using (?flags:regex).  This is to allow
# the regex to be used later in a larger regex without losing the flags because we change /$regex/ to regex.pattern in
# the generated code.
# usage: ($regex, $modifier) = build_in_qr_flags($arg1, $modifier);
{
    my ($regex, $flags) = @_;

    return ($regex, $flags) unless $flags;

    my $x_flag = x_flag($flags);            # issue s80
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
    return ("(?$mapped_flags:$regex
)", '') if($x_flag);                    # issue s80
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

sub replace_escape_with_chr             # issue s28
# We can't use \ in f"{...}" so we must replace this escape character with the equivalent chr(...) call
# Return a 2-element list with the function and the updated string w/o the escape
{
    my $string = shift;
    my $in_regex = shift;

    my $ch2 = substr($string,1,1);
    if(exists($SPECIAL_ESCAPES{$ch2})) {
        $string = substr($string,2);
        return ($SPECIAL_ESCAPES{$ch2} . '+' . $SPECIAL_ESCAPES{$ch2}, $string) if($ch2 eq "\\" && $in_regex);
        return ($SPECIAL_ESCAPES{$ch2}, $string);
    } elsif($ch2 eq '-') {              # unescape_string doesn't handle \-
        $string = substr($string,2);
        return ('chr(45)', $string);
    } else {
        my $bs2 = index($string, "\\", 2);
        my $rest = '';
        if($bs2 != -1) {
            $rest = substr($string, $bs2);
            $string = substr($string,0,$bs2);
        }
        my $u = unescape_string($string, 1);    # pass "has_double_brackets"
        return ("chr(" . ord(substr($u,0,1)) . ")", substr($u,1) . $rest);
    }
}

sub semicolon_in_block          # issue s39
# Return 1 if there is a semicolon in a {...} block like in a map/grep function
{
    my $source = shift;

    my $end_br = matching_curly_br($source, 0);
    return 1 if($end_br < 0);                           # issue s78: assume any multi-line block needs to be pulled out
    $end_br = length($source) if $end_br < 0;
    return 1 if(index(substr($source,0,$end_br),';') > 0);
    return 0;
}

sub handle_while_magic_function                 # issue s40
# From the documentation: If the condition expression of a while statement is 
# based on any of a group of iterative expression types then it gets some magic 
# treatment. The affected iterative expression types are readline, the <FILEHANDLE>
# input operator, readdir, glob, the <PATTERN> globbing operator, and each. If the
# condition expression is one of these expression types, then the value yielded by
# the iterative operator will be implicitly assigned to $_. If the condition
# expression is one of these expression types or an explicit assignment of one of
# them to a scalar, then the condition actually tests for definedness of the
# expression's value, not for its regular truth value.                     
#
# Arg: position of the function.  Returns: New position of the function
{
     my $pos = shift;

     $TokenStr = join('', @ValClass);   # Required to use certain functions
     if(index($TokenStr,'=') < 0) {     # If we don't have an assignment, then assign the default variable
         insert(2,'=','=',':=');
         insert(2,'s','$_',$DEFAULT_VAR);
         $pos += 2;
         say STDERR "handle_while_magic_function: inserted $DEFAULT_VAR:=" if($::debug && $Pythonizer::PassNo != &Pythonizer::PASS_0);
     }
     my $match = &Pythonizer::matching_br(1);
     return $pos if $match < 0;
     if($ValClass[2] eq 'f' && $ValPerl[2] eq 'defined') {              # issue s92: Don't insert 'defined' if user already has that in there!
         return $pos;                                                   # issue s92
     }                                                                  # issue s92
     insert(2,'(','(','(');
     insert(2,'f','defined',$keyword_tr{defined});
     insert($match+2,')',')',')');
     $pos += 2;
     say STDERR "handle_while_magic_function: inserted 'defined' function" if($::debug && $Pythonizer::PassNo != &Pythonizer::PASS_0);
     return $pos;
}

sub looks_like_anon_hash_def            # issue test coverage: Handle {k=>'v'}
# Does this '{' look like an anonymous hash definition?
{
    my $source = shift;

    return 0 if(length($source) == 1);
    return 1 if($source =~ /\{\s*\}/);  # empty one
    return 1 if($source =~ /\{\s*\w+\s*=>/);
    return 1 if($source =~ /\{\s*'\w+'\s*=>/);
    return 1 if($source =~ /\{\s*q.\w+.\s*=>/);
    return 1 if($source =~ /\{\s*qq.\w+.\s*=>/);
    return 0;
}

sub template_var                    # issue s76: Is this perl name being currently used as a function template variable?
{
    return 0 if scalar(@nesting_stack) == 0;
    my $top = $nesting_stack[-1];
    return 0 if !exists $top->{function_template};
    my $perl_name = shift;
    return 1 if $perl_name eq $top->{function_template};
    return 0;
}

sub in_x_regex_comment              # issue s80
# For a regex with the 'x' flag, is the current position in the string part of a comment?
# Args: string - multi-line regex string to search
#       pos    - current position to check
# Result: 1 or 0
{
    my $string = $_[0];
    my $pos = $_[1];

    for(my $p = $pos-1; $p >= 0; $p--) {
        my $ch = substr($string, $p, 1);
        return 1 if($ch eq '#' && !is_escaped($string, $p));
        return 0 if($ch eq ']' && !is_escaped($string, $p));
        return 0 if($ch eq "\n" && !is_escaped($string, $p));
    }
    return 0;
}

sub x_flag                      # issue s80
# Return 1 if this regex modifier has an x flag, return 2 if it has 2 x flags
{
    my $modifier = $_[0];

    #say STDERR "x_flag($modifier)";
    return 2 if(index($modifier, 're.X|re.X') >= 0);
    return 1 if(index($modifier, 're.X') >= 0);
    return 0;
}

sub squash_double_x_flag_regex  # issue s80
# For a double x flag regex, squash out the extra spaces in ranges, because python can't support them like that
{
    my $regex = $_[0];
    my $result = '';
    my $in_brackets = 0;

    for(my $i = 0; $i < length($regex); $i++) {
        my $c = substr($regex, $i, 1);
        if($c eq '\\') {        # Handle escaped char
            my $nc = substr($regex, $i+1, 1);
            if($in_brackets && ($nc eq ' ' || $nc eq "\t")) {    # Remove escaped space/tabs in brackets
                $result .= $nc;
            } else {
                $result .= $c . $nc;
            }
            $i++;
            next;
        } elsif($in_brackets && ($c eq ' ' || $c eq "\t")) {
            next;           # Skip spaces and tabs in brackets
        } elsif(!$in_brackets && $c eq '[') {
            $in_brackets = 1;
        } elsif($in_brackets && $c eq ']') {
            $in_brackets = 0;
        }
        $result .= $c;
    }
    say STDERR "squash_double_x_flag_regex($regex) = $result" if($::debug);
    return $result;
}

sub preprocess_regex_x_flag_refs_in_comments        # issue s80
# For a regex with the x flag in pass 1, remove '$' and '@' references in comments - in PASS_1 just replace them with '?'
# in PASS_2 we replace them with special chars that we later remove in post processing
# so we don't match them with variables
{
    my $regex = $_[0];
    my $result = '';
    my $in_brackets = 0;
    my $in_comment = 0;
    my $pc = 0;

    for(my $i = 0; $i < length($regex); $i++) {
        my $c = substr($regex, $i, 1);
        if($c eq '\\') {        # Handle escaped char
            my $nc = substr($regex, $i+1, 1);
            if($nc eq '#' && $Pythonizer::PassNo==&Pythonizer::PASS_2) {
                say STDERR "preprocess_regex_x_flag_refs_in_comments - replacing \\#" if($::debug >= 5);
                $result .= chr(ord('#') + 0x80);
            } else {
                $result .= $c . $nc;
            }
            $i++;
            $pc = 0;
            next;
        } elsif(!$in_brackets && $c eq '#' && $pc ne '$') {  # start of comment (not $#...)
            $in_comment = 1;
        } elsif($in_comment && ($c eq '$' || $c eq '@')) {
            say STDERR "preprocess_regex_x_flag_refs_in_comments - replacing $c" if($::debug >= 5);
            if($Pythonizer::PassNo==&Pythonizer::PASS_1) {
                $c = '?';
            } else {
                $c = chr(ord($c) + 0x80);        # Encode the char so we can decode it later
            }
        } elsif($in_comment && $c eq "\n") {
            $in_comment = 0;
        } elsif(!$in_brackets && $c eq '[') {
            $in_brackets = 1;
        } elsif($in_brackets && $c eq ']') {
            $in_brackets = 0;
        }
        $result .= $c;
        $pc = $c;       # keep track of prior char
    }
    return $result;
}

sub postprocess_regex_x_flag_refs_in_comments        # issue s80
# For a regex with the x flag in pass 1, restore '$' and '@' references in comments
# in PASS_2 as we replaced them with special chars that we later remove here
{
    my $regex = $_[0];
    my $result = '';
    my $in_brackets = 0;
    my $in_comment = 0;
    my $pc = 0;

    for(my $i = 0; $i < length($regex); $i++) {
        my $c = substr($regex, $i, 1);
        if($c eq '\\') {        # Handle escaped char
            my $nc = substr($regex, $i+1, 1);
            $result .= $c . $nc;
            $i++;
            $pc = 0;
            next;
        } elsif(!$in_brackets && $c eq '#' && $pc ne '$') {  # start of comment (not $#...)
            $in_comment = 1;
        } elsif($in_comment && ($c eq chr(ord('$')+0x80) || $c eq chr(ord('@')+0x80))) {
            $c = chr(ord($c) - 0x80);        # Decode the char
            say STDERR "postprocess_regex_x_flag_refs_in_comments - restoring $c" if($::debug >= 5);
        } elsif($c eq chr(ord('#')+0x80)) {
            $result .= '\\';
            $c = '#';
            say STDERR "postprocess_regex_x_flag_refs_in_comments - restoring \\$c" if($::debug >= 5);
        } elsif($in_comment && $c eq "\n") {
            $in_comment = 0;
        } elsif(!$in_brackets && $c eq '[') {
            $in_brackets = 1;
        } elsif($in_brackets && $c eq ']') {
            $in_brackets = 0;
        }
        $result .= $c;
        $pc = $c;       # keep track of prior char
    }
    return $result;
}

sub fixup_case_subs             # issue s129
# Fixup case statement with implicit sub definitions by inserting an explicit "sub" like Switch.pm does
{
    my $source = shift;
    my $pos = shift;

    my $rest = substr($source, $cut);
    my $result;
    if(exists $UseSwitch{__} && $rest =~ /^\s*__/) {
        $rest =~ s/__([^{]*)\{/sub {\$_[0] $1}{/;
        $result = substr($source,0,$cut) . $rest;
        say STDERR "fixup_case_subs($source, $cut) = $result" if($::debug);
        return $result;
    }
    return $source unless($rest =~ /^\s*\{/);
    return $source if($rest =~ /^\s*\{\}/);     # case {} is not a sub
    return $source if($rest =~ /^\s*\{([^},]*),[^}]*\}/ && # case {1,1} is not a sub
                      $1 !~ /\b\w+\b/);                 # but case {scalar grep $x, @arr} IS a sub
    #if($rest =~ /(\s*\{[^}]+\})(\s*\{.*)$/) {
    #$result = substr($source,0,$cut) . ' (sub' . $1 . ')' . $2;
    #} else {
    #$result = substr($source,0,$cut) . ' sub ' . $rest;
    #}
    my ($p_open, $p_close);
    for($p_open=0; $p_open < length($rest); $p_open++) {
        last if(substr($rest, $p_open, 1) eq '{');
    }
    $p_close = matching_curly_br($rest, $p_open);
    $result = substr($source,0,$cut) . ' (sub' . substr($rest, 0, $p_close+1) . ')' . substr($rest, $p_close+1);
    say STDERR "fixup_case_subs($source, $cut) = $result" if($::debug);
    return $result;
}

sub fixup_switch_subs             # issue s129
# Fixup switch statement with references to __ to insert a 'sub'
{
    my $source = shift;
    my $pos = shift;

    my $rest = substr($source, $cut);
    my $result;
    if(exists $UseSwitch{__} && $rest =~ /^\s*\(\s*__/) {
        $rest =~ s/__([^{]*)\)/sub {\$_[0] $1})/;
        $result = substr($source,0,$cut) . $rest;
        say STDERR "fixup_switch_subs($source, $cut) = $result" if($::debug);
        return $result;
    }
    return $source;
}

sub in_when                     # issue s129
# Are we in a when/case?
{
    for $ndx (reverse 0 .. $#nesting_stack) {
        return 1 if $nesting_stack[$ndx]->{type} eq 'when';
    }
    return 0;
}

sub bracketed_function_end      # issue s134
# Is this the end of a bracketed function, like 'grep'?
{
    my $pos = shift;            # position of the end of the function brackets, before the array

    return 0 if($ValClass[$pos] ne ')');
    return 0 if($ValPerl[$pos] ne '}');
    my $sbr = &Pythonizer::reverse_matching_br($pos);
    return 0 if($sbr <= 0);
    return 0 if($ValClass[$sbr-1] ne 'f');
    return 1;
}

sub special_code_block_name     # issue s155
# Return 1 if this is the name of a special code block like for BEGIN, END, etc
{
      return 0 unless defined $_[0];
      return 1 if($_[0] =~ /^__(?:BEGIN|END|CHECK|INIT|UNITCHECK)__\d/);
      return 0;
}

sub ampersand_is_sub_sigil      # issue s152
# Return 1 iff this '&' looks like a sigil for a sub, else return 0 if this looks like a bitwise and
{
    return 1 if $tno == 0;
    if(index('i)"ds', $ValClass[$tno-1]) != -1) {      # issue s152: distinguish & from &Sub
        return 0 if $tno-2 < 0;
        return 1 if $ValClass[$tno-2] eq 'f' && $ValPy[$tno-2] eq 'print';          # print/say FH &Sub
        return 0;
    }
    return 1;
}

sub inRefOkFunction            # issue s169
# Return 1 if we are in a function call where references to scalars are ok, like in a GetOptions call
{
    for(my $i = 0; $i <= $#ValClass; $i++) {
        if($ValClass[$i] eq 'f') {
            if($ValPerl[$i] =~ /^(?:GetOptions|ref|isa|UNIVERSAL'isa|UNIVERSAL::isa|Dumper)$/) {
                return 1;
            }
        }
    }
    return 0;
}

sub nonScalarRef            # issue s173
# is this a non-scalar reference, e.g. to an arrayref or hashref which is later referred to via @$var or %$var?
{
    my $sub = cur_sub();
    my $typ = 's';
    $typ = $Pythonizer::VarType{$ValPy[$tno]}{$sub} if(exists $Pythonizer::VarType{$ValPy[$tno]}{$sub});
    return 0 if(substr($source,$cut) =~ /\s*->/);   # Reference to an array element or hash key - assume it's a scalar
    return 1 if $typ =~ /^[ah]/;        # This type is set in pass 1 on the @$var or %$var reference
    return 0;
}

sub inRefOkSub              # issue s185
# Return 1 if we are in a sub call which has reference out parameters, and this is one of them
{
    my $pos = shift;

    for(my $i = 0; $i <= $#ValClass; $i++) {
        if($ValClass[$i] eq 'i' && ($Pythonizer::LocalSub{$ValPy[$i]} || ($i != 0 && $ValClass[$i-1] eq 'D'))) {
           my $prefix = '';
           my $delta = 0;
           if($i != 0 && $ValClass[$i-1] eq 'D') {        # Method call
              $prefix = '->'; 
              $delta = 1;      # one implicit arg
           }
           # issue s241 if(exists $Pythonizer::SubAttributes{$prefix . $ValPy[$i]} && exists $Pythonizer::SubAttributes{$prefix . $ValPy[$i]}{out_parameters}) {
           # issue s241 return 1 if $Pythonizer::SubAttributes{$prefix . $ValPy[$i]}{out_parameters}->[0] eq 'var';
           if(defined &Pythonizer::get_sub_attribute_at($i, 'out_parameters')) {    # issue s241
               return 1 if &Pythonizer::get_sub_attribute_at($i, 'out_parameters')->[0] eq 'var';
               for(my $arg = 0; ;$arg++) {
                   my ($s, $e) = &::get_arg_start_end($i, $ValClass[$i+1] eq '(' ? $#ValClass+1 : $#ValClass, $arg+1);  # Adjust end_pos as we may not have finished parsing this line
                   last unless defined $s;
                   next unless $pos >= $s && $pos <= $e;
                   # issue s241 return 1 if grep {$_ eq (($arg+$delta).'r')} @{$Pythonizer::SubAttributes{$prefix . $ValPy[$i]}{out_parameters}};
                   return 1 if grep {$_ eq (($arg+$delta).'r')} @{&Pythonizer::get_sub_attribute_at($i, 'out_parameters')}; # issue s241
               }
           }
       }
   }
   return 0;
}

sub handle_pP_unicode               # issue s240
{
    my $regex = shift;

    # This is just a subset of the Unicode specification
    my %p_map = (
    L => 'a-zA-Z',  # Letter
    N => '0-9',  # Number
    P => '!"\#%&\x27()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$',         # Punctuation
    S => '\$+<=>\^`\|~\xa2-\xa6\xa8-\xa9\xac\xae-\xb1\xb4\xb8\xd7\xf7',    # Symbol
    Z => ' \t\r\n\x0b\f',    # Space
    C => '\x00-\x1f\x7f',    # Control

    '{AHex}' => "a-fA-F0-9",
    '{All}' => ".",
    '{Alnum}' => "a-zA-Z0-9",
    '{Alpha}' => "a-zA-Z",
    '{Any}' => ".",
    '{ASCII}' => '\x00-\x7f',
    '{ASCII_Hex_Digit}' => "a-fA-F0-9",
    '{Blank}' => ' \t\xa0',    # Blank
    '{C}' => '\x00-\x1f\x7f',    # Control
    '{Cc}' => '\x00-\x1f\x7f',    # Control
    '{Cc}' => '\x00-\x1f\x7f',    # Control
    '{Cntrl}' => '\x00-\x1f\x7f',    # Control
    '{Control}' => '\x00-\x1f\x7f',    # Control
    '{Decimal_Number}' => "0-9",  # Number
    '{Digit}' => "0-9",  # Number
    '{Graph:}' => '\x21-\x7e',
    '{Hex}' => "a-fA-F0-9",
    '{Hex_Digit}' => "a-fA-F0-9",
    '{HorizSpace}' => ' \t\xa0',    # Blank
    '{L}' => "a-zA-Z",  # Letter
    '{Letter}' => "a-zA-Z",  # Letter
    '{Ll}' => "a-z",  # Lowercase Letter
    '{Lower}' => "a-z",  # Lowercase Letter
    '{Lowercase}' => "a-z",  # Lowercase Letter
    '{Lowercase_Letter}' => "a-z",  # Lowercase Letter
    '{Lu}' => "A-Z",  # Uppercase Letter
    '{N}' => "0-9",  # Number
    '{Number}' => "0-9",  # Number
    '{P}' => '!"\#%&\x27()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$',         # Punctuation
    '{PerlSpace}' => '\s',
    '{PerlWord}' => '\w',
    '{PosixAlnum}' => "a-zA-Z0-9",
    '{PosixAlpha}' => "a-zA-Z",
    '{PosixBlank}' => ' \t',
    '{PosixCntrl}' => '\x00-\x1f\x7f',
    '{PosixDigit}' => "0-9",
    '{PosixGraph}' => '\x21-\x7e',
    '{PosixLower}' => "a-z",
    '{PosixPrint}' => '\x20-\x7e',
    '{PosixPunct}' => '!"\#%&\x27()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$',         # Punctuation
    '{PosixSpace}' => ' \t\r\n\x0b\f',
    '{PosixUpper}' => "A-Z",
    '{PosixWord}' => "A-Za-z0-9_",
    '{PosixXDigit}' => "0-9A-Fa-f",
    '{Print}' => '\x20-\x7e',
    '{Punct}' => '!"\#%&\x27()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$',         # Punctuation
    '{Punctuation}' => '!"\#%&\x27()*+,\-.\/:;<=>?\@\[\\\\\]^_\x91{|}~\$',         # Punctuation
    '{S}' => '\$+<=>\^`\|~\xa2-\xa6\xa8-\xa9\xac\xae-\xb1\xb4\xb8\xd7\xf7',    # Symbol
    '{Space}' => '\s',
    '{Symbol}' => '\$+<=>\^`\|~\xa2-\xa6\xa8-\xa9\xac\xae-\xb1\xb4\xb8\xd7\xf7',    # Symbol
    '{Unicode}' => ".",
    '{Upper}' => "A-Z",  # Uppercase Letter
    '{Uppercase}' => "A-Z",  # Uppercase Letter
    '{Uppercase_Letter}' => "A-Z",  # Uppercase Letter
    '{White_Space}' => '\s',
    '{Word}' => '\w',
    '{WSpace}' => '\s',
    '{XDigit}' => "a-fA-F0-9",
    '{XPerlSpace}' => '\s',
    '{XPosixBlank}' => ' \t\xa0',
    '{XPosixCntrl}' => '\x00-\x1f\x7f',    # Control
    '{XPosixSpace}' => '\s',
    );

    my @result = ();
    my $in_class = 0;
    my $c;
    for(my $i = 0; $i < length($regex); $i++, push @result, $c) {
        $c = substr($regex, $i, 1);
        if($c eq '\\') {
            my $c2 = substr($regex, $i+1, 1);
            if($c2 eq 'p' || $c2 eq 'P') {
                next if $c2 eq 'P' && $in_class && substr($regex, $i-1, 1) ne '[';  # We only handle \P at start of class or not in class
                my $c3 = substr($regex, $i+2, 1);
                my $repl;
                if($c3 eq '{') {
                    my $ndx = index($regex, '}', $i+3);
                    next if $ndx < 0;
                    my $uni = substr($regex, $i+2, $ndx+1-($i+2));
                    next if !exists $p_map{$uni};
                    $repl = $p_map{$uni};
                    $i = $ndx;
                } else {
                    next if !exists $p_map{$c3};
                    $repl = $p_map{$c3};
                    $i += 2;
                }
                push @result, '[' unless $in_class;
                push @result, '^' if $c2 eq 'P';    # Complement
                push @result, $repl;
                push @result, ']' unless $in_class;
                $c = '';
                next;
            }
            $c .= $c2;
            $i++;
        } elsif($c eq '[') {
            $in_class = 1;
        } elsif($c eq ']') {
            $in_class = 0;
        }
    }
    $result = join('', @result);
    say STDERR "handle_pP_unicode($regex) = $result" if $::debug;
    return $result;
}

sub handle_block_scope_pragma       # use integer, use English
{
    my ($cur_value, $name, $setter, $new_value) = @_;

    say STDERR "handle_block_scope_pragma($cur_value, $name, setter, $new_value)" if $::debug;
    &$setter($new_value);
    return if(!@nesting_stack);
    $top = $nesting_stack[-1];
    $BlockScopePragmas{$name} = 1;
    $top->{$name} = $cur_value;
    $top->{$name.'setter'} = $setter;
}

sub undo_block_scope_pragmas        # use integer, use English
{
    return if(!@nesting_stack);
    $top = $nesting_stack[-1];
    for my $pragma (keys %BlockScopePragmas) {
        next if !exists($top->{$pragma});
        my $old_value = $top->{$pragma};
        my $setter = $top->{$pragma.'setter'};
        say STDERR "undo_block_scope_pragmas: calling ${pragma}setter($old_value)" if $::debug;
        &$setter($old_value);
    }
}

sub handle_use_english          # use English
{
    my $source = $_[0];
    my $hashref = $_[1];

    my $cut_adjust = 0;

    if($source =~ /^.(\w+)/) {
        my $len = length($1);
        if(exists $hashref->{$1}) {
            my $replacement = $hashref->{$1};
            say STDERR "handle_use_english($source): found $1, replacing with $replacement" if($::debug >= 5);
            substr($source,1, $len) = $replacement;
            $cut_adjust = $len - length($replacement);
        }
    }
    say STDERR "handle_use_english: new source: $source, cut_adjust: $cut_adjust" if($::debug >= 5);
    return wantarray ? ($source, $cut_adjust) : $source;
}

1;

