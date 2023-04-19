package Pythonizer;
#
## ABSTRACT:  Supplementary subroutines for pythonizer
## Includes logging subroutine: logme,  abend, out, getopts  and helpme
## Copyright Nikolai Bezroukov, 2019-2020.
## Licensed under Perl Artistic license
# Ver      Date        Who        Modification
# =====  ==========  ========  ==============================================================
# 00.00  2019/10/10  BEZROUN   Initial implementation. Limited by the rule "one statement-one line"
# 00.10  2019/11/19  BEZROUN   The prototype is able to process the minimal test (with  multiple errors) but still
# 00.11  2019/11/19  BEZROUN   autocommit now allow to save multiple modules in addition to the main program
# 00.12  2019/12/27  BEZROUN   Notions of ValType was introduced in preparation of introduction of pre_processor.pl version 0.2
# 00.20  2020/02/03  BEZROUN   getline was moved from pythonyzer.
# 00.30  2020/08/05  BEZROUN   preprocess_line was folded into getline.
# 00.40  2020/08/17  BEZROUN   getops is now implemented in Softpano.pm to allow the repretion of option letter to set the value of options ( -ddd)
# 00.50  2020/08/24  BEZROUN   Option -p added
# 00.60  2020/08/25  BEZROUN   __DATA__ and __END__ processing added
# 00.61  2020/08/25  BEZROUN   POD processing  added Option - r (refactor) added
# 00.70  2020/09/03  BEZROUN   Stack manipulation defined more completly and moved from main script to Pythonizer.om
# 00.80  2020/09/17  BEZROUN   Basic global varibles detection added. Global statement now is generated for each subroutine
# 00.90  2020/10/12  BEZROUN   Option -l added. Output format improved. Many small fixes

use v5.10.1;
use warnings;
use strict 'subs';
use feature 'state';
use Perlscan qw(tokenize $TokenStr @ValClass @ValPerl @ValPy @ValType %token_precedence %SPECIAL_FUNCTION_MAPPINGS destroy insert append replace %FuncType %PyFuncType %UseRequireVars %UseRequireOptionsPassed %UseRequireOptionsDesired special_code_block_name);  # SNOOPYJC
use Softpano qw(abend logme out getopts standard_options);
use Pyconfig;				# issue 32
use Pass0 qw(pass_0);   # SNOOPYJC
use Data::Dumper;       # SNOOPYJC
# issue s70 use open ':std', IN=>':crlf', IO=>':utf8';        # SNOOPYJC
use open ':std', IN=>':crlf';        # issue s70
use File::Path qw(make_path);           # issue s23
use File::Basename;                     # issue s23
use File::Spec::Functions qw(catfile);  # issue s23
require Exporter;
use Storable qw(dclone);                # issue s18
use FixLatin qw(fix_latin);             # issue s70
use Encode qw/decode find_encoding/;    # issue s70

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw(preprocess_line correct_nest getline prolog output_line %LocalSub %PotentialSub %UseSub %GlobalVar %InitVar %VarType init_val matching_br reverse_matching_br next_matching_token last_matching_token next_matching_tokens next_same_level_token next_same_level_tokens next_lower_or_equal_precedent_token fix_scalar_context %SubAttributes %Packages @Packages %PackageDef arg_type_from_pos in_sub_call end_of_function new_anonymous_sub save_nest restore_nest for_loop_uses_default_var get_sub_attribute get_sub_attribute_at set_sub_attribute clone_sub_attributes debug_start_end); # SNOOPYJC
our  ($IntactLine, $output_file, $NextNest,$CurNest, $line, $fname, @orig_ARGV);
   our ($f_encoding, $f_encodobj, $f_decodobj, $e_option);  # issue s70
   $IntactLno = 0;           # issue s6
   $IntactEndLno = 0;        # issue s6
   $TraceIntactLine = 0;     # issue s6
   # issue 32 $::TabSize=3;
   $::TabSize=$TABSIZE;         # issue 32
   $::breakpoint=0;
   $breakpoint=99999;               # SNOOPYJC: for -B (first pass breakpoint)
   $NextNest=$CurNest=0;
   # issue 32 $MAXNESTING=9;
   $VERSION = '0.80';
   $refactor=0;  # option -r flag (invocation of pre-pythonizer)
   sub PASS_0 { 0 }     # SNOOPYJC: Pre-pass to determine -m or -M
   sub PASS_1 { 1 }     # SNOOPYJC: The first pass: determining global/local/my vars and variable types
   sub PASS_2 { 2 }     # SNOOPYJC: The second pass: Code generation
   $PassNo=PASS_1;           # SNOOPYJC: EXTERNAL VAR: Current pass
   $InLineNo=0; # counter, pointing to the current like in InputTextA during the first pass
   %LocalSub=(); # list of local subs
   %UseSub=();          # SNOOPYJC: list of subs declared on "use subs", issue s3: also imported subs are added here
   %UsePackage=();      # issue s209: list of all packages mentioned in use XXX::YYY with their line numbers
   %RequirePackage=();  # issue s18: list of all packages mentioned in require XXX::YYY with their line numbers
   %PotentialSub=();    # SNOOPYJC: List of potential sub calls
   %GlobalVar=(); # generated "external" declaration with the list of global variables.
   %InitVar=(); # SNOOPYJC: generated initialization
   %SubAttributes=();   # SNOOPYJC: Map of sub to set of attributes.  Current ones: modifies_arglist, blesses, overloads
   # issue 32 $maxlinelen=188;
   $maxlinelen=$MAXLINELEN;
   $GeneratedCode=0;    # issue 96: used to see if we generated any real code between { and }
   %Packages = ();      # SNOOPYJC: Set of all python names of packages defined in this file (determined on the first pass)
   %PackageDef = ();    # issue s18: Set of all python names of packages defined in this file (determined on the first pass) with the line they are defined on
   @Packages = ();      # SNOOPYJC: List of all python names of packages defined in this file in the order declared
   $CurPackage = undef; # SNOOPYJC
   $mFlag = 0;          # SNOOPYJC
   $MFlag = 0;          # SNOOPYJC
   %anonymous_subs_used = ();   # issue s26
   $pass_0_ran = 0;     # issue s63: set to 1 if we ran pass_0
   $deferred_nesting_top = undef;       # issue s252
   $StartingBeginLno = undef;           # issue s325

#
#::prolog --  Decode parameter for the pythonizer. all parameters are exported
#
sub prolog
{
      my $dir = shift;				# issue 55
      my $log_dir = shift;                      # issue 64
      my $script_name = shift;                  # issue 64
      my $banner_msg = shift;                   # issue 64
      my $log_retention = shift;                # issue 64
      # SNOOPYJC getopts("AThd:v:r:b:t:l:",\%options);
      @orig_ARGV = @ARGV;                       # SNOOPYJC
      # NOTE: Remember to add new flags to Pass0.PM (# pragma pythonizer), the help with ## at the start of pythonizer, and the readme/documentation!
      getopts("fFNyYauUkKnmMAVThsSpPd:v:r:b:B:t:l:R:o:e:",\%options);     # SNOOPYJC, issue s23, issue s19, issue s87, issue s132, issue s70, issue s284
#
# Three standard options -h, -v and -d
#
      standard_options(\%options);
      Softpano::banner($log_dir, $script_name, $banner_msg, $log_retention);      # issue 64
#
# Custom options specific for the application
#
      if(   exists $options{'r'}  ){
         if(  $options{'r'} eq ''){
	    # issue 55 $refactor='./pre_pythonizer.pl';
            $refactor="$dir/pre_pythonizer.pl";		# issue 55
         }else{
            if(   -f $options{'r'} ){
              $refactor=$options{'r'};
            }else{
               logme('S',"The Script  $options{'r'} does not exist (may be you need to specify path to the file)\n");
               exit 255;
            }
         }
         unless (-x $refactor ){
             logme('S',"File $options{'r'} specifed in option -r is not executable\n");
             exit 255;
         }
      }

      if(   exists $options{'b'}  ){
        unless ($options{'b'}){
          logme('S',"Option -b should have a numeric value. There is no default.");
          exit 255;
        }
        if(  $options{'b'}>0  && $options{'b'}<9000 ){
           $::breakpoint=$options{'b'};
           ($::debug) && logme('W',"Breakpoint set to line  $::breakpoint");
        }else{
           logme('S',"Wrong value of option -b ( breakpoint): $options('b')\n");
           exit 255;
        }
      }
      if(   exists $options{'B'}  ){            # SNOOPYJC
        unless ($options{'B'}){
          logme('S',"Option -B should have a numeric value. There is no default.");
          exit 255;
        }
        if(  $options{'B'}>0  && $options{'B'}<9000 ){
           $breakpoint=$options{'B'};
           ($::debug) && logme('W',"Breakpoint set to line  $breakpoint");
        }else{
           logme('S',"Wrong value of option -B ( breakpoint): $options('B')\n");
           exit 255;
        }
      }
      if(   exists $options{'t'}  ){
         $options{'t'}=1 if $options{'t'} eq '';
         if(  $options{'t'}>1  && $options{'t'}<=10 ){
            $::TabSize=$options{'t'};
         }else{
            logme('S',"Range for options -t (tab size) is 2-10. You specified: $options('t')\n");
            exit 255;
         }
      }
      if( exists $options{'w'} ){
         if($options{'w'}>=100 && $options{'w'}<=256  ){
            $maxlinelen=$options{'w'};
            if( $maxlinelen//2==1 ){
               $maxlinelen-=1;
            }
         }else{
            logme('W',"Incorrect value for length of the line in protocol of tranlation: $options{'w'}\n Minimum  is 100. Max is 256. Default value 188 is assumed \n");
         }
      }
      # SNOOPYJC - add more options

      if( exists $options{'R'} ) {
         if($options{R} eq ':all') {
             $::remap_all = 1;
         } elsif($options{R} eq ':global') {
             $::remap_global = 1;
         } elsif($options{R} eq ':none') {
             $::remap_global = 0;
             $::remap_all = 0;
         } else {
             my @remaps = split /,/, $options{R};
             %::remap_requests = map { $_ => 1 } @remaps;
             $::remap_global = 0;
             $::remap_all = 0;
         }
      }
	
      if( exists $options{'l'} ){
         if($options{'l'}>=48 && $options{'l'}<=1000  ){
            $::black_line_length=int($options{'l'});
         }else{
            logme('W',"Incorrect value for length of the line generated by the black formatter $options{'l'}\n Minimum  is 48. Max is 1000. Default value $::black_line_length is assumed \n");
         }
      }

      if( exists $options{'T'} ) {
          $::traceback = 1;
      }
      if( exists $options{'n'} ) {
          $::trace_run = 1;
      }
      if( exists $options{'A'} ) {
          $::autodie = 1;
      }
      if( exists $options{'m'} ) {
          $mFlag = 1;
          $::implicit_global_my = 1;
      }
      if( exists $options{'M'} ) {
          $MFlag = 1;
      }
      if( exists $options{'s'} ) {
          $::pythonize_standard_library = 1;
      }
      if( exists $options{'S'} ) {
          $::pythonize_standard_library = 0;
      }
      if( exists $options{'p'} ) {
          $::import_perllib = 1;
      }
      if( exists $options{'P'} ) {
          $::import_perllib = 0;
      }
      if( exists $options{'V'} ) {      # issue s132
          print ucfirst($::SCRIPT_NAME) . " $::VERSION\n";
          exit(0);
      }
      if( exists $options{'N'} ) {
          $::autovivification = 0;
      }
      if( exists $options{'k'} ) {
          $::black = 1;
      }
      if( exists $options{'K'} ) {
          $::black = 0;
      }
      if( exists $options{'u'} ) {
          $::replace_usage = 1;
      }
      if( exists $options{'U'} ) {
          $::replace_usage = 0;
      }
      if( exists $options{'o'} ) {              # issue s23
          $::output_dir = $options{'o'};        # issue s23
      }                                         # issue s23
      if( exists $options{'a'} ) {              # issue s19
          $::gen_author = 1;                    # issue s19
      }                                         # issue s19
      if( exists $options{'y'} ) {		# issue s87
          $::replace_run = 1;
      }
      if( exists $options{'Y'} ) {		# issue s87
          $::replace_run = 0;
      }
      if( exists $options{'e'} ) {              # issue s70
          $e_option = $options{'e'};            # issue s70
      }                                         # issue s70
      if( exists $options{'f'} ) {		# issue s284
          $::fully_qualify_calls = 1;
      }
      if( exists $options{'F'} ) {		# issue s274
          $::fully_qualify_calls = 0;
      }
#
# Application arguments
#
      if(  scalar(@ARGV)==1 ){
         $fname=$ARGV[0];
         unless( -f $fname ){
            abend("Input file $fname does not exist");
         }
         # issue s245 $source_file=substr($ARGV[0],0,rindex($ARGV[0],'.'));
         my $p = rindex($ARGV[0], '.');                                # issue s245
         $source_file = ($p < 0 ? $ARGV[0] : substr($ARGV[0],0,$p));   # issue s245
         if(defined $::output_dir) {            # issue s23
             make_path($::output_dir);          # issue s23
             $source_file = catfile($::output_dir, basename($source_file));     # issue s23 - also used for the .data file
         }                                      # issue s23
         $output_file=$source_file.'.py';
         out("Results of transcription are written to the file  $output_file");
         if(  $refactor ){
             unless( -f "$fname.bak" ){
                `cp -p "$fname" "$fname.bak" && tr -d "\r" < "$fname.bak" > "$fname"`; # just in case
             }
             out("Option -r (refactor) was specified. file refactored using $refactor as the first pass over the source code");
            `pre_pythonizer -v 0 $fname`;
         }
         #$fsize=-s $fname;
         #if ($fsize<10){
         #abend("The size of the file is $fsize. Nothing to do. Exiting");
         #}
         unless( -r $fname ){
            abend("File does not have read permissions for the user");
         }
         # issue stdin open (STDIN, '<',$fname) || die("Can't open $fname for reading $!");
         open (SYSIN, '<',$fname) || die("Can't open $fname for reading $!");   # issue stdin
         $. = 0;
      }else{
          abend("Input file should be supplied as the first argument");
      }
      if( $debug){
          print STDERR "ATTENTION!!! Working in debugging mode debug=$debug\n";
      }
      shift @ARGV;              # SNOOPYJC: Don't read from both the file and STDIN if we hit the end
      $PassNo=PASS_0;
      $pass_0_ran = 0;          # issue s63
      if(!$mFlag && !$MFlag) {
          my $pass_0_result;
          if($fname =~ /\.pm$/) {
              $pass_0_result = 0;       # use -M for perl modules
          } else {
              &Perlscan::initialize();
              $pass_0_result = pass_0();
              correct_nest(0,0);
              $pass_0_ran = 1;  # issue s63
          }
          if(defined $pass_0_result) {
              if($pass_0_result) {      # -m
                  $::implicit_global_my = 1;
              }
          }
          # issue stdin close STDIN;
          # issue stdin open (STDIN, '<',$fname) || die("Can't open $fname for reading");
          open (SYSIN, '<',$fname) || die("Can't open $fname for reading");     # issue stdin
          $. = 0;
      }
      $PassNo=PASS_1;
      if($::implicit_global_my == 0) {
          $MAIN_MODULE = $DEFAULT_PACKAGE;
      }
      if($::import_perllib) {
          &Perlscan::init_perllib();
      }
      out("=" x 121,"\n");
      out("  LNO|NST|ERR|Python code...                                                                          Perl original...");
      &Perlscan::initialize();
      get_globals();
      # issue stdin close STDIN;
      # issue stdin open (STDIN, '<',$fname) || die("Can't open $fname for reading");
      open (SYSIN, '<',$fname) || die("Can't open $fname for reading"); # issue stdin
      $. = 0;
      $PassNo=PASS_2;
      $IntactLno = $IntactEndLno = 0;   # issue s6
      $IntactLine = '';                 # issue s6
      open(SYSOUT,'>',$output_file) || die("Can't open $output_file for writing");
      if(!defined $::fully_qualify_calls) {     # issue s284
          if($::implicit_global_my) {           # issue s284
              $::fully_qualify_calls = 0;       # issue s284
          } else {                              # issue s284
              $::fully_qualify_calls = 1;       # issue s284
          }                                     # issue s284
      }
      return;
} # prolog

%VarType = ('sys.argv'=>{__main__=>'a of m'},   # issue 41, issue s359: with bad index it could be None
            'sys.argv[1:]'=>{__main__=>'a of m'},       # issue s359: this is @ARGV
            'os.name'=>{__main__=>'S'},
            EVAL_ERROR=>{__main__=>'S'},
	    "${PERL_SORT_}a"=>{__main__=>'s'},
	    "${PERL_SORT_}b"=>{__main__=>'s'},
            # issue s90 'os.environ'=>{__main__=>'h of s'}); # SNOOPYJC: {varname}{sub} = type (a, h, s, I, S, F, N, u, m)
            'os.environ'=>{__main__=>'h of m'}); # SNOOPYJC: {varname}{sub} = type (a, h, s, I, S, F, N, u, m), issue s90: with a bad key, it could be None
%NeedsInitializing = ();        # SNOOPYJC: {sub}{varname} = type
# SNOOPYJC: initialized means it is set before it's being used
%initialized = (__main__=>{'sys.argv'=>'a of m',    # issue s359: bad index, it could be None
                       'sys.argv[1:]'=>'a of m',    # issue s359
                       'os.name'=>'S',
                       EVAL_ERROR=>'S',
		       '__dict__'=>'h',
                       # issue s90 'os.environ'=>'h of s'});       # {sub}{varname} = type
                       'os.environ'=>'h of m'});       # {sub}{varname} = type, issue s90: with a bad key, it could be None


%VarSubMap=(); # issue 108: matrix  var/sub that allows to create list of global for each sub

sub get_globals
#
# This suroutine creates two hashes
#   1. hash $GlobalVar with declations of global variables used in particula surtutine
#   2. %LocalSub;  -- list of subs in the program
#
{
#
# Arrays and hashes for varible analyses
#
my ( $varname, $subname, $CurSubName,$i,$k,$var_usage_in_subs);

my %DeclaredVarH=(); # list of my varibles in the current subroute
# issue 108 my %VarSubMap=(); # matrix  var/sub that allows to create list of global for each sub
   $CurSubName='__main__';
   $LocalSub{'__main__'}=1;
   $VarSubMap{"${PERL_SORT_}a"}{$CurSubName}='+';	# SNOOPYJC
   $VarSubMap{"${PERL_SORT_}b"}{$CurSubName}='+';	# SNOOPYJC
   foreach my $g (keys %GLOBALS) {             # SNOOPYJC
      $VarSubMap{$g}{$CurSubName}='+';         # SNOOPYJC
   }                                           # SNOOPYJC
   for my $g (keys %GLOBAL_TYPES) {            # SNOOPYJC
      my $t = $GLOBAL_TYPES{$g};
      $initialized{__main__}{$g} = $t;
      $VarType{$g}{__main__} = $t;
      if($::import_perllib) {
         $initialized{__main__}{$PERLLIB.'.'.$g} = $t;
         $VarType{$PERLLIB.'.'.$g}{__main__} = $t;
      }
   }
   my $PriorExprType = undef;                  # SNOOPYJC: used to type the function result
   my $got_first_line = 0;                      # issue s63
   while(1){
      if( scalar(@Perlscan::BufferValClass)==0 ){
         $line=getline(); # get the first meaningful line, skipping commenets and  POD
         if(!defined $line && $::saved_eval_tokens) {   # issue 42: done scanning the eval string
             $::saved_eval_tokens = undef;
             $. = $::saved_eval_lno;
             for my $t (@::saved_eval_buffer) {
                 getline($t);
             }
             @::saved_eval_buffer = ();       # issue s240
             next;
         }
         last unless(defined($line));
         if( $::debug==2 && $.== $::breakpoint ){
            say STDERR "\n\n === Line $. Perl source: $line ===\n";
            $DB::single = 1;
         }
         say STDERR "\n === Pass1: Line_$. Perl source:".$line."===" if($::debug);
         if( $.>=$breakpoint ){
            logme('S', "First pass breakpoint was triggered at line $. in Pythonizer.pm");
            $DB::single = 1;
         }
         # issue s311 if(defined $::saved_sub_tokens && $::nested_sub_at_level < 0) {  # SNOOPYJC
         if(defined $::saved_sub_tokens && $::nested_sub_at_level <= $::saved_sub_tokens_level[-1]) {  # SNOOPYJC, issue s311
             &::unpackage_tokens($::saved_sub_tokens);
             # issue s311 $::saved_sub_tokens = undef;
             $::saved_sub_tokens = pop @::saved_sub_tokens_stack;           # issue s311
             pop @::saved_sub_tokens_level;                                 # issue s311
             if($ValClass[0] eq 'c' && $ValPerl[0] eq 'aliased_foreach') {  # issue s252
                 getline($line);                # issue s252
             } else {                           # issue s252
                say STDERR "Continuing to scan tokens after handling sub with line=$line" if($::debug >= 3);
                &Perlscan::tokenize($line, 1);     # continue where we left off
             }
         } else {
            Perlscan::tokenize($line);
         }
      }else{
         #process token buffer -- Oct 9, 2020 --NNB
         @ValClass=@Perlscan::BufferValClass;
         $TokenStr=join('',@ValClass);
         @ValPerl=@Perlscan::BufferValPerl;
         @ValPy=@Perlscan::BufferValPy;

      }
      unless(defined($ValClass[0])){
         next;
      }
      my $pragma_pythonizer_line = 0;       # issue s325
      if((!$pass_0_ran) && $#ValClass >= 3 && $ValClass[0] eq 'i' && $ValPerl[0] eq 'pragma' && $ValPerl[1] eq 'pythonizer') {  # issue s63
          if($got_first_line == 0 || ($ValPerl[2] eq 'no' && $ValPerl[3] eq 'convert')) {       # issue s64
             my $uim = &Pass0::handle_pragma_pythonizer();
             $::implicit_global_my = $uim if(defined $uim);
             $pragma_pythonizer_line = 1;       # issue s325
          } else {
             logme('W',"# pragma pythonizer is only supported at start of source file if -m or -M are passed")
          }
      }
      if($got_first_line == 0 && $ValClass[0] eq 'k' && 
         $#ValClass == 1 && $ValClass[1] eq 'i' && $ValPerl[1] =~ /^__BEGIN__/) {       # issue s325
          $StartingBeginLno = $.;                                                       # issue s325
          say STDERR "StartingBeginLno = $." if $::debug;                               # issue s325
      }                                                                                 # issue s325

      if(!defined $CurPackage && ($ValClass[0] ne 'c' || $ValPerl[0] ne 'package')) {     # SNOOPYJC: Set the default package unless
                                                                			  # we start the file with a "package" stmt
         if(!$implicit_global_my) {
            push @Packages, $DEFAULT_PACKAGE unless(exists $Packages{$DEFAULT_PACKAGE});
            $Packages{$DEFAULT_PACKAGE} = 1;
            $CurPackage = $DEFAULT_PACKAGE;
         }
      }

      fix_scalar_context();                             # issue 37
      if( $ValClass[0] eq 't' && ($ValPerl[0] eq 'my' || $ValPerl[0] eq 'state') ){     # issue s306: Treat 'state' like 'my' in a sub
         for($i=1; $i<=$#ValClass; $i++ ){
            last if( $ValClass[$i] eq '=' );
            if( $ValClass[$i] =~/[sah]/ ){
               check_ref($CurSubName, $i);              # SNOOPYJC
               # issue s155 $DeclaredVarH{$ValPy[$i]}=1; # this hash is need only for particular sub
               $DeclaredVarH{$ValPy[$i]}=1 # this hash is need only for particular sub
                  unless($CurSubName eq '__main__' || special_code_block_name($CurSubName));     # issue s155: 'my' is like 'myfile' in BEGIN, etc subs, issue s306
            }
         }
         my $possible_parameter = 0;                  # issue s185
         if( $i<$#ValClass ){
            for( $k=$i+1; $k<@ValClass; $k++ ){
               if( $ValClass[$k]=~/[sah]/ ){
                  $possible_parameter = 1 if $ValPerl[$k] eq '@_';   # issue s185
                  $possible_parameter = 1 if $ValPerl[$k] eq '$_' && $ValPy[$k] =~ /\[\d+\]$/;  # issue s185
                  check_ref($CurSubName, $k);           # SNOOPYJC
                  next if exists($DeclaredVarH{$ValPy[$k]});
                  next if( defined($ValType[$k]) && $ValType[$k] eq 'X' && !exists($GLOBALS{$ValPy[$k]}));      # SNOOPYJC
                  $VarSubMap{$ValPy[$k]}{$CurSubName}='+';
               } elsif($ValClass[$k] eq 'f' && ($ValPerl[$k] eq 'shift' || $ValPerl[$k] eq 'pop') &&        # SNOOPYJC
                      ($k == $#ValClass || $ValPerl[$k+1] eq '@_' || $ValClass[$k+1] !~ /[ahfi]/)) {        # SNOOPYJC
                  # issue s84 $SubAttributes{$CurSubName}{modifies_arglist} = 1;                  # SNOOPYJC: This sub shifts it's args
                  my $cs = &Perlscan::cur_sub();                # issue s184
                  # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1;                  # SNOOPYJC: This sub shifts it's args, issue s84
                  set_sub_attribute($cs, 'modifies_arglist', 1);                  # SNOOPYJC: This sub shifts it's args, issue s84
                  if($ValPerl[$k] eq 'shift') {                      # issue s184
                      # issue s241 $SubAttributes{$cs}{arglist_shifts}++;          # issue s184
                     set_sub_attribute($cs, 'arglist_shifts', get_sub_attribute($cs, 'arglist_shifts',0,0) + 1);   # issue s184, issue s241
                  }                                                  # issue s184
                  $possible_parameter = 1;                           # issue s185
               }
            } # for
	        if($possible_parameter && $we_are_in_sub_body) {         # issue s185
                track_potential_sub_parameter_copies();              # issue s185
            }                                                        # issue s185
         }
      # SNOOPYJC }elsif(  $ValPerl[0] eq 'sub' && $#ValClass==1 ){
      }elsif($ValPerl[0] eq 'sub' && 1 <= $#ValClass && exists $::nested_subs{$ValPerl[1]}) {   # issue 78: don't switch to nested sub
          $LocalSub{$ValPy[1]}=1;
          $::nested_sub_at_level = $Perlscan::nesting_level;
          push @::nested_sub_at_levels, $::nested_sub_at_level;     # issue s241
      }elsif(  $ValPerl[0] eq 'sub' && $#ValClass >= 1) {         # SNOOPYJC: handle sub xxx() (with parens)
         $CurSubName=$ValPy[1];
         my $dx = rindex($CurSubName, '.');     # issue s320
         if($dx != -1) {                        # issue s320
             $LocalSub{$CurSubName}=1;          # issue s320
             my $packname = &Perlscan::unescape_keywords(substr($CurSubName,0,$dx));       # issue s320
             $CurSubName = substr($CurSubName, $dx+1);  # issue s320
             if(!exists $UsePackage{$packname} && !exists $RequirePackage{$packname} && !exists $PYTHON_PACKAGES_SET{$packname} && !exists $Packages{$packname}) {   # issue s320
                $Packages{$packname} = 2;           # issue s320: 2 means we reference it but don't define it here
             }
         }
	     $initialized{$CurSubName}{$PERL_ARG_ARRAY} = 'a';	  # SNOOPYJC
         $LocalSub{$CurSubName}=1;
         $LocalSub{"$CurPackage.$CurSubName"}=1 if $ValPy[1] eq $CurSubName;   # issue s3, issue s320
         %DeclaredVarH=(); # this is the list of my varible for given sub; does not needed for any other sub
	     $we_are_in_sub_body=1;			# issue 45
         if($::debug > 3) {
             say STDERR "get_globals: switching to '$CurSubName' at line $.";
         }
         # issue s155: can have sub nested in BEGIN: correct_nest(0,0);                             # issue 45
      } elsif($ValClass[0] eq 'c' && $ValPerl[0] eq 'package' && $#ValClass >= 1) {     # SNOOPYJC: Keep track of packages
          $Packages{$ValPy[1]} = 1;              # SNOOPYJC
          $PackageDef{$ValPy[1]} = $. unless exists $PackageDef{$ValPy[1]};              # SNOOPYJC, issue s18
          push @Packages, $ValPy[1];             # SNOOPYJC
          $CurPackage = $ValPy[1];               # SNOOPYJC
      }elsif( $ValClass[0] eq '{') {                    # issue 45
          correct_nest(1);                              # issue 45
          if($deferred_nesting_top) {            # issue s252: We deferred marking this aliased_foreach because it's a stmt modifier
            $top = $Perlscan::nesting_stack[-1];
            $top->{is_sub} = 1;
            $top->{in_sub} = 1;
            $top->{cur_sub} = $deferred_nesting_top;
            $top->{type} = 'sub';
            $top->{was_foreach} = 1;
            $deferred_nesting_top = undef;
          }
      }elsif( $ValClass[0] eq '}' && $#ValClass == 0) {	# issue 45
         correct_nest(-1);                              # issue 45
         if($we_are_in_sub_body && $NextNest == 0) {	# issue 45
             # SNOOPYJC: At the end of the function, if we are going to insert a "return N" statement
             # in ::finish(), then set the type of the function, else set it to 'm' for mixed.
             if($::debug > 3) {
                 say STDERR "get_globals: switching back to 'main' at line $.";
             }
             my $typ = 'm';
             $typ = $PriorExprType if(defined $PriorExprType);
             $VarType{$CurSubName}{__main__} = merge_types($CurSubName, '__main__', $typ, undef, 'a');  # issue s356
             my $pkg = 'sys.modules["__main__"]';
             $pkg = $CurPackage if(defined $CurPackage);
             $VarType{"$pkg.$CurSubName"}{__main__} = $VarType{$CurSubName}{__main__};
             $we_are_in_sub_body = 0;		# issue 45
             $CurSubName='__main__';		# issue 45
         }					# issue 45
      }else{
         my $p;                             # issue s184
         my $cs = &Perlscan::cur_sub();     # issue s184, issue s185
         for( $k=0; $k<@ValClass; $k++ ){
             if(  $ValClass[$k]=~/[sahG]/ ){        # issue s248: add 'G' to handle *db_connect::new = sub {...};
                check_ref($CurSubName, $k);                  # SNOOPYJC
                if($k != 0 && $ValClass[$k-1] eq 't' && $ValPerl[$k-1] eq 'my') {       # SNOOPYJC e.g. for(my $i=...)
                    $DeclaredVarH{$ValPy[$k]} = 1;
                }
                next if exists($DeclaredVarH{$ValPy[$k]});
                next if(  defined($ValType[$k]) && $ValType[$k] eq 'X' && !exists($GLOBALS{$ValPy[$k]}));        # SNOOPYJC
                next if($ValPy[$k] eq '');      # Undefined special var
                $VarSubMap{$ValPy[$k]}{$CurSubName}='+';
                if( $ValPy[$k] =~/[\[\(]/ && $ValPy[$k] !~ /^len\(/ && $ValPy[$k] ne 'globals()' &&
                    $ValPy[$k] !~ /\.__dict__$/ &&
                    substr($ValPy[$k],0,5) ne '(len(' &&        # issue 14: $#x => (len(x)-1)
                    $ValType[$k] ne 'ss' &&                 # issue s185
                    $ValType[$k] ne '%s' &&                 # issue s215
                    $ValType[$k] ne '@s' &&                 # issue s243
                    substr($ValPy[$k],0,4) ne 'sys.'){   # Issue 13
                   $InLineNo = $.;
                   say "=== Pass 1 INTERNAL ERROR in processing line $InLineNo Special variable is $ValPerl[$k] as $ValPy[$k], k=$k, our ValType=$ValType[$k]";
                   $DB::single = 1;
                }
              } elsif($ValClass[$k] eq 'k' && $ValPerl[$k] eq 'use' && $k+1 <= $#ValClass && $ValPerl[$k+1] eq 'parent') {      # issue s18
                  my $t = 'a of S';
                  my $pyISA = &Perlscan::escape_keywords($CurPackage,1) . '.' . &Perlscan::remap_conflicting_names('ISA', '@', '', 1);
                  $t = merge_types($pyISA, '__main__', $t, undef, 'a'); # issue s356
                  $VarType{$pyISA}{__main__} = $t;
      	          $VarSubMap{$pyISA}{__main__}='+';
                  $NeedsInitializing{__main__}{$pyISA} = $t if(!exists $initialized{__main__}{$pyISA});
              } elsif($ValClass[$k] eq 'f' && ($ValPerl[$k] eq 'shift' || $ValPerl[$k] eq 'pop') &&        # SNOOPYJC
                      ($k == $#ValClass || $ValPerl[$k+1] eq '@_' || $ValClass[$k+1] !~ /[ahfi]/)) {       # SNOOPYJC
		         # issue s84 $SubAttributes{$CurSubName}{modifies_arglist} = 1;                  # SNOOPYJC: This sub shifts it's args
                 my $cs = &Perlscan::cur_sub();
                 # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1;                  # SNOOPYJC: This sub shifts it's args, issue s84
                 set_sub_attribute($cs, 'modifies_arglist', 1);                  # SNOOPYJC: This sub shifts it's args, issue s84
                 if($ValPerl[$k] eq 'shift') {                      # issue s184
                     # issue s241 $SubAttributes{$cs}{arglist_shifts}++;         # issue s184
                     set_sub_attribute($cs, 'arglist_shifts', get_sub_attribute($cs, 'arglist_shifts',0,0) + 1);   # issue s184, issue s241
                 }                                                  # issue s184
              } elsif($ValClass[$k] eq 'f' && ($ValPerl[$k] eq 'push' || $ValPerl[$k] eq 'unshift') &&
		      (($#ValClass >= $k+1 && $ValPerl[$k+1] eq '@_') ||
               ($k+2 <= $#ValClass && $ValPerl[$k+1] eq '(' && $ValPerl[$k+2] eq '@_'))) { # issue s53, issue s220
		         # issue s84 $SubAttributes{$CurSubName}{modifies_arglist} = 1;     # issue s53
                 my $cs = &Perlscan::cur_sub();
                 # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1;     # issue s53, issue s84
                 set_sub_attribute($cs, 'modifies_arglist', 1);                  # SNOOPYJC: This sub shifts it's args, issue s84
                 if($ValPerl[$k] eq 'unshift') {                      # issue s184
                     # issue s241 $SubAttributes{$cs}{arglist_shifts}--;         # issue s184
                     set_sub_attribute($cs, 'arglist_shifts', get_sub_attribute($cs, 'arglist_shifts',0,0) - 1);   # issue s184, issue s241
                 }                                                  # issue s184
              } elsif((($ValClass[$k] eq 'q' && $ValPy[$k] =~ /\b$DEFAULT_VAR\b/)) ||                # issue s151
                  ($ValClass[$k] eq 'f' && ($ValPerl[$k] eq 're' && 
                   ($ValPy[$k] =~ /\b$DEFAULT_VAR\b/ || $ValPy[$k] =~ /^\.replace/)) ||
                  # issue s151 ($ValPerl[$k] eq 'tr' && ($k == 0 || $ValClass[$k-1] ne '~'))) {      # issue s8: sets the $DEFAULT_VAR
                  ($ValPerl[$k] eq 'tr' && ($k == 0 || $ValClass[$k-1] ne 'p')))) {      # issue s8: sets the $DEFAULT_VAR, issue s151
                  
		        my $t = merge_types($DEFAULT_VAR, $CurSubName, 'S');			# issue s104
                $VarType{$DEFAULT_VAR}{$CurSubName} = $t;      # issue s8, issue s104
      	        $VarSubMap{$DEFAULT_VAR}{$CurSubName}='+';		# issue s103
                $NeedsInitializing{$CurSubName}{$DEFAULT_VAR} = $t if(!exists $initialized{$CurSubName}{$DEFAULT_VAR}); # issue s8, issue s104
                if(($ValPy[$k] =~ /^re\.sub/ ||
                    $ValPy[$k] =~ /^\.replace/) &&      # issue s344
                   &Perlscan::is_loop_ctr('$_')) {      # issue s252
                    &Perlscan::set_loop_ctr_mod('$_');  # issue s252
                }                                       # issue s252

	          } elsif($ValClass[$k] eq 'f' && arg_type($ValPerl[$k], $ValPy[$k], 0, 0) eq 'H' && $#ValClass > $k) {	# issue s101: handle file handles across subs
		        my $h = $k+1;
		        $h++ if($ValClass[$h] eq '(');
		        if($ValClass[$h] eq 'i' && index($ValPy[$h],'.') < 0) {	# Do this for bareword file handles, but not STDxx
       	            $VarSubMap{$ValPy[$h]}{$CurSubName}='+';
		        }
                if($ValPerl[$k] eq 'open') {            # issue s285: Handle open as dup - reference the FH being duped
                    if($h+2 < $#ValClass && $ValClass[$h+2] eq '"' && $ValPerl[$h+2] =~ /^\>\&(\w+)/) {
                        my $name = $1;      # e.g. open(STDERR, ">&SAVERR")
       	                $VarSubMap{$name}{$CurSubName}='+' unless exists $Perlscan::keyword_tr{$name};
                    } elsif($h+4 < $#ValClass && $ValClass[$h+4] eq 'i' && index($ValPy[$h+4],'.') < 0) {   # e.g. open(STDERR, ">&", SAVERR)
       	                $VarSubMap{$ValPy[$h+4]}{$CurSubName}='+';
                    }
                }
              } elsif($ValClass[$k] eq 'f' &&
		        ((($ValPerl[$k] eq 'chomp' || $ValPerl[$k] eq 'chop' || $ValPerl[$k] eq 'eval' || $ValPerl[$k] eq 'split' || 
			     $ValPerl[$k] eq 'defined' || $ValPerl[$k] eq 'mkdir' || $ValPerl[$k] eq 'ord' || $ValPerl[$k] eq 'chr' ||
		 	     $ValPerl[$k] eq 'quotemeta' || $ValPerl[$k] eq 'oct' || $ValPerl[$k] eq 'hex' || $ValPerl[$k] eq 'require' ||
		 	     $ValPerl[$k] eq 'stat' || $ValPerl[$k] eq 'lstat' || $ValPerl[$k] eq 'reverse') && ($#ValClass == $k || end_of_function($k) == $k)) ||
			    ($ValPerl[$k] eq 'split' && $#ValClass == $k+1) ||
			    (($ValPerl[$k] eq 'print' || $ValPerl[$k] eq 'printf') && ($#ValClass == $k || ($#ValClass == $k+1 && $ValClass[$k+1] eq 'i'))))) {	# issue s103
		        my $t = 'S';					        # issue s104
		        $t = 'm' if $ValPerl[$k] eq 'defined';			# issue s104
                $t = merge_types($DEFAULT_VAR, $CurSubName, $t);        # issue s104
                $VarType{$DEFAULT_VAR}{$CurSubName} = $t;      		# issue s104
		        $VarSubMap{$DEFAULT_VAR}{$CurSubName}='+';		# issue s103
	      	    $NeedsInitializing{$CurSubName}{$DEFAULT_VAR} = $t if(!exists $initialized{$CurSubName}{$DEFAULT_VAR});	# issue s103, issue s104
                if($ValPerl[$k] eq 'chomp' || $ValPerl[$k] eq 'chop') { # issue s252: They modify $_
                    if(&Perlscan::is_loop_ctr('$_')) {      # issue s252
                        &Perlscan::set_loop_ctr_mod('$_');  # issue s252
                    }                                       # issue s252
                }                                           # issue s252
              } 
              if($ValClass[$k] eq '(' && $k+1 <= $#ValClass && $ValClass[$k+1] eq ')' && $ValPerl[$k] eq '(' &&
                 ($k == 0 || ($ValClass[$k-1] eq 'k' && $ValPerl[$k-1] eq 'return'))) {     # issue s254
                 # Here we are (potentially) returning () - make this an implicit wantarray, since we
                 # need to return either an empty array or None, based on the calling context
                  my $cs = &Perlscan::cur_sub();                   # issue s254
                  if($cs ne '__main__') {                          # issue s254
                      $Perlscan::SpecialVarsUsed{'wantarray'}{$cs} = 2; # issue s254
                      set_sub_attribute($cs, 'wantarray', 2);      # issue s254
                      say STDERR "Setting 'wantarray' on $cs based on return of ()" if $::debug;
                  }                                                # issue s254
              }                                                    # issue s254

	          if($ValClass[$k] eq 'i' && ($k == 0 || $ValPerl[$k-1] eq 'return' || $ValPerl[$k-1] eq 'goto') && $we_are_in_sub_body && $k+3 <= $#ValClass &&
                      $ValClass[$k+1] eq '(' && $ValPerl[$k+2] eq '@_' && $ValClass[$k+3] eq ')' &&
                       defined get_sub_attribute_at($k,'wantarray')) { # issue s241: goto &mysub; -or- return &mysub;
                  my $cs = &Perlscan::cur_sub();                   # issue s241
                  set_sub_attribute($cs, 'wantarray', 1);                           # issue s241
                  set_sub_attribute($cs, 'wantarray_inherited_from', $ValPy[$k]);   # issue s241
# issue s282              } elsif($ValClass[$k] eq 'i' && $k == 3 && $ValClass[0] eq 'G' && $ValClass[1] eq '=' && $ValClass[2] eq '\\' &&
# issue s282                      (defined get_sub_attribute_at($k, 'wantarray') || defined get_sub_attribute_at($k, 'out_parameters'))) {    # issue s241: *x = \&mysub;
# issue s282                  clone_sub_attributes($ValPy[$k], $ValPy[0]);      # issue s241
# issue s282                  if(exists $LocalSub{$ValPy[$k]}) {
# issue s282                      $LocalSub{$cs} = $LocalSub{$ValPy[$k]};
# issue s282                  }
              } elsif($ValClass[$k] eq 'i' && $ValClass[0] eq 'G' && $ValClass[1] eq '=' && $ValClass[$k-1] eq '\\') {    # issue s241: *x = \&mysub;  -or- *x = *y = \&mysub
                  for(my $j = 0; $j < $k; $j++) {                           # issue s282 - see also test issue 115
                      if($ValClass[$j] eq 'G' && $ValClass[$j+1] eq '=') {
                         clone_sub_attributes($ValPy[$k], $ValPy[$j]);
                         if(exists $LocalSub{$ValPy[$k]}) {
                             $LocalSub{$ValPy[$j]} = $LocalSub{$ValPy[$k]};
                         }
                      }
                 }
              }
              my $outs;                     # issue s252
              if($ValClass[$k] eq 'f' && exists $PYF_OUT_PARAMETERS{$ValPy[$k]}) {      # issue s252
                  $p = get_function_out_parameter($k);                                  # issue s252
                  if(defined $p && &Perlscan::is_loop_ctr($ValPerl[$p])) {              # issue s252
                    &Perlscan::set_loop_ctr_mod($ValPerl[$p]);                          # issue s252
                  }                                                                     # issue s252
                  if(defined $p) {
                    my $typ = arg_type_from_pos($p);                              # issue s252
                    my $t = merge_types($ValPy[$p], $CurSubName, $typ, $p);           # issue s252, issue s256
                    $VarType{$ValPy[$p]}{$CurSubName} = $t;                       # issue s252
                    if(exists $NeedsInitializing{$CurSubName}{$ValPy[$p]}) {      # issue s252
                        $NeedsInitializing{$CurSubName}{$ValPy[$p]} = $t;         # issue s252
                    }                                                             # issue s252
                  }
              } elsif($ValClass[$k] eq 'i' && ($k == 0 || $ValPerl[$k-1] ne 'sub') && exists $LocalSub{$ValPy[$k]}) {   # issue s252
                  # Is this a sub call that can change the loop counter?
                  my $lc = &Perlscan::get_loop_ctr();
                  if(defined $lc) {
                      my @lcs = split(/,/, $lc);
                      for $lc (@lcs) {
                          if($lc eq '$_') {
                              # VarSubMap isn't set for the default var because it has ValType==X - the
                              # default variable isn't global in Pythonizer, so we don't assume it's changed
                              # over a sub call.
                              #if(exists $VarSubMap{$DEFAULT_VAR}{$ValPy[$k]}) {
                              #   &Perlscan::set_loop_ctr_mod('$_');
                              #}
                          } else {
                              my $py = &Perlscan::perl_name_to_py($lc);
                              if(exists $VarSubMap{$py}{$ValPy[$k]} && &Perlscan::loop_ctr_type($lc, $py) ne 'my') {
                                 &Perlscan::set_loop_ctr_mod($lc);
                              }
                          }
                      }
                  }
              }
              if($ValClass[$k] eq 'i' && ($k == 0 || $ValPerl[$k-1] ne 'sub') && $#ValClass != $k &&
                    defined ($outs = get_sub_attribute_at($k, 'out_parameters'))) {     # issue s252
                   my $adj = 0;
                   if($k == 0 || $ValClass[$k-1] ne 'D') {
                       ;
                   } else {
                       $adj = 1;        # Allow for the first arg being $self
                   }
                   my $ep = &::end_of_call($k);
                   foreach my $arg (@$outs) {
                       no warnings 'numeric';       # handle 1r, etc
                       my ($s, $e) = &::get_arg_start_end($k, $ep, $arg+1-$adj);
                       my $r = '';
                       $r = 'r' if($arg =~ /r/);
                       if($s && ($s == $e || ($r eq 'r' && $ValClass[$s] eq '\\' && $e-$s == 1))) {
                           if(&Perlscan::is_loop_ctr($ValPerl[$e])) {
                               &Perlscan::set_loop_ctr_mod($ValPerl[$e]);                          # issue s252
                           }
                       }
                   }
              }                                                                         # issue s252
              if($ValClass[$k] eq 'f' && $we_are_in_sub_body && $#ValClass != $k && exists $PYF_OUT_PARAMETERS{$ValPy[$k]} &&
                  ($p = function_modifies_sub_arg($k))) {              # issue s183
                 my $cs = &Perlscan::cur_sub();
                 # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1 if $ValPerl[$p] eq '$_' || $ValPerl[$p] eq '@_';     # issue s183: function modifies argument, issue s185
                 set_sub_attribute($cs, 'modifies_arglist', 1) if $ValPerl[$p] eq '$_' || $ValPerl[$p] eq '@_';     # issue s183: function modifies argument, issue s185
                 my $arg;
                 if($ValPy[$p] =~ /\[(\d+)\]/) {                # issue s184
                     my $als = 0;                           # issue s184
                     # issue s241 $als = $SubAttributes{$cs}{arglist_shifts} if exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arglist_shifts};    # issue s184
                     $arg = $1;                     # issue s241
                     $als = get_sub_attribute($cs, 'arglist_shifts',0,0);   # issue s241
                     # issue s241 $arg = $1 + $als;               # issue s185
                     $arg += $als;                  # issue s241
                     $arg .= 'r' if($ValType[$p] eq 'ss');      # issue s185
                 } elsif($ValType[$p] eq 'ss') {                      # issue s185: 'ss' means it's a '$$'
                     # issue s241 $arg = $SubAttributes{$cs}{arg_copies}{$ValPerl[$p]};
                    $arg = ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$p]};   # issue s241
                    $arg .= 'r';            # Reference
                 } else {               # issue s184: varargs
                     $arg = 'var';      # issue s185
                 }
                 set_out_parameter($cs, $arg);          # issue s184, issue s185
                 # issue s184 logme('W', "Sub arg modified by this $ValPerl[$k] call will not change the argument passed in python");
	          } elsif($ValClass[$k] eq 'i' && ($k == 0 || $ValPerl[$k-1] ne 'sub') && $we_are_in_sub_body && $#ValClass != $k && 
                  # issue s241 ((($k == 0 || $ValClass[$k-1] ne 'D') && exists $SubAttributes{$ValPy[$k]}{out_parameters}) ||
                  # issue s241 ($k != 0 && $ValClass[$k-1] eq 'D' && exists $SubAttributes{'->'.$ValPy[$k]}{out_parameters}))) { # issue s184
                       defined get_sub_attribute_at($k, 'out_parameters')) { # issue s184, issue s241
                   # This is a call to a sub that modified it's arguments - propagate that up to this sub if appropriate
                   my $adj = 0;
                   if($k == 0 || $ValClass[$k-1] ne 'D') {
                       # issue s241 $outs = $SubAttributes{$ValPy[$k]}{out_parameters};
                       $outs = get_sub_attribute($ValPy[$k], 'out_parameters');     # issue s241
                   } else {
                       # issue s241 $outs = $SubAttributes{'->'.$ValPy[$k]}{out_parameters};
                       $outs = get_sub_attribute($ValPy[$k], 'out_parameters', 1);      # issue s241: method call
                       $adj = 1;        # Allow for the first arg being $self
                   }
                   my $cs = &Perlscan::cur_sub();
                   my $als = 0;                           # issue s184
                   # issue s241 $als = $SubAttributes{$cs}{arglist_shifts} if exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arglist_shifts};    # issue s184
                   $als = get_sub_attribute($cs, 'arglist_shifts',0,0);   # issue s241
                   my $ep = &::end_of_call($k);
                   foreach my $arg (@$outs) {
                       no warnings 'numeric';       # handle 1r, etc
                       my ($s, $e) = &::get_arg_start_end($k, $ep, $arg+1-$adj);
                       if($s && $s == $e) {
                           my $r = '';                          # issue s185
                           $r = 'r' if($arg =~ /r/);            # issue s185
                           if($ValClass[$s] eq 's' && $ValPerl[$s] eq '$_' && $ValPy[$s] =~ /^$PERL_ARG_ARRAY/) {   # issue s184
                               # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1;    # SNOOPYJC: This sub mods it's args, issue s84
                              set_sub_attribute($cs, 'modifies_arglist', 1);    # SNOOPYJC: This sub mods it's args, issue s84, issue s241
                              if($ValPy[$s] =~ /\[(\d+)\]/) {                # issue s184
                                  set_out_parameter($cs, ($1+$als).$r);          # issue s184, issue s185
                               } else {               # issue s184: varargs
                                  set_out_parameter($cs, 'var');            # issue s184
                               }
                           } elsif($ValClass[$s] eq 'a' && $ValPerl[$s] eq '@_') {      # issue s241
                              # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1;    # issue s241 This sub mods it's args, issue s84
                              # issue s241 $SubAttributes{$cs}{out_parameters} = dclone($outs);    # issue s241
                              set_sub_attribute($cs, 'modifies_arglist', 1);    # SNOOPYJC: This sub mods it's args, issue s84, issue s241
                              set_sub_attribute($cs, 'out_parameters', dclone($outs));    # issue s241
                              set_out_parameter($cs, $arg);          # issue s241: This is just used to set the -> and the package:: entries
                              last;     # We copied the whole thing so we don't need to do anything else
                          }
                       }
                   }
              } elsif($k != 0 && $ValClass[$k] eq 'c' && $k+2 <= $#ValClass &&
                      ((($ValPerl[$k] eq 'while' || $ValPerl[$k] eq 'until') && $ValClass[$k+1] eq '(' && ($ValClass[$k+2] eq 'j' || $ValClass[$k+2] eq 'g')) ||
		               ($ValPy[$k] eq 'for' && for_loop_uses_default_var($k)))) {	# issue s235: Handle while/until/for loop as stmt modifier
	            $VarSubMap{$DEFAULT_VAR}{$CurSubName}='+';		# issue s235
                my $t = merge_types($DEFAULT_VAR, $CurSubName, 'm');     # issue s235 it's a string but it could also be undef at EOF
                $VarType{$DEFAULT_VAR}{$CurSubName} = $t;      		# issue s235
	            $initialized{$CurSubName}{$DEFAULT_VAR} = $t unless $NeedsInitializing{$CurSubName}{$DEFAULT_VAR};	# issue s103, issue s104
              } elsif($ValClass[$k] eq 'f' && $ValPerl[$k] eq 'bless') {        # issue s317
                  # If we bless an object into a named package, make sure that package is marked as a class
                  # so we pass is_class=True to _init_package
                  my $lst = $k+1;
                  my $end = $#ValClass;
                  if($ValPerl[$lst] eq '(') {
                      $end = matching_br($lst);
                      $lst++;
                  }
                  my $comma = next_same_level_token(',', $lst, $end);
                  if($comma != -1 && $comma+1 <= $end && ($ValClass[$comma+1] eq '"' || $ValClass[$comma+1] eq 'i')) {
                      $Perlscan::SpecialVarsUsed{'bless'}{$ValPerl[$comma+1]} = 1;
                  }
              }

              if($ValClass[$k] eq 'q' && $ValPy[$k] =~ /\b$DEFAULT_MATCH:=/) {       # issue s323
	             $VarSubMap{$DEFAULT_MATCH}{$CurSubName}='+';		# issue s323
              }

          } # for
          if(scalar(@ValClass) > 0 && $ValClass[0] eq 'k' && $ValPerl[0] eq 'return') {         # SNOOPYJC: return statement
              $typ = 'm';
              if(scalar(@ValClass) > 1) {
                  my $end = $#ValClass;
                  my $c;                # Look for return N if(...);
                  $end = $c-1 if(($c = next_same_level_token('c', 1, $end)) != -1);
                  $typ = expr_type(1, $end, $CurSubName);
              }
              $VarType{$CurSubName}{__main__} = merge_types($CurSubName, '__main__', $typ, undef, 'a'); # issue s356
          } elsif(($#ValClass >= 2 && ($ValPerl[0] eq 'while' || $ValPerl[0] eq 'until') && $ValClass[1] eq '(' && ($ValClass[2] eq 'j' || $ValClass[2] eq 'g')) ||
		   ($#ValClass >= 2 && $ValPy[0] eq 'for' && for_loop_uses_default_var(0))) {	# issue s103, issue s235
	          $VarSubMap{$DEFAULT_VAR}{$CurSubName}='+';		# issue s103
              my $t = merge_types($DEFAULT_VAR, $CurSubName, 'm');     # issue s104: it's a string but it could also be undef at EOF
              $VarType{$DEFAULT_VAR}{$CurSubName} = $t;      		# issue s104
	          $initialized{$CurSubName}{$DEFAULT_VAR} = $t unless $NeedsInitializing{$CurSubName}{$DEFAULT_VAR};	# issue s103, issue s104
	      }
      } # statements
      # SNOOPYJC: Capture the prior expr type in case of implicit function return (as done by pythonizer::finish())
      # If we determine it's a mixed type ('m'), then stop checking
      if(scalar(@ValClass) == 0) {                              # SNOOPYJC
          $PriorExprType = 'm';                 # We couldn't have inserted a "return" here
      } elsif(exists $VarType{$CurSubName} && exists $VarType{$CurSubName}{__main__} && $VarType{$CurSubName}{__main__} eq 'm') {   # SNOOPYJC: not worth checking
          $PriorExprType = 'm';
      } else {
         $typ = 'm';                    # mixed by default
         if((index('"(dsahf-', $ValClass[0]) >= 0)) {           # Expression
             $typ = expr_type(0, $#ValClass, $CurSubName);
         } elsif(($p = index($TokenStr, '=')) > 0 &&  $ValClass[0] ne 't') {  # Assignment
             $typ = expr_type($p+1, $#ValClass, $CurSubName);
         } elsif($ValClass[0] eq 'k' && scalar(@ValClass) > 1) {      # Return value
             $typ = expr_type(1, $#ValClass, $CurSubName);
         }
         $PriorExprType = $typ;               # SNOOPYJC
      }
      # SNOOPYJC: Capture some potential sub calls for use/require statement support
      # The code here mirrors that of pythonizer main pass where it checks for $LocalSub{...}.
      if($TokenStr =~ m'^t[ahsG]=i$') {
          $PotentialSub{$ValPy[3]} = 1;
          trash_global_types($ValPy[3]) if !exists $LocalSub{$ValPy[3]};        # issue bootstrap
      } elsif($TokenStr =~ m'^h=\(') {
          my $comma_flip = 0;
          for(my $i=3; $i<$#ValPy; $i++) {
              if($comma_flip == 1 && $ValClass[$i] eq 'i') {
                $PotentialSub{$ValPy[$i]} = 1;
                trash_global_types($ValPy[$i]) if !exists $LocalSub{$ValPy[$i]};        # issue bootstrap
              } elsif($ValPy[$i] eq ',') {
                  $comma_flip = 1-$comma_flip;
              }
          }
      } elsif($TokenStr eq 'c(i)') {
          $PotentialSub{$ValPy[2]} = 1;
          trash_global_types($ValPy[2]) if !exists $LocalSub{$ValPy[2]};        # issue bootstrap
      } elsif($ValPerl[0] ne 'use' && $ValPerl[0] ne 'require' && $ValPerl[0] ne 'no') {
          for(my $i=0; $i <= $#ValClass; $i++) {
              if($ValClass[$i] eq 'i') {
                 next if($i+1 <= $#ValClass && $ValClass[$i+1] =~ /[AD]/);         # key=>, method->
                 if(($i+1 > $#ValClass || $ValPerl[$i+1] eq '(') ||      # f(...
                   ($i == 0 || ($ValPerl[$i-1] ne '{' && $ValClass[$i-1] ne 'D'))) {      # not {key..., not ->method
                    $PotentialSub{$ValPy[$i]} = 1;
                    trash_global_types($ValPy[$i]) if !exists $LocalSub{$ValPy[$i]};        # issue bootstrap
                 }
              }
          }
      } elsif($#ValClass >= 2 && $ValPerl[0] eq 'use' && $ValPerl[1] eq 'subs') {
          my @subs = ();
          for(my $i=2; $i<=$#ValClass; $i++) {
             if($ValClass[$i] eq '"') {         # Plain String
                 push @subs, $ValPy[$i];
             } elsif($ValClass[2] eq 'q') {
                if(index(q('"), substr($ValPy[$i],0,1)) >= 0) {
                    push @subs, $ValPy[$i];
                } else {
                    push @subs, map {'"'.$_.'"'} split(' ', $ValPy[$i]);         # qw(...) on use stmt doesn't generate the split
                }
             }
          }
          for my $sub (@subs) {
              $UseSub{&::unquote_string($sub)} = 1;
          }
      } elsif($#ValClass >= 1 && $ValPerl[0] eq 'use' && $ValClass[1] eq 'i') {   # issue s209
          $UsePackage{$ValPy[1]} = $. unless exists $UsePackage{$ValPy[1]};       # issue s209, issue s18
      } elsif($#ValClass >= 1 && $ValPerl[0] eq 'require' && $ValClass[1] eq 'i') {     # issue s18: Distinguish require from use as require is dynamic
          $RequirePackage{$ValPy[1]} = $. unless exists $RequirePackage{$ValPy[1]};       # issue s18
      }
      if($TokenStr =~ m'C"' && !$::saved_eval_tokens) {     # issue 42 eval '...'
          # Parse the eval string into tokens
          my $pos = $-[0];
          my $ch0;
          if($ValPerl[$pos] eq 'eval' && (($ch0 = substr($ValPy[$pos+1],0,1)) eq "'" || $ch0 eq '"')) {
              $::saved_eval_tokens = 1;     # We don't need to actually save the code, just set a flag for getline
              $::saved_eval_lno = $.;
              my $t;
              while(($t = getline())) {
                  push @::saved_eval_buffer, $t;
              }
              my $text;
              if(substr($ValPy[$pos+1],0,3) eq '"""') {
                $text = substr($ValPy[$pos+1],3,length($ValPy[$pos+1])-6);
              } else {
                $text = substr($ValPy[$pos+1], 1, length($ValPy[$pos+1])-2);
              }
              my @lines = split(/^/m, $text);
              say STDERR "On line $., pushing " . scalar(@lines) . " lines + { }" if($::debug);
              getline('{');     # Push this one to the regular buffer (to help us count lines easier)
              for my $ln (@lines) {
                  getline($ln, 1);      # Push to special_buffer
              }
              getline('}', 1);  # Push to special_buffer
          }
      } elsif(!$::saved_eval_tokens) {                  # issue 78: e flag on regex
          for(my $i = 0; $i <= $#ValClass; $i++) {
              if($ValClass[$i] eq 'f' && $ValPerl[$i] eq 're' && $ValPy[$i] =~ /re\.E/) {
                  if($ValPy[$i] =~ /re\.E\|re\.E/) {
                      logme('W',"Regex substitute 'ee' flag is not supported");
                  }
                  $ValPy[$i] =~ /,e'''(.*)'''/s;
                  my $expr = $1;
                  # issue s26 my $subname = "$ANONYMOUS_SUB$.";
                  $VarSubMap{$DEFAULT_MATCH}{$CurSubName}='+';        # issue s323
                  $VarSubMap{$DEFAULT_MATCH}{__main__}='+';           # issue s323
                  my $subname = new_anonymous_sub();     # issue s26
                  $::nested_subs{$subname} = "$DEFAULT_MATCH";
                  $::saved_eval_tokens = 1;
                  $::saved_eval_lno = $.;
                  my $t;
                  while(($t = getline())) {
                    push @::saved_eval_buffer, $t;
                  }
                  my @lines = split(/^/m, $expr);
                  say STDERR "On line $., pushing " . scalar(@lines) . " lines + sub $subname { }" if($::debug);
                  getline("sub $subname {");
                  for my $ln (@lines) {
                      getline($ln, 1);
                  }
                  getline('}', 1);
                  last;
                  #} elsif($ValClass[$i] eq 'k' && $ValPerl[$i] eq 'no' && $ValPerl[$i+1] eq 'warnings') {
                  #$::saved_eval_tokens = 1;
                  #$::saved_eval_lno = $.;
                  #my $t;
                  #while(($t = getline())) {
                  #push @::saved_eval_buffer, $t;
                  #}
                  #getline("local ($^W) = 0;");
                  #last;
              }
          }
      }
      if($#ValClass != 0 && $ValClass[$#ValClass] eq 'k' && $ValPerl[$#ValClass] eq 'sub') {
         # issue s26 my $subname = "$ANONYMOUS_SUB$.";
         my $subname = new_anonymous_sub();     # issue s26
         $::nested_subs{$subname} = "\*$PERL_ARG_ARRAY";
         push @::saved_sub_tokens_stack, $::saved_sub_tokens;            # issue s311
         push @::saved_sub_tokens_level, $::nested_sub_at_level;         # issue s311
         $::saved_sub_tokens = &::package_tokens();
         $::nested_sub_at_level = $Perlscan::nesting_level;
         push @::nested_sub_at_levels, $::nested_sub_at_level;     # issue s241
         &::p_replace($::saved_sub_tokens, $#ValClass,'"',$subname,$subname);     # Change the 'sub' to the subname reference
         destroy(0, $#ValClass);
         append('i', $subname, $subname);
         say STDERR "Creating nested_subs{$subname} for sub in expression" if($::debug);
         # Since we already processed the '{' after the 'sub', adjust the nesting_info at the top of the stack
         $top = $Perlscan::nesting_stack[-1];
         $top->{is_sub} = 1;
         $top->{in_sub} = 1;
         $top->{cur_sub} = $subname;
         $top->{type} = 'sub';
         if($::debug >= 3) {
            no warnings 'uninitialized';
            say STDERR "updated nesting_info=@{[%{$top}]}";
        }
      }
      if($#ValClass != 0 && $ValClass[$#ValClass] eq 'C' && $ValPerl[$#ValClass] eq 'do') {     # issue s74
         my $subname = new_anonymous_sub();
         $::nested_subs{$subname} = "";
         push @::saved_sub_tokens_stack, $::saved_sub_tokens;            # issue s311
         push @::saved_sub_tokens_level, $::nested_sub_at_level;         # issue s311
         $::saved_sub_tokens = &::package_tokens();
         $::nested_sub_at_level = $Perlscan::nesting_level;
         push @::nested_sub_at_levels, $::nested_sub_at_level;     # issue s241
         &::p_replace($::saved_sub_tokens, $#ValClass,'"',$subname,$subname);     # Change the 'sub' to the subname reference
         &::p_append($::saved_sub_tokens,'(','(','(');            # insert '()'
         &::p_append($::saved_sub_tokens,')',')',')');
         destroy(0, $#ValClass);
         append('i', $subname, $subname);
         say STDERR "Creating nested_subs{$subname} for do in expression" if($::debug);
         # Since we already processed the '{' after the 'sub', adjust the nesting_info at the top of the stack
         $top = $Perlscan::nesting_stack[-1];
         $top->{is_sub} = 1;
         $top->{in_sub} = 1;
         $top->{cur_sub} = $subname;
         $top->{type} = 'sub';
         $top->{was_do} = 1;                        # issue s137
         if($::debug >= 3) {
            no warnings 'uninitialized';
            say STDERR "updated nesting_info=@{[%{$top}]}";
        }
      }
      if($#ValClass >= 1 && $ValClass[0] eq 'c' && is_foreach_loop(0)) {  # issue s252
         my $expr_start;
         my $loop_ctr_ndx;
         my $loop_ctr_py;
         my $loop_ctr_perl;
         if(for_loop_uses_default_var(0)) {
             $expr_start = 0;
             $expr_start = 1 if($ValPerl[1] eq '(');
         } else {
             $expr_start = next_same_level_token('(', 1, $#ValClass);
             $loop_ctr_ndx = 1;
             $loop_ctr_ndx = 2 if $ValClass[1] eq 't';
         }
         if(&::is_list($expr_start)) {
             if(defined $loop_ctr_ndx) {
                 $loop_ctr_py = $ValPy[$loop_ctr_ndx];
                 $loop_ctr_perl = $ValPerl[$loop_ctr_ndx];
             } else {
                 $loop_ctr_py = $DEFAULT_VAR;
                 $loop_ctr_perl = '$_';
             }

             my $subname = new_anonymous_sub();
             say STDERR "Creating nested_subs{$subname} for foreach $loop_ctr_py with list" if($::debug);
             if(exists $Perlscan::line_needs_try_block{$Perlscan::statement_starting_lno} &&
                 ($Perlscan::line_needs_try_block{$Perlscan::statement_starting_lno} & Perlscan::TRY_BLOCK_FOREACH)) {
                 $loop_ctr_py = '';
             }
             $::nested_subs{$subname} = $loop_ctr_py;
             $::aliased_foreach_subs{$subname} = $loop_ctr_perl; 
             $DeclaredVarH{$loop_ctr_py} = 1;  # Make sure the sub arg is not declared 'global'
             push @::saved_sub_tokens_stack, $::saved_sub_tokens;            # issue s311
             push @::saved_sub_tokens_level, $::nested_sub_at_level;         # issue s311
             $::saved_sub_tokens = &::package_tokens();
             $::nested_sub_at_level = $Perlscan::nesting_level;
             push @::nested_sub_at_levels, $::nested_sub_at_level;     # issue s241
             &::p_replace($::saved_sub_tokens, 0, 'c', 'aliased_foreach', $subname);
             if(!defined $loop_ctr_ndx) {        # Normalize it always to have a loop ctr and parens
                 &::p_insert($::saved_sub_tokens, 1, 's', '$_', $DEFAULT_VAR);
                 if($ValPerl[$expr_start] ne '(') {
                     &::p_append($::saved_sub_tokens,')',')',')');
                     &::p_insert($::saved_sub_tokens, 2, '(','(','(');
                 }
             }
             destroy(0, $#ValClass);
             replace(0,'k','sub','def');
             append('i', $subname, $subname);
             if(scalar(@Perlscan::nesting_stack) == 0 || $Perlscan::nesting_stack[-1]->{type} ne 'foreach') {
                 $deferred_nesting_top = $subname;
             } else {
                # Since we already processed the '{' after the 'for', adjust the nesting_info at the top of the stack
                $top = $Perlscan::nesting_stack[-1];
                $top->{is_sub} = 1;
                $top->{in_sub} = 1;
                $top->{cur_sub} = $subname;
                $top->{type} = 'sub';
                $top->{was_foreach} = 1;
            }
         }
      } elsif($#ValClass >= 1 && $ValClass[0] eq 'c' && $ValPerl[0] eq 'aliased_foreach') {     # issue s252
          if($ValClass[1] eq 't') {
              &Perlscan::unmap_loop_var($ValPerl[2]);           # issue s252
          } else {
              &Perlscan::unmap_loop_var($ValPerl[1]);           # issue s252
          }
      }

      correct_nest();                           # issue 45
      if($Perlscan::nesting_level < $::nested_sub_at_level) {       # issue 78
          #say STDERR "Setting nested_sub_at_level = -1" if($::debug >= 3);
          # issue s241 $::nested_sub_at_level = -1;
          pop @::nested_sub_at_levels;                   # issue s241
          $nsal = scalar(@::nested_sub_at_levels) ? $::nested_sub_at_levels[-1] : -1; # issue s241
          say STDERR "Setting nested_sub_at_level = $nsal (was $::nested_sub_at_level), nested_sub_at_levels=@::nested_sub_at_levels" if $::debug >= 3;  # issue s241
          $::nested_sub_at_level = $nsal;                           # issue s241
          
      }
      $got_first_line = 1 unless $pragma_pythonizer_line;      # issue s63, issue s325
   } # while

   # issue s4 &Perlscan::compute_desired_use_require_options();    # issue name

   &Perlscan::prepare_locals();         # issue 108: Prepare all 'local' vars for code generation

   if($::debug >= 5) {
       print STDERR "VarSubMap = ";
       $Data::Dumper::Indent=1;
       $Data::Dumper::Terse = 1;
       say STDERR Dumper(\%VarSubMap);
       print STDERR "VarType = ";
       say STDERR Dumper(\%VarType);
       print STDERR "initialized = ";
       say STDERR Dumper(\%initialized);
       print STDERR "NeedsInitializing = ";
       say STDERR Dumper(\%NeedsInitializing);
       print STDERR "NameMap = ";
       say STDERR Dumper(\%Perlscan::NameMap);
       print STDERR "ReverseNameMap = ";
       say STDERR Dumper(\%Perlscan::ReverseNameMap);
       print STDERR "sub_external_last_nexts = ";
       say STDERR Dumper(\%Perlscan::sub_external_last_nexts);
       print STDERR "line_needs_try_block = ";
       say STDERR Dumper(\%Perlscan::line_needs_try_block);
       print STDERR "line_contains_stmt_modifier = ";
       say STDERR Dumper(\%Perlscan::line_contains_stmt_modifier);
       print STDERR "line_contains_for_loop_with_modified_counter = ";
       say STDERR Dumper(\%Perlscan::line_contains_for_loop_with_modified_counter);
       print STDERR "line_modifies_foreach_counter = ";                 # issue s252
       say STDERR Dumper(\%Perlscan::line_modifies_foreach_counter);    # issue s252
       print STDERR "line_contains_local_for_loop_counter = ";			# issue s100
       say STDERR Dumper(\%Perlscan::line_contains_local_for_loop_counter);	# issue s100
       print STDERR "SubAttributes = ";
       say STDERR Dumper(\%SubAttributes);
       if(\%Perlscan::line_substitutions) {
           print STDERR "line_substitutions = ";
           say STDERR Dumper(\%Perlscan::line_substitutions);
       }
       print STDERR "sub_varclasses = ";
       say STDERR Dumper(\%Perlscan::sub_varclasses);
       print STDERR "line_varclasses = ";
       say STDERR Dumper(\%Perlscan::line_varclasses);
       $Data::Dumper::Indent=0;
       print STDERR "LocalSub = ";
       say STDERR Dumper(\%LocalSub);
       print STDERR "PotentialSub = ";
       say STDERR Dumper(\%PotentialSub);
       print STDERR "UseSub = ";
       say STDERR Dumper(\%UseSub);
       print STDERR "Packages = ";
       say STDERR Dumper(\%Packages);
       print STDERR "UsePackage = ";
       say STDERR Dumper(\%UsePackage);
       print STDERR "RequirePackage = ";
       say STDERR Dumper(\%RequirePackage);
       print STDERR "FileHandles = ";
       say STDERR Dumper(\%Perlscan::FileHandles);
       print STDERR "SpecialVarsUsed = ";
       say STDERR Dumper(\%Perlscan::SpecialVarsUsed);
       print STDERR "scalar_pos_gen_line = ";
       say STDERR Dumper(\%Perlscan::scalar_pos_gen_line);
       print STDERR "line_contains_pos_gen = ";
       say STDERR Dumper(\%Perlscan::line_contains_pos_gen);
       if(%Pass0::line_no_convert_regex) {           # issue s64
           print STDERR "line_no_convert_regex = ";
           say STDERR Dumper(\%Pass0::line_no_convert_regex);
       }
       print STDERR "sub_lines_contain_potential_last_expression = ";	# issue implicit conditional return
       say STDERR Dumper(\%Perlscan::sub_lines_contain_potential_last_expression); # issue implicit conditional return
       print STDERR "StatementStartingLno = ";	# issue s275
       say STDERR Dumper(\%Perlscan::StatementStartingLno); # issue s275
       if(defined $StartingBeginLno) {          # issue s325
           say STDERR "StartingBeginLno = $StartingBeginLno";   # issue s325
       }                                        # issue s325
=pod    # issue s4 - we don't do this any more
       if(\%UseRequireVars) {
           print STDERR "UseRequireVars = ";
           say STDERR Dumper(\%UseRequireVars);
           print STDERR "UseRequireOptionsPassed = ";
           say STDERR Dumper(\%UseRequireOptionsPassed);
           print STDERR "UseRequireOptionsDesired = ";
           say STDERR Dumper(\%UseRequireOptionsDesired);
       }
=cut
   }

   # issue s127 foreach $varname (keys %VarSubMap ){
   foreach $varname (sort keys %VarSubMap ){                # issue s127
      next if(  $varname=~/[\(\[]/ );
      # SNOOPYJC next if(  length($varname)==1 );
      next if($varname !~ /^[A-Za-z_][A-Za-z0-9._]*$/);   # SNOOPYJC: has to be a valid python var name or with a package
      $var_usage_in_subs=scalar(keys %{$VarSubMap{$varname}} );
      # SNOOPYJC if(  $var_usage_in_subs>1){
         # Variable that is present in multiple subs assumed to be global
         # Pick one common type for the variable and propagate it to all the subs
         my $common_type = undef;
         foreach $subname (keys %{$VarType{$varname}}) {
             if(defined $common_type) {
                 $common_type = common_type($common_type, $VarType{$varname}{$subname});
             } else {
                 $common_type = $VarType{$varname}{$subname}
             }
         }
         #$DB::single = 1 if(!defined $common_type);
         if(defined $common_type && exists $VarType{$varname} && exists $VarType{$varname}{__main__} && $common_type ne $VarType{$varname}{__main__} && $::debug>=3) {
                 say STDERR "get_globals: Merging to common type $common_type for global var $varname";
         }
         # issue s127 foreach $subname (keys %{$VarSubMap{$varname}} ){
         foreach $subname (sort keys %{$VarSubMap{$varname}} ){     # issue s127
            if($var_usage_in_subs>1 || exists $NeedsInitializing{$subname}{$varname}) { # SNOOPYJC
                next if($varname !~ /^[A-Za-z_][A-Za-z0-9._]*$/);   # Has to be a valid python var name or with a package
                next if($varname eq 'True' || $varname eq 'False');     # issue s23
                if($varname =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {    # Valid python var name with NO package
                    $GlobalVar{$subname}.=','.$varname;
                }
                # SNOOPYJC: Since this var exists in $VarSubMap, it's not a "my" variable and if
                # it needs initializing, we need to do it in the top-level scope, not in the sub
                $common_type = $NeedsInitializing{$subname}{$varname} if(!defined $common_type);
                my $ld = rindex($varname, '.');         # issue bootstrap: don't assume the type of a var from a package
                if($ld >= 0) {                          # issue bootstrap
                    # For bootstrapping, we have main.debug which is set to a string, but tested as in int
                    if(defined $common_type && $common_type =~ /[IFN]/) {           # Integer, Float, or Numeric - change to scalar
                        $common_type = 's';
                    } elsif(defined $common_type && $common_type =~ / of .$/) {     # like a of S
                        $common_type =~ s/ of .$//;
                    }
                    my $package_name = &Perlscan::unescape_keywords(substr($varname,0,$ld));    # issue s18
                    if(!exists $Packages{$package_name}) {       # issue bootstrap: our package: another program can change the value/type so we can't assume it
                        delete $NeedsInitializing{$subname}{$varname};
                    }
		        }
                $VarType{$varname}{$subname} = $common_type if(defined $common_type);
                if(defined $common_type && $subname ne '__main__' && exists $NeedsInitializing{$subname}{$varname}) {     # SNOOPYJC
                    # $VarType{$varname}{main} = merge_types($varname, $subname, $common_type);        # SNOOPYJC
                    $VarType{$varname}{__main__} = $common_type;            # SNOOPYJC
                    $VarSubMap{$varname}{__main__} = '+';                   # SNOOPYJC
                    if(exists $NeedsInitializing{__main__}{$varname}) {
                        $NeedsInitializing{__main__}{$varname} = $common_type;
                    } else {
                        $NeedsInitializing{__main__}{$varname} = $NeedsInitializing{$subname}{$varname};        # SNOOPYJC
                    }
                    delete $NeedsInitializing{$subname}{$varname};      # SNOOPYJC
                }                                                       # SNOOPYJC
            }
         }
      # SNOOPYJC }
   }
   # issue s127 foreach $subname (keys %NeedsInitializing) {         # SNOOPYJC
   # issue s127     foreach $varname (keys %{$NeedsInitializing{$subname}}) {
   foreach $subname (sort keys %NeedsInitializing) {         # SNOOPYJC, issue s127
       foreach $varname (sort keys %{$NeedsInitializing{$subname}}) {   # issue s127
           # SNOOPYJC: issue bootstrap next if(!exists $VarSubMap{$varname}{$subname});   # if it's not in VarSubMap, then it's a "my" variable, which is handled in pythonizer
	       next if($varname =~ /__dict__$/);
           next if($varname eq 'True' || $varname eq 'False');     # issue s23
           if($varname =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {   # Has to be a valid python var name
               $InitVar{$subname} .= "\n$varname = ".init_val($NeedsInitializing{$subname}{$varname});
           } elsif($varname =~ /^[A-Za-z_][A-Za-z0-9._]*$/) {   # Has a package name
               $::Pyf{_init_global} = 1;
               my $dx = rindex($varname, '.');
               my $packname = substr($varname,0,$dx);
               my $unescaped_packname = &Perlscan::unescape_keywords($packname);        # issue s18
               my $vn = substr($varname, $dx+1);
               my $ig = '_init_global';
               $ig = "$PERLLIB.init_global" if($::import_perllib);
               if(exists $Packages{$unescaped_packname}) {	# Only init if the named package is defined here
               	   $InitVar{$subname} .= "\n$varname = $ig('$packname', '$vn', " .init_val($NeedsInitializing{$subname}{$varname}) . ')';
	           }
           }
        }
    }

   ($::debug) && out("\nDETECTED GLOBAL VARIABLES:");
   foreach $subname (keys %GlobalVar ){
      $GlobalVar{$subname}='global '.substr($GlobalVar{$subname},1);
      ($::debug) && out "\t$subname: $GlobalVar{$subname}";
   }
   ($::debug) && out("\nAUTO-INITIALIZED VARIABLES:");
   foreach $subname (keys %InitVar ){
      ($::debug) && out "\t$subname: $InitVar{$subname}";
      $InitVar{$subname}.="\n";         # Add a blank line at the end
   }
   ($::debug) && out("\nList of local subroutines:");
   ($::debug) && out(join(' ', keys %LocalSub));
   #here we have already populated array Sub2name with the list of subs and $global_list with the list of global variables
   %anonymous_subs_used = ();   # issue s26: Clear it for PASS_2
}

sub init_val            # SNOOPYJC: Get the initializer value for the var, given the type
{
   my $type = shift;

   $type = substr($type,0,1);   # Handle 'h of S' by changing it to 'h'

   my $val = 'None';
   $val = '0' if($type =~ /[IN]/);      # Integer or Number
   $val = '0.0' if($type eq 'F');       # Float
   $val = "''" if($type eq 'S' || $type eq 's');        # String or scalar
   if($type eq 'a') {        # array
       if($::autovivification) {
           $::Pyf{Array} = 1;
           $val = 'Array()';
           $val = "$PERLLIB.Array()" if($::import_perllib);
       } else {
           $val = '[]';
       }
   } elsif($type eq 'h') {        # hash 
       if($::autovivification) {
           $::Pyf{Hash} = 1;
           $val = 'Hash()';
           $val = "$PERLLIB.Hash()" if($::import_perllib);
       } else {
           $val = '{}';
       }
   }
   return $val;
}

sub check_ref           # SNOOPYJC: Check references to variables so we can type them or later initialize them
{
    my $CurSub = shift;
    my $k = shift;      # Points to a scalar, hash, or array name

    my $name = $ValPy[$k];
    my $class;
    my $type = undef;
    my $typ = undef;
    $class = $ValClass[$k];
    if($::debug >= 3) {
        say STDERR "check_ref($CurSub, $name) at $k";
    }

    if(exists $Perlscan::sub_varclasses{$CurSub}{$ValPerl[$k]} && $Perlscan::sub_varclasses{$CurSub}{$ValPerl[$k]} eq 'local') {    # issue s144
        # issue s144: 'local' variables aren't really local
        $CurSub = '__main__' 
    }

    # issue s209: If we are referring to a package variable, then grab the package name and add it to our list of packages, unless
    # we 'use' that package.  This is so we generate an _init_package for that package
    my $dx = rindex($name, '.');
    if($dx != -1) {
        my $packname = &Perlscan::unescape_keywords(substr($name,0,$dx));       # issue s18
        if(!exists $UsePackage{$packname} && !exists $RequirePackage{$packname} && !exists $PYTHON_PACKAGES_SET{$packname} && !exists $Packages{$packname} &&   # issue s18
           $packname !~ /^len\(/ && $packname !~ /^builtins\b/ && 
           $packname !~ /^\(/ && $packname !~ /^\d/ &&
           $packname !~ /^$DEFAULT_MATCH\b/ && $packname !~ /^$PERLLIB\b/) {
            if($packname =~ /^[\w.]+$/) {   # Don't put things like '" ".join(map(str, os.getgrouplist(os.getuid(), os' in %Packages!
                $Packages{$packname} = 2;           # 2 means we reference it but don't define it here
            }
        }
    }

    # Record if we are modifying the loop counter
    if($ValPy[0] ne 'for' && $class eq 's' && 
       (($k != 0 && $ValClass[$k-1] eq '^') || ($k+1 <= $#ValClass && ($ValClass[$k+1] eq '=' || $ValClass[$k+1] eq '^')))) {
# issue s252        my $lc = &Perlscan::get_loop_ctr();        # undef  $i  -or- $i,$j
# issue s252        if(defined $lc) {
# issue s252            my @lcs = split(/,/, $lc);
# issue s252            for $lc (@lcs) {
# issue s252                if($ValPerl[$k] eq $lc) {
                if(&Perlscan::is_loop_ctr($ValPerl[$k])) {      # issue s252
                    &Perlscan::set_loop_ctr_mod($ValPerl[$k]);  # issue s252
                    # issue for logme('W',"Loop counter $lc modified in loop - generated code for 'for' loop may be incorrect");
# issue s252                    last;
                }
# issue s252            }
# issue s252        }
    } elsif($class eq 's' && $k+2 <= $#ValClass && $ValClass[$k+1] eq 'p' && $ValClass[$k+2] eq 'f' &&
        ($ValPerl[$k+2] eq 're' || $ValPerl[$k+2] eq 'tr')) {           # issue s252
        if(&Perlscan::is_loop_ctr($ValPerl[$k])) {      # issue s252
            &Perlscan::set_loop_ctr_mod($ValPerl[$k]);  # issue s252
        }                                               # issue s252
    }                                                   # issue s252

    if($k > 0) {
        if($ValClass[$k-1] eq '^') {      # pre ++ or --
            if($k+1 <= $#ValClass && $ValPerl[$k+1] eq '[') {
                $type = 'a of I';         # ++ $arr[$ndx]
            } elsif($k+1 <= $#ValClass && $ValPerl[$k+1] eq '{') {
                $type = 'h of I';         # ++ $hash{key}
            } else {
                $type = 'I';
            }
            $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
            if($name =~ /^$PERL_ARG_ARRAY\[/) {   # issue s184: NeedsInitializing doesn't work on sub arglist
                $type =~ s/I/m/;        # issue s184
            }                           # issue s184
        } elsif($ValClass[$k-1] eq 'f' && $ValPerl[$k-1] eq 'defined' && &::end_of_variable($k) == $k) {
            # If they are checking if this var is defined, then we have to init it to "None" if
            # we're called on to init it, so set the type to 'm' for "mixed".  This means we
            # need to convert it using _num and _str each time we reference it so we don't get
            # any NoneType exceptions.
            $type = 'm';
	    #$DB::single = 1;
        }
    }

    return if(!$name);

    # issue s262: Handle out parameters on my statements also
    # issue s262 my $cs = &Perlscan::cur_sub();
    my $cs = $CurSub;               # issue s262: If we are in one of our nested subs, we actually want to check the attributes of the parent sub

    if($class eq 's' && $::autovivification && $ValPerl[$k] eq '$_') {      # issue s359: We use .get(...) on _args, so we have to copy them
        set_sub_attribute($cs, 'modifies_arglist', 1);                      # issue s359
        my $sub = &Perlscan::cur_sub();                                     # issue s359: Mark it on the nested sub too
        if(exists $::nested_subs{$sub} && $::nested_subs{$sub} =~ /$PERL_ARG_ARRAY/) {  # issue s359
            set_sub_attribute($sub, 'modifies_arglist', 1);                     # issue s359
        }
    }                                                                       # issue s359

    if($ValClass[$k] eq 's' && $ValPerl[$k] eq '$_' && $ValPy[$k] =~ /^$PERL_ARG_ARRAY/ &&    # issue s184
        (($k-1 >= 0 && $ValClass[$k-1] eq '^') ||  # issue s184: handle ++$_[N] / --$_[N]
        ($ValPy[$k] !~ /\[\d+\]/ && $k+3 <= $#ValClass && $ValClass[$k+1] eq '(' && ($p = matching_br($k+1)) != -1 &&  # vararg
         $p+1 <= $#ValClass && 
         ($ValClass[$p+1] eq '=' || $ValClass[$p+1] eq '^' ||
          ($ValClass[$p+1] eq 'p' && $ValClass[$p+2] eq 'f' && $ValPerl[$p+2] =~ /^(?:re|tr)$/)))	||
        ($k+1 <= $#ValClass && 
       ($ValClass[$k+1] eq '=' ||
        $ValClass[$k+1] eq '^' ||               # issue s184: handle $_[N]++ / $_[N]--
       # issue s151 ($ValClass[$k+1] eq '~' && $ValClass[$k+2] eq 'f' && $ValPerl[$k+2] =~ /^(?:re|tr)$/))	# issue ddts
       ($ValClass[$k+1] eq 'p' && $ValClass[$k+2] eq 'f' && $ValPerl[$k+2] =~ /^(?:re|tr)$/))	# issue ddts, issue s151
    ))) {
        # issue s84 $SubAttributes{$CurSubName}{modifies_arglist} = 1;    # SNOOPYJC: This sub mods it's args
        # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1;    # SNOOPYJC: This sub mods it's args, issue s84
        set_sub_attribute($cs, 'modifies_arglist', 1);    # SNOOPYJC: This sub mods it's args, issue s84, issue s241
        if($ValPy[$k] =~ /\[(\d+)\]/) {                # issue s184
             my $als = 0;                           # issue s184
             # issue s241 $als = $SubAttributes{$cs}{arglist_shifts} if exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arglist_shifts};    # issue s184
             $als = get_sub_attribute($cs, 'arglist_shifts',0,0);   # issue s241
             set_out_parameter($cs, $1+$als);       # issue s184
        } else {        # issue s184: vararg
             set_out_parameter($cs, 'var');          # issue s184
        }
    } elsif($ValClass[$k] eq 's' && $ValPerl[$k] eq '$' && $k+3 <= $#ValClass && $ValClass[$k+1] eq '(' &&
            $ValClass[$k+3] eq ')' && $ValClass[$k+2] eq 's' &&
            (($ValPerl[$k+2] eq '$_' && $ValPy[$k+2] =~ /\[\d+\]$/) ||
                # issue s241 (exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arg_copies} &&
                # issue s241 exists $SubAttributes{$cs}{arg_copies}{$ValPerl[$k+2]})) &&
             (defined get_sub_attribute($cs, 'arg_copies') &&           # issue s241
             exists ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k+2]})) &&   # issue s241
            (($k-1 >= 0 && $ValClass[$k-1] eq '^') ||
             ($k+4 <= $#ValClass &&
              ($ValClass[$k+4] eq '=' ||
               $ValClass[$k+4] eq '^' ||               # issue s184: handle $_[N]++ / $_[N]--
               ($ValClass[$k+4] eq 'p' && $ValClass[$k+5] eq 'f' && $ValPerl[$k+5] =~ /^(?:re|tr)$/))
              ))) {                                 # issue s185
          my $arg;
          if($ValPy[$k+2] =~ /\[(\d+)\]$/) {    # Arg specified
              # issue s241 $SubAttributes{$cs}{modifies_arglist} = 1;     # We store the value here
             set_sub_attribute($cs, 'modifies_arglist', 1);     # We store the value here, issue s241
             my $als = 0;                           # issue s185
             # issue s241 $als = $SubAttributes{$cs}{arglist_shifts} if exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arglist_shifts};    # issue s185
             $als = get_sub_attribute($cs, 'arglist_shifts',0,0);   # issue s241
             $arg = $1 + $als;
          } else {
              # issue s241 $arg = $SubAttributes{$cs}{arg_copies}{$ValPerl[$k+2]}
              $arg = ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k+2]};   # issue s241
          }
          $arg .= 'r';            # Reference
          set_out_parameter($cs, $arg);         # issue s185
    } elsif($ValClass[$k] eq 's' && defined $ValType[$k] && $ValType[$k] eq  'ss' &&
        # issue s241 exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arg_copies} &&
        # issue s241 exists $SubAttributes{$cs}{arg_copies}{$ValPerl[$k]} &&
         defined get_sub_attribute($cs, 'arg_copies') &&
         exists ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k]} &&
        (($k-1 >= 0 && $ValClass[$k-1] eq '^') ||
         ($k+1 <= $#ValClass &&
          ($ValClass[$k+1] eq '=' ||
           $ValClass[$k+1] eq '^' ||               # issue s184: handle $_[N]++ / $_[N]--
           ($k+2 <= $#ValClass && $ValClass[$k+1] eq 'p' && $ValClass[$k+2] eq 'f' && $ValPerl[$k+2] =~ /^(?:re|tr)$/))
    ))) {                                                   # issue s185
        # issue s241 my $arg = $SubAttributes{$cs}{arg_copies}{$ValPerl[$k]};
        my $arg = ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k]};    # issue s241
        $arg .= 'r';            # Reference
        set_out_parameter($cs, $arg);         # issue s185
    }

    if($k+1 <= $#ValClass) {
        if($ValClass[$k+1] eq '=') {
            my $cs = &Perlscan::cur_sub();      # issue s185
            # issue s241 if(exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arg_copies} &&
            # issue s241 exists $SubAttributes{$cs}{arg_copies}{$ValPerl[$k]} && $ValType[$k] ne 'ss') {      # issue s185
            if(defined get_sub_attribute($cs, 'arg_copies') &&
               exists ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k]} && $ValType[$k] ne 'ss') {      # issue s185
               # issue s241 delete $SubAttributes{$cs}{arg_copies}{$ValPerl[$k]};        # issue s185: No longer a copy if we change it
               delete ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k]};        # issue s185: No longer a copy if we change it, issue s241
            }                                                               # issue s185
            my $lim = $#ValClass;
            if($k-1 >= 0 && $ValClass[$k-1] eq '(') {   # parens around assignment - stop at the )
                $lim = matching_br($k-1)-1;
                # issue s151 if($lim+3 <= $#ValClass && $ValClass[$lim+2] eq '~' && $ValClass[$lim+3] eq 'f' &&
                if($lim+3 <= $#ValClass && $ValClass[$lim+2] eq 'p' && $ValClass[$lim+3] eq 'f' &&  # issue s151
                    ($ValPerl[$lim+3] eq 're' || $ValPerl[$lim+3] eq 'tr')) {
                    # issue s8: ($my_c = $my_a) =~ s/3/1/; where $k is pointing at $my_c - 
                    # here $my_c is set to be the string result of the substitution or
                    # translation, not a copy of $my_a.
                    $type = 'S';                # issue s8
                }
            }
            my $semi = next_same_level_token(';', $k+2, $lim);  # like for($i=0; ...)
            $lim = $semi-1 if($semi != -1);
            my $el = next_lower_or_equal_precedent_token('=', $k+2, $lim);
            if($el != -1) {
                if($ValClass[$el] eq '=') {     # Chain assignment - find the last one
                    my $last_eq = rindex($TokenStr, '=');
                    $k = $last_eq-1;
                    $el = next_lower_or_equal_precedent_token('=', $k+2, $lim);
                    $lim = $el-1 if($el != -1);
                } else {
                    $lim = $el-1;
                }
            }
            $type = expr_type($k+2, $lim, $CurSub) if(!defined $type);  # issue s8
            if($class eq 'a' && $type !~ / of /) {
	        # issue s98 $type = "a of ".$type;
                $type = "a of m";		# issue s98
            } elsif($class eq 'h' && $type !~ / of /) {
	        # issue s98 $type = "h of ".$type;
                $type = "h of m";		# issue s98
            }
            #$type = 'm' if($type eq 'u');       # If we don't know the type, can no longer assume anything
            if($ValClass[$k] eq 'a' && (!defined $type || $type !~ /^a/)) { # issue s356
                $type = 'a';                                                # issue s356
            }  elsif($ValClass[$k] eq 'h' && (!defined $type || $type !~ /^h/)) { # issue s356
                $type = 'h';                                                # issue s356
            }                                                               # issue s356
            my $op = $ValPerl[$k+1];
            if($op eq '=') {     # e.g. not +=
                if($name =~ /^\(len\((.*)\)-1\)$/) {            # issue s93: $#myArray = ...
                    $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
                }                                               # issue s93
                $initialized{$CurSub}{$name} = $type unless(is_referenced($ValClass[$k], $name, $k+2) || &Perlscan::in_conditional($k) ||
                                                            &Perlscan::cur_sub() ne $CurSub);       # issue s277
            } elsif($op eq '.=') {
                $type = 'S';
                $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
                if($name =~ /^$PERL_ARG_ARRAY\[/) {   # issue s184: NeedsInitializing doesn't work on sub arglist
                    $type = 'm';            # issue s184
                }                           # issue s184
            } else {                # +=, -=, *=, /=, |=, &=
                $type = 'N' unless($type eq 'I' || $type eq 'F');        # numeric
                $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
                if($name =~ /^\(len\((.*)\)-1\)$/) {            # issue s93: $#myArray = ...
                    $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
                }                                               # issue s93
                if($name =~ /^$PERL_ARG_ARRAY\[/) {   # issue s184: NeedsInitializing doesn't work on sub arglist
                    $type = 'm';            # issue s184
                }                           # issue s184
            }
        } elsif($ValClass[$k+1] eq '^') {   # ++ or --
            $type = 'I';
            $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
            if($name =~ /^\(len\((.*)\)-1\)$/) {            # issue s93: $#myArray = ...
                $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
            }                                               # issue s93
            if($name =~ /^$PERL_ARG_ARRAY\[/) {   # issue s184: NeedsInitializing doesn't work on sub arglist
                $type = 'm';            # issue s184
            }                           # issue s184
        # issue s151 } elsif($ValClass[$k+1] eq '~' && $k+2 <= $#ValClass && $ValClass[$k+2] eq 'f' &&
        } elsif($ValClass[$k+1] eq 'p' && $k+2 <= $#ValClass && $ValClass[$k+2] eq 'f' &&   # issue s151
            ($ValPerl[$k+2] eq 're' || $ValPerl[$k+2] eq 'tr') && index($ValPy[$k+2], 're.R') < 0) {    # issue s8
            # This is a s or tr operation, which both reads and changes the result (into a string)
            $type = 'S';
            $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
            if($name =~ /^$PERL_ARG_ARRAY\[/) {   # issue s184: NeedsInitializing doesn't work on sub arglist
                $type = 'm';            # issue s184
            }                           # issue s184
        } elsif(!defined $type) {
            $m = next_same_level_token(')', $k, $#ValClass); 
            #say STDERR "m = $m";
            if($m != -1 && $ValPerl[$m] eq ')' && $m < $#ValClass && $ValClass[$m+1] eq '=') {        # like ($v1, $v2) = RHS;
                my $cs = &Perlscan::cur_sub();      # issue s185
                # issue s241 if(exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arg_copies} &&
                # issue s241 exists $SubAttributes{$cs}{arg_copies}{$ValPerl[$k]} && $ValType[$k] ne 'ss') {      # issue s185
                if(defined get_sub_attribute($cs, 'arg_copies') &&
                    exists ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k]} && $ValType[$k] ne 'ss') {      # issue s185
                    # issue s241 delete $SubAttributes{$cs}{arg_copies}{$ValPerl[$k]};        # issue s185: No longer a copy if we change it
                    delete ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k]};        # issue s185: No longer a copy if we change it, issue s241
                }                                                               # issue s185
                $rhs_type = expr_type($m+2, $#ValClass, $CurSub);
                if($rhs_type =~ /^a of (.*)$/) {            # like a of S
                    $type = $1;
                } else {
                    $type = 'm';
                }
		        if($ValClass[$k] eq 'a') {		# issue s95
		            $type = 'a';			# issue s95
	            } elsif($ValClass[$k] eq 'h') {		# issue s95
		            $type = 'h';			# issue s95
	            }
                $initialized{$CurSub}{$name} = $type unless(&Perlscan::in_conditional($k));
            }
        }
    }
    if(($k == 1 || ($k == 2 && $ValClass[1] eq 't')) && $ValClass[0] eq 'c' && $ValPy[0] eq 'for' && $k+1 <= $#ValClass) {  # Var in a foreach loop is initialized, issue s177: Handle foreach @_;
        $type = expr_type($k+1, $#ValClass, $CurSub);
        $type = 's' if($type eq 'a' || $type eq 'h');           # We don't know a of what?
        $type =~ s/^a of //;
        $initialized{$CurSub}{$name} = $type unless($k == 1 && &Perlscan::in_conditional($k));
    } elsif(($k >=1 && $ValClass[$k-1] eq 'f' && ($ValPerl[$k-1] eq 'open' || $ValPerl[$k-1] eq 'opendir')) ||  # open $fh
           ($k >=2 && $ValClass[$k-1] eq '(' && $ValClass[$k-2] eq 'f' && ($ValPerl[$k-2] eq 'open' || $ValPerl[$k-2] eq 'opendir'))  ||  # open($fh
           ($k >=3 && $ValClass[$k-1] eq 't' && $ValClass[$k-2] eq '(' && $ValClass[$k-3] eq 'f' && ($ValPerl[$k-3] eq 'open' || $ValPerl[$k-3] eq 'opendir'))) { # open(my $fh
        $type = 'H';
        $initialized{$CurSub}{$name} = $type if($ValClass[$k-1] eq 't' || !&Perlscan::in_conditional($k));
        if(&Perlscan::is_loop_ctr($ValPerl[$k])) {      # issue s252
            &Perlscan::set_loop_ctr_mod($ValPerl[$k]);  # issue s252
        }                                               # issue s252
    } elsif($ValClass[0] eq 't' && ($ValPerl[0] eq 'my' || $ValPerl[0] eq 'local' || $ValPerl[0] eq 'state') &&
            being_declared_here($k) &&                                                  # issue bootstrap: make sure this isn't on the RHS of the = (if any)
            !exists $initialized{$CurSub}{$name} && !&Perlscan::in_conditional($k)) {   # issue s10
        $initialized{$CurSub}{$name} = (defined $type ? $type : 'u');                   # issue s10
    }

    if(defined $type) {
        #if($ValClass[$k] =~ /^[ah]/) {                  # issue s356
        #$NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});        # issue s356
        #}                                               # issue s356
        $VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type, $k);      # issue s356
        $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
        if($name =~ /^\(len\((.*)\)-1\)$/) {            # issue s93: $#myArray
            $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
        } elsif($name =~ /^len\((.*)\)$/) {             # issue s93: scalar(@myArray)
            $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
        }                                               # issue s93
    }
    if($class eq 's' && $k+1 <= $#ValClass && $ValClass[$k+1] eq '(' && $ValPerl[$k+1] ne '(') {     # Being subscripted
        $class = (($ValPerl[$k+1] eq '{') ? 'h' : 'a');
        $NeedsInitializing{$CurSub}{$name} = $class if(!exists $initialized{$CurSub}{$name});
        my $rhs_type = undef;
        if(defined $type) {
            $rhs_type = $type;
        }
        $type = undef;
        my $p = $k+1;
        while($ValClass[$p] eq '(') {
            $class = (($ValPerl[$p] eq '{') ? 'h' : 'a');
            if(defined $type) {
                $type .= " of $class";
            } else {
                $type = $class;
            }
            my $q = matching_br($p);
            last if $q < 0;
            $p = $q+1;
            last if($p > $#ValClass);
        }
        if($p <= $#ValClass) {
            if($ValClass[$p] eq '=') {
                $rhs_type = expr_type($p+1, $#ValClass, $CurSub);
            } elsif($ValClass[$p] eq '^') {
                if(exists $VarType{$name} && exists $VarType{$name}{$CurSub}) {
                    # We can't set this type if it doesn't have one because we read the
                    # value before setting it.  Test case in test_regex.pl with main.chars
                    $rhs_type = 'I';
                }
            # issue s151 } elsif($ValClass[$p] eq '~') {
            } elsif($ValClass[$p] eq 'p') {     # issue s151
                $rhs_type = 'S';
            } elsif(index(')x*/%+-.HI>&|0r?:,Ao"', $ValClass[$p]) >= 0) {
                return;         # Just a reference to the array
            }
        } elsif($k-1 >= 0 && $ValClass[$k-1] eq 'f' && ($ValPerl[$k-1] eq 'chop' || $ValPerl[$k-1] eq 'chomp')) {   # issue s148
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, "$type of S", undef, $class);    # issue s356
        } elsif($k-2 >= 0 && $ValClass[$k-1] eq '(' && $ValClass[$k-2] eq 'f' && ($ValPerl[$k-2] eq 'chop' || $ValPerl[$k-2] eq 'chomp')) { # issue s148
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, "$type of S", undef, $class);    # issue s356
        } else {
            return;             # Just a reference to the array
        }
	    # issue s98 if(defined $rhs_type) {
	    # issue s98     $VarType{$name}{$CurSub} = merge_types($name, $CurSub, "$type of $rhs_type");
	    # issue s98 } else {
        $VarType{$name}{$CurSub} = merge_types($name, $CurSub, "$type of m", undef, $lcass);
        # issue s98 }
   } elsif($class eq 's' && $k-1 >= 0 && $ValClass[$k-1] eq 'f' && ($ValPerl[$k-1] eq 'chop' || $ValPerl[$k-1] eq 'chomp')) {       # issue s148
        $VarType{$name}{$CurSub} = merge_types($name, $CurSub, 'S');
   } elsif($class eq 's' && $k-2 >= 0 && $ValClass[$k-1] eq '(' && $ValClass[$k-2] eq 'f' && ($ValPerl[$k-2] eq 'chop' || $ValPerl[$k-2] eq 'chomp')) { # issue s148
        $VarType{$name}{$CurSub} = merge_types($name, $CurSub, 'S');
   } elsif($class eq 'a' || $class eq 'h') {    # e.g. if(@arr) or if(%hash) or push @arr, ...
       $type = $class;
       if($k-1 >= 0 && $ValClass[$k-1] eq 'f' && ($ValPerl[$k-1] eq 'push' || $ValPerl[$k-1] eq 'unshift') && $k+2 <= $#ValClass) {
            $type = expr_type($k+2, $#ValClass, $CurSub);
            $type = "$class of $type";
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type, undef, $class);   # issue s356
        } elsif($k-2 >= 0 && $ValClass[$k-1] eq '(' && $ValClass[$k-2] eq 'f' && ($ValPerl[$k-2] eq 'push' || $ValPerl[$k-2] eq 'unshift') && $k+2 <= $#ValClass) {
            my $match = matching_br($k-1);
            $type = expr_type($k+2, $match-1, $CurSub);
            $type = "$class of $type";
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type, undef, $class);   # issue s356
        } elsif($k-1 >= 0 && $ValClass[$k-1] eq 'f' && ($ValPerl[$k-1] eq 'chop' || $ValPerl[$k-1] eq 'chomp')) {       # issue s148
            $type = "$class of S";
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type, undef, $class);   # issue s356
        } elsif($k-2 >= 0 && $ValClass[$k-1] eq '(' && $ValClass[$k-2] eq 'f' && ($ValPerl[$k-2] eq 'chop' || $ValPerl[$k-2] eq 'chomp')) { # issue s148
            $type = "$class of S";
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type, undef, $class);   # issue s356
        # issue s93 } elsif(substr($ValPy[$k],0,4) eq 'len(') {
        } elsif($name =~ /^\(len\((.*)\)-1\)$/) {            # issue s93: $#myArray
            $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
	        $type = 'I';                                # issue s93
        } elsif($name =~ /^len\((.*)\)$/) {             # issue s93: scalar(@myArray)
            $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
	        $type = 'I';                                # issue s93
        }                                               # issue s93
	    # issue s93 $type = 'I';
        # issue s93 }
        $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
        $VarType{$name}{$CurSub} = $type if(!exists $VarType{$name} || !exists $VarType{$name}{$CurSub});
   } elsif(($typ = expr_type($k, $k, $CurSub)) && $typ ne 's') {
        if($name =~ /^\(len\((.*)\)-1\)$/) {            # issue s93: $#myArray
            $NeedsInitializing{$CurSub}{$1} = 'a' if(!exists $initialized{$CurSub}{$1});        # issue s93
        }
        $NeedsInitializing{$CurSub}{$name} = $typ if(!exists $initialized{$CurSub}{$name});
   } elsif(!defined $type) {                            # Scalar reference - try to find what type it needs to be
        $type = scalar_reference_type($k);
        if($::debug >= 3) {
            say STDERR "scalar_reference_type($k) = $type";
        }
        # Don't override an assigned type with a referenced type, since normally
        # we will change references to use _num() or _str(), but if this var
        # is not initialized, then we can set it's type here, e.g. if it's used as an array ref.
        #
        # Actually, this causes more problems than it's worth by setting wrong types of things
        # which omit conversion functions!
        #if(!exists $VarType{$name}{$CurSub} || $VarType{$name}{$CurSub} eq 'u') {
        #$VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type);
        #}
        if(!exists $NeedsInitializing{$CurSub}{$name}) {
            $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
        }
    }
}

sub is_referenced
# Is this variable referenced on the RHS of this assignment?
{
    my $class = shift;
    my $name = shift;
    my $k = shift;

    for(my $i = $k; $i <= $#ValClass; $i++) {
        return 0 if($ValClass[$i] eq ';');              # End of this part of for loop init
        return 1 if($ValClass[$i] eq $class && $ValPy[$i] eq $name);
    }
    
    return 0;
}

sub scalar_reference_type       # given a reference to a scalar, try to infer the type of the scalar
{
    my $k = shift;

    my $prev = '';
    my $next = '';
    $prev = $ValClass[$k-1] if($k != 0);
    $next = $ValClass[$k+1] if($k+1 <= $#ValClass);

    # First see if this is a hash key or array subscript

    if($prev eq '(' && $next eq ')') {
        if($ValPerl[$k-1] eq '[') {
            return 'I';
        } elsif($ValPerl[$k-1] eq '{') {
            return 'S';
        }
    }
    
    # Now see if this is a function argument which may not be in parens
    for(my $i = $k-1; $i >= 0; $i--) {
        if($ValClass[$i] eq ')') {
            $i = reverse_matching_br($i);
        } elsif($ValClass[$i] eq 'f') {
            my $fname = $ValPerl[$i];
            my $pname = $ValPy[$i];
            if($ValClass[$i+1] eq '(') {
                my $q = matching_br($i+1);
                last if($k > $q);               # not in the parens like f(...)..k..
                $i++;
            }
            # Figure out which arg of the function this is: note some functions the first arg
            # is not separated from the second arg with spaces
            if($k == $i+1) {
                $arg = 0;           # That was easy
            } else {
                $arg = 1;
                my $j = $i+2;
                $j++ if($j <= $k && $ValClass[$j] eq ',');
                for( ; $j<=$k; $j++) {
                    last if($k == $j);
                    $arg++ if($ValClass[$j] eq ',');
                    #$j = matching_br($j) if($ValClass[$j] eq '(');
                    $j = &::end_of_variable($j);
                    return 'u' if($j < 0);
                }
            }
            my $ty = arg_type($fname, $pname, $arg);
            if($::debug > 3) {
                say STDERR "arg_type($fname, $pname, $arg) = $ty";
            }
            return $ty if(defined $ty && $ty !~ /[ah]/);
            last;
        } elsif($ValClass[$i] eq 'c') {         # .... if(... v ...);
            last;
        }
    }

    my $p = $k-1;
    my $n = $k+1;
    my $op = '';
    if($k-2 >= 0 && $ValClass[$k-1] eq '(') {
        $p--;
        $prev = $ValClass[$p];
    }
    $op = $prev if(index(">+-*/%0o.", $prev) >= 0);
    $m = $p;
    if($k+2 <= $#VarClass && $ValClass[$k+1] eq ')') {
        $n++;
        $next = $ValClass[$n];
    }
    if(index(">+-*/%0o.", $next) >= 0) {
        $op = $next;
        $m = $n;
    }
    if($op eq '.') {
        return 'S';
    } elsif($op eq '>') {     # could be like < or like lt
        return 'S' if($ValPerl[$m] =~ /^[a-z][a-z]$/);  # like eq, gt, etc
        return 'I';     # boolean is an Int in perl
    } elsif($op ne '') {
        return 'N';         # Numeric
    }
    return 's';         # Unknown scalar
}

sub in_sub_call                           # SNOOPYJC
# If this token is a sub arg, return true
{
    my $k = shift;

    my ($i, $arg);

    for($i = $k-1; $i >= 0; $i--) {     # issue s3
        if($ValClass[$i] eq '(') {
           if($i-1 >= 0 && $ValClass[$i-1] eq 'i') {
               my $q = matching_br($i);
               return 1 if($q == -1);           # issue bootstrap - maybe we didn't scan that far yet
               return 0 if($k > $q);            # not in the parens list i(...)..k..
               return 1;
           }
           return 0;
        } elsif($ValClass[$i] eq 'i' && $LocalSub{$ValPy[$i]}) {
            return 1;
        } elsif($ValClass[$i] eq 'i' && $i-1 >= 0 && $ValClass[$i-1] eq 'D') {  # issue s205: Method call
            return 1;                       # issue s205
        } elsif($ValClass[$i] eq ')') {
            $i = reverse_matching_br($i);
            return 0 if($i < 0);
	        $i++;	# issue bootstrapping: Process the '(' next
        } elsif($ValClass[$i] eq '=' && $ValPy[$i] ne ':=') {
            return 0;
        }
    }
    return 0;
}

=pod
sub arg_type_from_pos                           # SNOOPYJC
# If this token is a function arg, return what arg type it is, else return 'u'
{
    my $k = shift;

    my ($i, $arg);

    for($i = $k; $i >= 0; $i--) {
        if($ValClass[$i] eq '(') {
           if($i-1 >= 0 && $ValClass[$i-1] eq 'f') {
              $i--;
              last;
           }
           return 'u';
        } elsif($ValClass[$i] eq 'f' && $i != $k) {
            last;
        } elsif($ValClass[$i] eq ')') {
            $i = reverse_matching_br($i);
            return 'u' if($i < 0);
        # issue s48 } elsif($ValClass[$i] eq '=' && $ValPy[$i] ne ':=') {
        # issue s48 return 'u';
        }
    }
    return 'u' if($i < 0 || $ValClass[$i] ne 'f');
    my $fname = $ValPerl[$i];
    my $pname = $ValPy[$i];
    if($ValClass[$i+1] eq '(') {
        my $q = matching_br($i+1);
        return 'u' if($k > $q);               # not in the parens like f(...)..k..
        $i++;
    }
    # Figure out which arg of the function this is: note some functions the first arg
    # is not separated from the second arg with spaces
    if($k == $i+1) {
        $arg = 0;           # That was easy
    } else {
        $arg = 1;
        my $j = $i+2;
        $j++ if($j <= $k && $ValClass[$j] eq ',');
        for( ; $j<=$k; $j++) {
            last if($k == $j);
            $arg++ if($ValClass[$j] eq ',');
            #$j = matching_br($j) if($ValClass[$j] eq '(');
            $j = &::end_of_variable($j);
            return 'u' if($j < 0);
        }
    }
    my $ty = arg_type($fname, $pname, $arg);
    if($::debug > 3) {
        say STDERR "arg_type_from_pos($k): ($fname, $pname, $arg) = $ty";
    }
    return $ty;
}
=cut

sub arg_type_from_pos           # issue s48 - split up this function into 2
{
    my ($fname, $pname, $arg) = arg_from_pos($_[0], 0);
    my $ty = arg_type($fname, $pname, $arg);
    if($::debug > 3) {
        no warnings 'uninitialized';
        say STDERR "arg_type_from_pos($k): ($fname, $pname, $arg) = $ty";
    }
    return $ty;
}

sub arg_from_pos                           # issue s48
# If this token is a function arg, return which arg of which function it is, 
# returning ($perlName, $pyName, $arg#) else return (undef, undef, undef).  Arg# counts from 0.
{
    my $k = shift;
    my $quiet = (scalar(@_) > 0 ? $_[0] : 0);

    my ($i, $arg);

    for($i = $k; $i >= 0; $i--) {
        if($ValClass[$i] eq '(') {
           if($i-1 >= 0) {
              if($ValClass[$i-1] eq 'f') {
                 $i--;
                 last;
              } elsif($ValClass[$i-1] eq 'i') {     # issue s205: Sub call
                  return (undef, undef, undef);
              } elsif($ValPerl[$i-1] eq '}') {      # issue s205
                  my $j = reverse_matching_br($i-1);
                  if($j-1 >= 0 && $ValPerl[$j-1] eq '&') {  # object being cast as a sub
                     return (undef, undef, undef);
                  }
              }
           }
           # issue s48 return (undef, undef, undef);
        } elsif($ValClass[$i] eq 'f' && $i != $k) {
            last;
        } elsif($ValClass[$i] eq ')') {
            $i = reverse_matching_br($i);
            return (undef, undef, undef) if($i < 0);
        # issue s48 Handle chomp(my @tester=<FH>)
        # issue s48 } elsif($ValClass[$i] eq '=' && $ValPy[$i] ne ':=') {
        # issue s48 return (undef, undef, undef);
        }
    }
    return (undef, undef, undef) if($i < 0 || $ValClass[$i] ne 'f');
    my $fname = $ValPerl[$i];
    my $pname = $ValPy[$i];
    if($ValClass[$i+1] eq '(' && $ValPerl[$i+1] eq '(') {       # issue s48: not like map {...} a
        my $q = matching_br($i+1);
        return (undef, undef, undef) if($k >= $q);              # not in the parens like f(...)..k.. or pointing to the close paren
        return (undef, undef, undef) if($k == $i+1);            # not IN the parens if we ARE at the parens
        $i++;
    }
    # Figure out which arg of the function this is: note some functions the first arg
    # is not separated from the second arg with spaces
    if($k == $i+1) {
        $arg = 0;           # That was easy
    } else {
        $arg = 1;
        # issue s184 my $j = $i+2;
        my $j = ($ValClass[$i+1] eq 'f' ? end_of_function($j) : &::end_of_variable($i+1))+1;      # issue s184
        # issue s271 $j++ if($j <= $k && $ValClass[$j] eq ',');
        $j++ if($j <= $k && ($ValClass[$j] eq ',' || $ValClass[$j] eq 'A'));    # issue s271
        for( ; $j<=$k; $j++) {
            last if($k == $j);
            # issue s271 $arg++ if($ValClass[$j] eq ',');
            $arg++ if($ValClass[$j] eq ',' || $ValClass[$j] eq 'A');    # issue s271
            $arg++ if($ValClass[$j] eq ')' and $ValPerl[$j] eq '}');    # issue s48: like map {...} a
            #$j = matching_br($j) if($ValClass[$j] eq '(');
            $j = &::end_of_variable($j);
            return (undef, undef, undef) if($j < 0);
        }
    }
    if(!$quiet && $::debug > 3) {
        say STDERR "arg_from_pos($k) = ($fname, $pname, $arg)";
    }
    return ($fname, $pname, $arg);
}

sub arg_type            # Given the name of a built-in function, and the arg#, return the required type
{
    my $fname = shift;          # Perl name
    my $name = shift;           # Python name
    my $arg = shift;
    my $repeat = (scalar(@_) > 0 ? $_[0] : 1);  # Flag to repeat the last arg if we run out - default = True
    my $return_optional = (scalar(@_) > 1 ? $_[1] : 0); # Flag to return if the next arg is optional or not, issue s246

    return 'u' if(!defined $fname);             # issue s48
    my $ft = undef;
    if(exists $PyFuncType{$name}) {
        $ft = $PyFuncType{$name};
	#say STDERR "PyFuncType{$name} = $ft";           # TEMP
    } elsif(exists $FuncType{$fname}) {
        $ft = $FuncType{$fname};
	#say STDERR "FuncType{$name} = $ft";             # TEMP
    }
    return 's' if(!defined $ft);
    my $argc = 0;
    for(my $i = 0; $i < length($ft); $i++) {
        my $c = substr($ft,$i,1);
        # issue s48 return 's' if($c eq ':');       # We reached the end
        if($c eq ':') {         # issue s48: return the last arg type if we have more than there are
            if($repeat) {       # issue s48
                $c = substr($ft,$i-1,1);
                return $c if $c ne '?';     # Skip the "optional" indicator if present
                return substr($ft,$i-2,2) if $return_optional;
                return substr($ft,$i-2,1);
            }
            return '';
        }
        if($c eq 'H' && substr($ft,$i+1,1) eq '?' && $arg != 0) {	# issue s101
            $i++;
            $argc++;
            next;
        }
        next if($c eq '?');
        if($argc == $arg) {
            if($return_optional && substr($ft,$i+1,1) eq '?') { # issue s48
                return "$c?";
            }
            return $c;
        }
        # issue s48 if($c eq 'a') {
            # SNOOPYJC return 's';                 # unknown scalar
            # issue s48 return 'a';         # SNOOPYJC: Needed for scalar/list context
        # issue s48 }
        $argc++;
    }
    return undef;                 # probably not part of this function
}

sub merge_types         # SNOOPYJC: Merge type of object when we get new info
{
    my $name = shift;
    my $CurSub = shift;
    my $type = shift;
    my $pos = (scalar(@_) ? $_[0] : undef);         # issue s356
    my $class = (scalar(@_) > 1 ? $_[1] : undef);   # issue s356: Specify one or the other

    if($::debug >= 3) {
        no warnings 'uninitialized';
        say STDERR "merge_types($name, $CurSub, $type, $pos, $class)";
    }

    my $new_type = $type;		# issue s116
    if(!defined $type) {
        $type = 's';
    }
    my $otype;                      # issue s356
    if($type ne 'H' && &Perlscan::in_conditional(0)) {          # issue s356, issue s357
        if(!exists $VarType{$name} || !exists $VarType{$name}{$CurSub}) {   # issue s356
            if(exists $NeedsInitializing{$CurSub}{$name} && 
               $NeedsInitializing{$CurSub}{$name} =~ /^[ah]/) { # issue s356
                $otype = $NeedsInitializing{$CurSub}{$name};    # issue s356
            } elsif(exists $initialized{$CurSub}{$name}) {   # issue s356
                $otype = $initialized{$CurSub}{$name};  # issue s356
            } elsif(defined $pos && $ValClass[$pos] =~ /^[ah]/) {       # issue s356
                return $type;                           # issue s356
            } elsif(defined $class && $class =~ /^[ah]/) {              # issue s356
                return $type;                           # issue s356
            } elsif(declared_in_statement($name)) {     # issue s362
                return $type;                           # issue s362
            } else {                                    # issue s356
                $otype = 'u';       # issue s356: undefined
            }
        } else {                      # issue s356
            $otype = $VarType{$name}{$CurSub};      # issue s356
        }
    } else {                    # issue s356
        if(!exists $VarType{$name}) {
            return $type;
        }
        if(!exists $VarType{$name}{$CurSub}) {
            return $type;
        }
        $otype = $VarType{$name}{$CurSub};
    }
    if($::debug >= 3) {
        say STDERR "merge_types: otype=$otype";
    }
    # issue s116 if($otype eq 's') {         # scalar - treat like we have no info yet
    # issue s116 return $type;
    # issue s116 }
    # issue s116 if($type eq 's') {
    # issue s116 return $otype;
    # issue s116 }
    if(!defined $new_type) {		# issue s116
        return $otype;			# issue s116
    }					# issue s116
    return $type if($type eq $otype);   # Same type
    if(($otype eq 'a' || $otype eq 'h') && $type =~ /$otype of/) {
        return $otype;           # we have more specific info - must stick to the less specific
    }
    if(($type eq 'a' || $type eq 'h') && $otype =~ /$type of/) {
        return $type;           # we have less specific info - stick with it
    }
    if(($otype =~ /[ah] of/) && ($type =~ /[ah] of/)) {
        @olist = split / of /,$otype;
        @list = split / of /,$type;
        my $len = (scalar(@olist) >= scalar(@list) ? scalar(@list) : scalar(@olist));
        for(my $i = 0; $i < $len; $i++) {
            if($list[$i] ne $olist[$i]) {
                # SNOOPYJC if($list[$i] eq 's') {          # Was undef, now defined
                # SNOOPYJC     return join(' of ', @olist);
                # SNOOPYJC } elsif($olist[$i] eq 's') {
                # SNOOPYJC     return join(' of ', @list);
                # SNOOPYJC }
                $list[$i] = 'm';                # mixed type
                $#list = $i;                    # chop it there
                return join(' of ', @list);
            }
        }
        if(scalar(@olist) > scalar(@list)) {
            return join(' of ', @olist);        # we knew more before
        }
        return join(' of ', @list);
    } elsif($otype =~ /[ah] of/) {
        return 'm';                 # mixed type
    } elsif($type =~ /[ah] of/) {
        return 'm';                 # mixed type
    } elsif(($otype eq 's') && ($type =~ /[NIFSH]/)) {        # more specific type
        # issue s116 return $type;
        return $otype;		# issue s116: less specific type wins
    } elsif($otype eq 'N' && ($type =~ /[IFB]/)) {   # Numeric -> Int or Float or Boolean issue s124
        # issue s116 return $type;
        return $otype;		# issue s116
    } elsif($type eq 'N' && ($otype =~ /[IFB]/)) {   # Numeric -> Int or Float or Boolean issue s124
        # issue s116 return $otype;
        return $type;		# issue s116
    } elsif(($type =~ /[IF]/) && ($otype =~ /[IF]/)) {  # int vs float
        return 'F';             # Float wins
    } elsif(($type =~ /[BI]/) && ($otype =~ /[BI]/)) {  # int vs boolean issue s124
        return 'I';             # Int wins  issue s124
    } elsif(($type =~ /[BF]/) && ($otype =~ /[BF]/)) {  # float vs boolean issue s124
        return 'F';             # Float wins  issue s124
    } elsif($type eq 's') {
        return $type;
    }
    return 'm';         # Mixed
}

sub _expr_type           # Attempt to determine the type of the expression
# a=Array, h=Hash, s=Scalar, I=Integer, F=Float, N=Numeric, S=String, u=undef, f=function, H=FileHandle, ?=Optional, m=mixed, R=regex, B=bool, C=coderef
{
    my $k = shift;
    my $e = shift;
    my $CurSub = shift;

    my $class = $ValClass[$k];
    if($::debug >= 3) {
        say STDERR "expr_type($k, $e, $CurSub)";
    }
    if($PassNo == PASS_1) {
        for(my $p=$k; $p <= $e; $p++) {
            if($ValClass[$p] eq 'c' && $p != 0) {   # e.g. $i = 2 if(...) - stop at the 'if'
                return expr_type($k, $p-1, $CurSub) if($k <= $p-1);
            }
        }
    }
    if($class eq 'f' && end_of_function($k) >= $e) {         # built-in function call, issue s151
        if($k+1 <= $#ValClass) {
            if($ValPerl[$k] =~ /sort/) {
                if($ValPerl[$k+1] eq '{') {
                    my $ep = matching_br($k+1);
                    return expr_type($ep+1, $e, $CurSub) if($ep>$k && $ep+1 <= $e);
                } elsif($ValClass[$k+1] eq 'i' || ($ValClass[$k+1] eq 'f' && func_type($ValPerl[$k+1], $ValPy[$k+1]) eq 'I')) { # sort f a, but not sort keys h
                    return expr_type($k+2, $e, $CurSub) if($k+2 <= $e);
                } else {                                # sort a
                    return expr_type($k+1, $e, $CurSub) if($k+1 <= $e);
                }
            } elsif($ValPerl[$k] =~ /map/) {
                if($ValClass[$k+1] =~ /[fi]/) {      # map f a
                    return 'a of ' . expr_type($k+1, $k+1, $CurSub);
                }
            } elsif($ValPerl[$k] =~ /reverse/) {
                return 'S' if(substr($ValPy[$k],0,1) eq '_');   # _reverse: scalar context
                return expr_type($k+1, $e, $CurSub) if($k+1 <= $e);
            } elsif($ValPerl[$k] eq '_assign_global' && $ValClass[$k+1] eq '(') {
                # _assign_global('package', 'var', expr) => return the type of the expr
                my $close = matching_br($k+1);
                my $comma = next_same_level_token(',', $k+2, $close);
                $comma = next_same_level_token(',', $comma+1, $close);
                if($comma > $k && $close > $k) {
                    return expr_type($comma+1, $close-1, $CurSub);
                }
            }
        }
        return func_type($ValPerl[$k], $ValPy[$k]);
    } elsif($k == $e) {      # we have one thing
        if($class eq 'd') {             # Digits
            if($ValPy[$k] =~ /^(?:0[bo])?\d+$/ || $ValPy[$k] =~ /^0x[A-Fa-f0-9]+$/) {   # issue s69
                return 'I';             # Integer
            }
            return 'F';                 # Float
        } elsif($class eq 's') {        # Scalar
            if(defined $ValType[$k]) {          # issue s316
                return 'a' if $ValType[$k] eq '@s'; # issue s316
                return 'h' if $ValType[$k] eq '%s'; # issue s316
            }                                   # issue s316
            return $VarType{$ValPy[$k]}{$CurSub} if(exists $VarType{$ValPy[$k]} && exists $VarType{$ValPy[$k]}{$CurSub});
            my $v = substr($ValPerl[$k], 1);
            if(exists $Perlscan::SpecialVarType{$v}) {
                my $typ = $Perlscan::SpecialVarType{$v};
		        if($ValPy[$k] eq $DEFAULT_VAR && ($#ValClass == $k || $ValPy[$k+1] ne '=')) {	# issue s103
	      	        $VarSubMap{$DEFAULT_VAR}{$CurSub}='+';		# issue s103
               	    $NeedsInitializing{$CurSub}{$ValPy[$k]} = $typ unless exists $initialized{$CurSub}{$ValPy[$k]};	# issue s103
		        } elsif($ValPy[$k] eq $DEFAULT_VAR && exists $NeedsInitializing{$CurSub}{$ValPy[$k]}) {	# issue s103
	      	        $VarSubMap{$DEFAULT_VAR}{$CurSub}='+';		# issue s103
                } else {									# issue s103
                    $initialized{$CurSub}{$ValPy[$k]} = $typ;
                }
                $VarType{$ValPy[$k]}{$CurSub} = $typ;
                if(exists $SpecialVarR2L{$ValPy[$k]}) { # e.g. _nr() => INPUT_LINE_NUMBER
                    $initialized{$CurSub}{$SpecialVarR2L{$ValPy[$k]}} = $typ;
                    $VarType{$SpecialVarR2L{$ValPy[$k]}}{$CurSub} = $typ;
                }
                return $typ;
            }
            return 'I' if($ValPerl[$k] eq $INDEX_TEMP);         # We use this for ints only
            return 'S' if($ValPerl[$k] eq $KEY_TEMP);           # We use this for strings only
            return 'I' if(substr($ValPerl[$k],0,2) eq '$#');
            return 's';                 # scalar
        } elsif($class eq 'a') {        # array
            return 'I' if($ValPy[$k] =~ /^len\(/);      # Scalar context
            return $VarType{$ValPy[$k]}{$CurSub} if(exists $VarType{$ValPy[$k]} && exists $VarType{$ValPy[$k]}{$CurSub});
            my $v = substr($ValPerl[$k], 1);
            if(exists $Perlscan::SpecialArrayType{$v}) {
                my $typ = $Perlscan::SpecialArrayType{$v};
                $initialized{$CurSub}{$ValPy[$k]} = $typ;
                $VarType{$ValPy[$k]}{$CurSub} = $typ;
                return $typ;
            }
            return 'a of m';
        } elsif($class eq 'h') {        # hash
            return 'I' if($ValPy[$k] =~ /^len\(/);      # Scalar context
            return $VarType{$ValPy[$k]}{$CurSub} if(exists $VarType{$ValPy[$k]} && exists $VarType{$ValPy[$k]}{$CurSub});
            my $v = substr($ValPerl[$k], 1);
            if(exists $Perlscan::SpecialHashType{$v}) {
                my $typ = $Perlscan::SpecialHashType{$v};
                $initialized{$CurSub}{$ValPy[$k]} = $typ;
                $VarType{$ValPy[$k]}{$CurSub} = $typ;
                return $typ;
            }
            return 'h of m';
        } elsif($class eq '"' || $class eq 'x') {       # string or `exec` or /regex/
            return 'C' if($ValPy[$k] =~ /^$ANONYMOUS_SUB/);   # issue s229
            return 'S';                 # string
        } elsif($class eq 'q') {        # /regex/
            return 'R' if($ValPerl[$k] eq 'qr');        # Compiled regex
            return 'a of S' if($ValPy[$k] =~ /\.split\(\)$/);     # issue s38: qw/.../
            return 'S';                 # string
        } elsif($class eq 'i') {
            my $name = $ValPy[$k];
            if(substr($ValPerl[$k],0,1) eq '<') {   # Diamond operator
                return 'a of S' if($k-2 >= 0 && $ValClass[$k-2] eq 'a' && $ValClass[$k-1] eq '=');
                return 'S';
            } elsif($LocalSub{$name} || (exists $VarType{$name} && exists $VarType{$name}{__main__})) { # Local sub with no args
                # issue s241 return 'a' if exists $SubAttributes{$name}{wantarray} && &::list_or_scalar_context($k, $e); # issue string exprs
                return 'a' if defined get_sub_attribute($name, 'wantarray') && &::list_or_scalar_context($k, $e); # issue string exprs, issue s241
                return $VarType{$name}{__main__} if(exists $VarType{$name} && exists $VarType{$name}{__main__});
                return 'm';
	        } elsif(exists $CONSTANT_MAP{$ValPerl[$k]}) {
		        return 'I';
            } else {
                return 'S';
            }
        } elsif($class eq 'g') {                # Glob
            return 'a of S';
        } elsif($class eq 'k' && $ValPerl[$k] eq 'sub') {   # issue s229
            return 'C';                         # issue s229: coderef
        }
        return 'm';
    } elsif($k+2 <= $e && $ValClass[$k+1] eq '=') {     # Type of assignment is type of RHS
        return expr_type($k+2, $e, $CurSub);
    } elsif($class eq 'i') {    # bare word
        my $name = $ValPy[$k];
        if(substr($ValPerl[$k],0,1) eq '<') {   # Diamond operator
            return 'a of S' if($k-2 >= 0 && $ValClass[$k-2] eq 'a' && $ValClass[$k-1] eq '=');
            return 'S';
        } elsif($LocalSub{$name} || (exists $VarType{$name} && exists $VarType{$name}{__main__})) {
            return $VarType{$name}{__main__} if(exists $VarType{$name} && exists $VarType{$name}{__main__});
            return 'm';
        } elsif($k+1 <= $#ValClass && $ValClass[$k+1] eq '(') {
            return $VarType{$name}{__main__} if(exists $VarType{$name} && exists $VarType{$name}{__main__});
            return 'm';
        } elsif($k+1 <= $#ValClass && $ValClass[$k+1] eq 'A') {         # key => value
            return 'm';         # User can change it to any type of value
        } elsif($k+1 <= $#ValClass && $ValClass[$k+1] eq 'i') {         # issue s236: new Package
            return 'm';             # issue s236
        } elsif($k+1 <= $#ValClass && $ValClass[$k+1] eq 'D') {         # issue s236: Package->method
            return 'm';             # issue s236
        }
        return 'S';             # will be changed to a string
    } elsif($class eq '\\' && $k+1 <= $e && $ValClass[$k+1] eq 'i' && $LocalSub{$ValPy[$k+1]}) {    # issue s229: coderef
        return 'C';             # issue s229
    } elsif($class eq '\\' && $k+1 == $e && $ValClass[$k+1] eq 'a') {    # issue s316
        return 's';             # issue s316
    } elsif($class eq '\\' && $k+1 == $e && $ValClass[$k+1] eq 'h') {    # issue s316
        return 's';             # issue s316
    } elsif($class ne '(') {            # Non-parenthesized expression
        my $s = $k;                     # issue s151
        $s = end_of_function($k)+1 if $class eq 'f';    # issue s151
        my $m;                                          # test list util
        if(($m = next_same_level_token(',', $s, $e)) != -1) {    # test list util
            my $typ = expr_type($k, $m-1, $CurSub);
            my $p = $m+1;
            $m = end_of_function($m+1) if $m+1 <= $#ValClass && $ValClass[$m+1] eq 'f';
            while(($m = next_same_level_token(',', $m+1, $e)) != -1) {
                $typ = common_type($typ, expr_type($p, $m-1, $CurSub));
                $p = $m+1;
                $m = end_of_function($m+1) if $m+1 <= $#ValClass && $ValClass[$m+1] eq 'f';
            }
            $typ = common_type($typ, expr_type($p, $e, $CurSub)) if $p <= $e;
            return "a of $typ";
        }
        if($class eq 'f' && $s+1 <= $#ValClass && $ValClass[$s] eq 'p' &&        # Pattern match, issue s151, issue s315
                $ValClass[$s+1] eq 'q' && (capturing_pattern($ValPerl[$k+1]) || g_flag_pattern($ValPy[$k+1]))) {    # issue s315
            return 'a of S';
        }
        # issue s151 my $m = next_same_level_tokens('>+-*/%0o.?:r', $k, $#ValClass);
        $m = next_same_level_tokens('>+-*/%0o.?:r', $s, $#ValClass);     # issue s151
        if($m != -1 && $m <= $e) {
            if($ValClass[$m] eq '.') {
                return 'S';             # String concat
            } elsif($ValClass[$m] eq '>') {     # could be like < or like lt
	            # issue s124 return 'S' if($ValPerl[$m] =~ /^[a-z][a-z]$/);  # like eq, gt, etc
	            # issue s124 return 'I';     # boolean is an Int in perl
                # issue s151 return 'B';		# issue s124: Boolean
                my $mm = next_same_level_tokens('?:', $m+1, $#ValClass);        # issue s229
                # issue s229: Handle $s==1 ? $subref : sub{5} properly - it's not an 'I'!!
                if($mm != -1 && $mm <= $e) {
                    return expr_type($mm-1, $e, $CurSub);
                }
	            return 'I';     # issue s151: boolean is an Int in python (until we convert it with _pb)
            # issue s152 } elsif($ValClass[$m] =~ /0o/) {    # or || and &&
            } elsif($ValClass[$m] =~ /[0o]/) {    # or || and &&, issue s152
		        return common_type(expr_type($k, $m-1, $CurSub),
	                           expr_type($m+1, $e, $CurSub));
            } elsif($ValClass[$m] eq '+' || $ValClass[$m] eq '-' || $ValClass[$m] eq '*') {
                if($k == $m) { # It's a unary - or +
                    return expr_type($m+1, $e, $CurSub);
                }
                my $result = common_type(expr_type($k, $m-1, $CurSub),
                                   expr_type($m+1, $e, $CurSub));
                return $result if($result eq 'I' || $result eq 'F');    # I or F is tighter than the N below
            } elsif($ValClass[$m] eq '?') {     # expr ? true_val : false_val
                my $colon = next_same_level_token(':', $m+1, $#ValClass);
                if($colon > 0) {
                    # issue s316 return common_type(expr_type($m+1, $colon-1, $CurSub),
                    # issue s316                    expr_type($colon+1, $e, $CurSub));
                    my $t1 = expr_type($m+1, $colon-1, $CurSub);        # issue s316
                    my $t2 = expr_type($colon+1, $e, $CurSub);          # issue s316
                    return 'h' if $t1 =~ /^h/ && $ValPerl[$colon+1] eq '(' && $colon+2 == $e && $ValPerl[$e] eq ')';  # issue s316: expr ? %h : ()
                    return 'h' if $t2 =~ /^h/ && $ValPerl[$m+1] eq '(' && $m+2 == $colon-1 && $ValPerl[$colon-1] eq ')';  # issue s316: expr ? () : %h
                    return common_type($t1, $t2);                       # issue s316
                }
            } elsif($ValClass[$m] eq ':') {
                                                #              expr  :  expr  :   expr
                if($ValPy[$m] eq 'if') {        # Converted: trueval if expr else falseval
                    my $colon = next_same_level_token(':', $m+1, $#ValClass);
                    if($colon > 0) {
                        # issue s316 return common_type(expr_type($k, $m-1, $CurSub),
                        # issue s316                    expr_type($colon+1, $e, $CurSub));
                        my $t1 = expr_type($k, $m-1, $CurSub);          # issue s316
                        my $t2 = expr_type($colon+1, $e, $CurSub);      # issue s316
                        return 'h' if $t1 =~ /^h/ && $ValPerl[$colon+1] eq '(' && $colon+2 == $e && $ValPerl[$e] eq ')'; # issue s316: expr ? %h : ()
                        return 'h' if $t2 =~ /^h/ && $ValPerl[$k] eq '(' && $k+1 == $m-1 && $ValPerl[$m-1] eq ')';  # issue s316: expr ? () : %h
                        return common_type($t1, $t2);                   # issue s316
                    }
                }
            } elsif($ValClass[$m] eq 'r') {
                return 'a of I';
            }
            return 'N';         # Numeric
        } elsif($class eq 's' && $k+1 <= $#ValClass && $ValClass[$k+1] eq '(') {    # An array with possible subscript or hash with key
            my $name = $ValPy[$k];
            if(exists $VarType{$name} && exists $VarType{$name}{$CurSub} && index($VarType{$name}{$CurSub}, ' of ') > 0) {
                my $typ = $VarType{$name}{$CurSub};
                my $p = $k+1;
                while($ValClass[$p] eq '(') {
                    $q = matching_br($p);
                    last if($q < 0);
                    $typ =~ s/^. of //;
                    $p = $q+1;
                    last if($p > $#ValClass);
                }
                return $typ if($typ);
            }
        # issue s151 } elsif($class eq 's' && $k+2 <= $#ValClass && $ValClass[$k+1] eq '~' &&        # Pattern match
        } elsif(($class eq 's' || $class eq '"') && $k+2 <= $#ValClass && $ValClass[$k+1] eq 'p' &&        # Pattern match, issue s151, issue s315
                $ValClass[$k+2] eq 'q' && (capturing_pattern($ValPerl[$k+2]) || g_flag_pattern($ValPy[$k+2]))) {    # issue s315
                return 'a of S';
        } elsif($class eq '"' && $k+2 <= $#ValClass && $ValClass[$k+1] eq 'A') {
            return 'm';                 # key => value - user can change the value to anything
        } elsif($class eq '"') {        # We split interpolated strings into many tokens like "s(s)", but it's still a string at the end!
            return 'S';
        }
        return 'm';
    } else {                    # '('
        # Handle (a, b) = ...
        my $m = matching_br($k);
        if($m > 0 && $m+1 < $#VarClass && $VarClass[$m+1] eq '=') {
            return 'm';
        }
        my $ma = $m;
        if($m != $e) {          # issue s327: We don't have the whole thing in the parens
            $m = next_same_level_tokens('?:', $m+1, $e);    # See if we have a conditional
            if($m != -1) {
                if($ValClass[$m] eq '?') {  # This is a non-converted ? : operation with the condition in parens
                    my $colon = next_same_level_token(':', $m+1, $e);
                    return 'm' if $colon < 0;
                    my $t1 = expr_type($m+1, $colon-1, $CurSub);
                    return 'h' if $t1 =~ /^h/ && $ValPerl[$colon+1] eq '(' && $colon+2 == $e && $ValPerl[$e] eq ')';  # issue s316: expr ? %h : ()
                    my $t2 = expr_type($colon+1, $e, $CurSub);
                    return 'h' if $t2 =~ /^h/ && $ValPerl[$m+1] eq '(' && $m+2 == $colon-1 && $ValPerl[$colon-1] eq ')';  # issue s316: expr ? () : %h
                    return common_type($t1, $t2);
                } elsif($ValPerl[$m] eq '?') {  # Converted ? : operation = expr1 if cond else expr2
                    my $colon = next_same_level_token(':', $m+1, $e);
                    return 'm' if $colon < 0;
                    my $t1 = expr_type($k, $m-1, $CurSub);
                    return 'h' if $t1 =~ /^h/ && $ValPerl[$colon+1] eq '(' && $colon+2 == $e && $ValPerl[$e] eq ')'; # issue s316: expr ? %h : ()
                    my $t2 = expr_type($colon+1, $e, $CurSub);
                    return 'h' if $t2 =~ /^h/ && $ValPerl[$k] eq '(' && $k+1 == $m-1 && $ValPerl[$m-1] eq ')';  # issue s316: expr ? () : %h
                    return common_type($t1, $t2);
                }
            }
            return 'm';
        }

        # Check for list first
        $m = next_same_level_token(',', $k+1, $m-1);
        if($m == -1) {                  # issue s316: Only got 1 thing - check for a one-element hash
            my $n = next_same_level_token('A', $k+1, $ma-1);       # Look for =>
            if($n != -1 && $ValPerl[$n] eq '=>') {      # Like {key1=>val1}
                my $t = expr_type($n+1, $ma-1, $CurSub);
                return "h of $t";
            }
        } else {                        # issue s316
        # issue s316 if($m != -1) {
            my $n = next_same_level_token('A', $k+1, $m-1);       # Look for =>
            my $t;
            if($n != -1 && $ValPerl[$n] eq '=>') {      # Like {key1=>val1, key2=>val2}
                $t = expr_type($n+1, $m-1, $CurSub);
                while($t ne 'm') {
                    my $o = next_same_level_tokens(',)', $m+1, $#ValClass-1);
                    last if($o < 0);
                    $n = next_same_level_tokens('A', $m+1, $o-1);       # Look for =>
                    last if($n < 0 || $ValPerl[$n] ne '=>');
                    my $u = expr_type($n+1, $o-1, $CurSub);
                    $t = common_type($t, $u);
                    last if($ValClass[$o] eq ')');
                    $m = $o;
                }
                return "h of $t";
            } else {                                    # like (1, 2, 3)
                $t = expr_type($k+1, $m-1, $CurSub);
                while($t ne 'm') {
                    my $o = next_same_level_tokens(',)', $m+1, $#ValClass);
                    last if($o < 0);
                    my $u = expr_type($m+1, $o-1, $CurSub);
                    $t = common_type($t, $u);
                    last if($ValClass[$o] eq ')');
                    $m = $o;
                }
            }
            return "a of $t";
        }                   # issue s316
        # issue s316 } elsif($ValPerl[$k] eq '[' && next_same_level_token('y', $k+1, $ma-1) != -1) { # issue s154: get proper type of [... y ...] expression
        if($ValPerl[$k] eq '[' && next_same_level_token('y', $k+1, $ma-1) != -1) { # issue s154: get proper type of [... y ...] expression
            return 'a of m';
        } elsif($ValPerl[$k] eq '{' && next_same_level_token('y', $k+1, $ma-1) != -1) {
            return 'h of m';
        } elsif(($ma-$k) == 1) {            # issue s197: () =  empty array
            return 'a';                     # issue s197
        } else {        # Not a list, just a parenthesized expression
            # issue s306 return expr_type($k+1, $ma-1, $CurSub);           # Just get the type of the expression in the (...)
            my $typ = expr_type($k+1, $ma-1, $CurSub);           # Just get the type of the expression in the (...), issue s306
            return $typ if $ma == $e;               # issue s306
            if($ma+3 <= $e && $ValClass[$ma+1] eq '(') {    # issue s306: Case in test is (split(/ /, $in))[0]
                if($ValPerl[$ma+1] eq '[') {        # issue s306: Being subscripted
                    if($typ =~ /a of (.*)$/) {      # issue s306
                        return $1;                  # issue s306
                    } else {                        # issue s306
                        return 'm';                 # issue s306
                    }                               # issue s306
                } elsif($ValPerl[$ma+1] eq '{') {   # issue s306: Being hash keyed
                    if($typ =~ /h of (.*)$/) {      # issue s306
                        return $1;                  # issue s306
                    } else {                        # issue s306
                        return 'm';                 # issue s306
                    }                               # issue s306
                }                                   # issue s306
            }                                       # issue s306
            return $typ;                            # issue s306
        }
    }
}

sub expr_type
{
    state $level = 0;
    $level++;
    print STDERR '>' x $level if($::debug>=3);
    my $result = _expr_type(@_);
    if($::debug>=3) {
        print STDERR '<' x $level;
        say STDERR "expr_type($_[0], $_[1], $_[2]) = $result";
    }
    $level--;
    return $result;
}

sub vartype                 # issue s316
{
    my $k = shift;
    my $CurSub = shift;
    return $VarType{$ValPy[$k]}{$CurSub} if(exists $VarType{$ValPy[$k]} && exists $VarType{$ValPy[$k]}{$CurSub});
    return 'm';
}

sub g_flag_pattern              # issue s315: is this a pattern with a g flag?
{
    my $pat_py = shift;

    return 1 if $pat_py =~ /\bre\.G\b/;
    return 1 if $pat_py =~ /\bre\.finditer\b/;
    return 1 if $pat_py =~ /\bre\.findall\b/;
    return 0;
}

sub capturing_pattern           # Is this pattern capturing with (...)?
{
    my $pat = shift;

    for(my $i = 0; $i < length($pat); $i++) {
        my $c = substr($pat, $i, 1);
        if($c eq "\\") {
            $i++;
            next;
        }
        if($c eq '(') {
           if(substr($pat, $i+1, 2) =~ /\?[<']/) {      # named capture group
               return 1;        
           } elsif(substr($pat, $i+1, 1) ne '?') {      # regular capture group
               return 1;
           }
        }
    }
    return 0;
}

sub common_type         # Create a common type from 2 types
{
    my $t1 = shift;
    my $t2 = shift;

    return $t1 if($t1 eq $t2);          # That was easy!
    # test list util u = undef (e.g. None) not undefined : return $t2 if($t1 eq 'u');          # u = undefined
    # test list util: return $t1 if($t2 eq 'u');
    return $t2 if(!defined $t1);    # test list util
    return $t1 if(!defined $t2);    # test list util
    if(index('IF', $t1) >= 0 && index('IF', $t2) >= 0) {
        return 'F';             # Int mixed with Float => Float
    } elsif($t1 eq 'N' && index('IF', $t2) >= 0) {
        return 'N';             # Numeric
    } elsif($t2 eq 'N' && index('IF', $t1) >= 0) {
        return 'N';             # Numeric
    } elsif($t1 eq 's' && index('IFN', $t2) >= 0) {
        return 's';              # Scalar
    } elsif($t2 eq 's' && index('IFN', $t1) >= 0) {
        return 's';              # Scalar
    }
    my $lcp = length(lcp($t1, $t2));
    if($lcp != 0) {                  # handle both being like a of I or a of a of N, etc
        if($lcp == 1) {
            return substr($t1,0,$lcp);
        } else {
            return substr($t1,0,$lcp) . common_type(substr($t1,$lcp), substr($t2,$lcp));
        }
    }
    return 'm';
}

sub lcp {               # Longest common prefix - LOL don't ask me how it works!
    return (join("\0", @_) =~ /^ ([^\0]*) [^\0]* (?:\0 \1 [^\0]*)* $/sx)[0];
}

sub func_type                   # Get the result type of this built-in function
{
    my $fname = shift;          # send us ValPerl
    my $pname = shift;          # ValPy

    my $type = undef;
    if(exists $PyFuncType{$pname}) {
        $type = $PyFuncType{$pname};
    } elsif(exists $FuncType{$fname}) {
        $type = $FuncType{$fname};
    } else {
        logme('W', "Cannot get function type for $fname ($pname in python)");
        return 'm' 
    }
    $type =~ s/^.*://;
    # SNOOPYJC: This code removed because we now map the real function type into %PyFuncType:
    #if(exists $Perlscan::SPECIAL_FUNCTION_MAPPINGS{$fname} &&
    #$Perlscan::SPECIAL_FUNCTION_MAPPINGS{$fname}{list} ne $pname) {
    #$type = 's';
    #}
    say STDERR "func_type($fname, $pname) = $type" if($::debug >= 5);
    return $type;
}

sub matching_br
# Find matching bracket, arase closeing braket, if found.
# Arg1 - starting position for scan
# Arg2 - (optional) -- balance from whichto start (allows to skip opening brace)
{
my $scan_start=$_[0];
my $balance=(scalar(@_)>1) ? $_[1] : 0; # case where opening bracket is missing for some reason or was skipped.
   for( my $k=$scan_start; $k<length($TokenStr); $k++ ){
     $s=substr($TokenStr,$k,1);
     if( $s eq '(' ){
        $balance++;
     }elsif( $s eq ')' ){
        $balance--;
        if( $balance==0  ){
           return $k;
        }
     }
  } # for
  # issue bootstrap return $#TokenStr;
  return -1;			# issue bootstrap: not found
} # matching_br

sub reverse_matching_br
# Find matching bracket, opening braket, if found.
# Arg1 - starting position for scan
# Arg2 - (optional) -- balance from whichto start (allows to skip closing brace)
{
my $scan_start=$_[0];
my $balance=(scalar(@_)>1) ? $_[1] : 0; # case where opening bracket is missing for some reason or was skipped.
   for( my $k=$scan_start; $k>=0; $k-- ){
     $s=substr($TokenStr,$k,1);
     if( $s eq ')' ){
        $balance++;
     }elsif( $s eq '(' ){
        $balance--;
        if( $balance==0  ){
           return $k;
        }
     }
  } # for
  # SNOOPYJC return 0;
  return -1;			# SNOOPYJC: not found
} # reverse_matching_br

sub next_matching_token                 # SNOOPYJC
# get the next matching token
{
my $t=$_[0];
my $scan_start=$_[1];
my $scan_end=$_[2];
    #if($scan_start > length($TokenStr)) { die "next_matching_token($t, $scan_start, $scan_end) =|$TokenStr|= failed!"; }
    my $k = index(substr($TokenStr, $scan_start, $scan_end-$scan_start+1), $t);
    return $k if($k < 0);
    return $k + $scan_start;
} # next_matching_token

sub last_matching_token                 # SNOOPYJC
# get the last matching token
{
my $t=$_[0];
my $scan_start=$_[1];
my $scan_end=$_[2];
    #if($scan_start > length($TokenStr)) { die "next_matching_token($t, $scan_start, $scan_end) =|$TokenStr|= failed!"; }
    my $k = rindex(substr($TokenStr, $scan_start, $scan_end-$scan_start+1), $t);
    return $k if($k < 0);
    return $k + $scan_start;
} # last_matching_token

sub next_matching_tokens                 # SNOOPYJC
# get the next matching token
{
my $t=$_[0];
my $scan_start=$_[1];
my $scan_end=$_[2];
    
    for(my $k = $scan_start; $k <= $scan_end; $k++) {
        return $k if(index($t, $ValClass[$k]) >= 0);
    }
    return -1;
} # next_matching_tokens

sub next_same_level_token
# get the next token on the same nesting level.
{
my $t=$_[0];
my $scan_start=$_[1];
my $scan_end=$_[2];
my $balance=0;
    # issue 74 for( my $k=$scan_start; $k<$scan_end; $k++ ){      # issue 74
    for( my $k=$scan_start; $k<=$scan_end; $k++ ){      # issue 74
      my $s=substr($TokenStr,$k,1);
      if( $s eq '(' ){
         $balance++;
      }elsif( $s eq ')' ){
         $balance--;
      }
      if($t eq ')') {            # SNOOPYJC: if we're looking for a ')', the balance needs to be -1
          return $k if($s eq $t && $balance < 0);
      } elsif( $s eq $t && $balance<=0  ){
          return $k;
      } elsif($t eq '(' && $s eq $t && $balance == 1) {
          return $k;
      }
      return -1 if $balance < 0;     # issue s3 - tokens were k(fs)Di(f(s),s) and we started at 2 and ended at 13
   } # for
   return -1; # not found
} # next_same_level_token

sub next_same_level_tokens
# get the next token on the same nesting level matching any given by first arg.
{
my $toks=$_[0];
my $scan_start=$_[1];
my $scan_end=$_[2];
my $balance=0;
    # issue 74 for( my $k=$scan_start; $k<$scan_end; $k++ ){      # issue 74
    for( my $k=$scan_start; $k<=$scan_end; $k++ ){      # issue 74
      my $s=substr($TokenStr,$k,1);
      # die("next_same_level_tokens($toks, $scan_start, $scan_end) for =|$TokenStr|= - out of range!") if(!defined $s);
      if( $s eq '(' ){
         $balance++;
      }elsif( $s eq ')' ){
         $balance--;
      }
      my $p = index($toks, $s);
      if($p >= 0) {
          if($s eq ')') {       # SNOOPYJC: if we're looking for a ')', the balance needs to be -1
              return $k if($balance < 0);
          } elsif( $balance<=0  ){
              return $k;
          } elsif($s eq '(' && $balance == 1) {
              return $k;
          }
      }
      return -1 if $balance < 0;     # issue s3 - tokens were k(fs)Di(f(s),s) and we started at 2 and ended at 13
   } # for
   return -1; # not found
} # next_same_level_tokens

sub next_lower_or_equal_precedent_token
# get the next token on the same nesting level that's lower or equal precedence than the given token
{
my $tok=$_[0];
my $scan_start=$_[1];
my $scan_end=$_[2];
    return -1 unless(exists $token_precedence{$tok});
    my $prec = $token_precedence{$tok};
    my $toks = '';
    for $t (keys %token_precedence) {
        $toks.=$t if($token_precedence{$t} <= $prec);
    }
    return next_same_level_tokens($toks, $scan_start, $scan_end);
}

sub apply_scalar_context                        # issue 37
{
    $pos = shift;
    $is_last = scalar @_ ? $_[0] : 0;   # issue s341: pos is the end of the terminal, not the start
    return 0 if($pos < 0 || $pos > $#ValClass);
    # issue 30 if($ValClass[$pos] eq 'a' && substr($ValPy[$pos],0,4) ne 'len(') {
    if(($ValClass[$pos] =~ /[ah]/ ||
       ($ValClass[$pos] eq 's' && defined $ValType[$pos] && ($ValType[$pos] eq '@s' || # handle @$var
                                                             $ValType[$pos] eq '%s'))) # issue s246: handle %$var
           && substr($ValPy[$pos],0,4) ne 'len(') {
        $ValPy[$pos] = 'len('.$ValPy[$pos].')';
        return 1;
    } elsif($ValClass[$pos] eq 'f' && exists $SPECIAL_FUNCTION_MAPPINGS{$ValPerl[$pos]}) {      # issue 65
        $scalar_ValPy = $SPECIAL_FUNCTION_MAPPINGS{$ValPerl[$pos]}->{scalar};
        if($ValPy[$pos] ne $scalar_ValPy) {
            $ValPy[$pos] = $scalar_ValPy;
            return 1;
        }
    } elsif($ValClass[$pos] eq '(' && $ValPerl[$pos] eq '(' && 
            $pos+1 <= $#ValClass && $ValClass[$pos+1] eq ')') {
        if($pos+2 <= $#ValClass && $ValClass[$pos+2] eq '=') {        # issue s46: goatse: $s = () = ...
            append(')',')',')');
            insert($pos+3,'(','(','(');
            # issue s254 insert($pos+3,'f','scalar','len');
            insert($pos+3,'f','scalar','lena');     # This 'scalar' has type a:I so the arg is in list context
            return 2;               # Signal list context
        } else {                    # issue s254: () is undef in scalar context
            replace($pos, 'f', 'undef', 'None');
            destroy($pos+1, 1);
            return 1;
        }
    } elsif($is_last && $ValClass[$pos] eq ')' && $ValPerl[$pos] eq '}') {  # issue s341
        my $open = reverse_matching_br($pos);           # issue s341
        return 0 if $open <= 0;                         # issue s341
        return 0 if $ValClass[$open-1] ne '@';          # issue s341: Looking for @{...}
        return 0 if $open-2 >= 0 && $ValClass[$open-2] eq 'f' && $ValPerl[$open-2] eq 'scalar'; # issue s341
        return 0 if $open-3 >= 0 && $ValPerl[$open-2] eq '(' && $ValClass[$open-3] eq 'f' && $ValPerl[$open-3] eq 'scalar'; # issue s341
        $ValPy[$open-1] = 'len('.$ValPy[$open-1].')';   # issue s341: This is just a flag for remove_dereferences
    }
    return 0;
}

sub fix_scalar_context                          # issue 37
{
    # Run over the statement and fix scalar context issues
    my $did_something = 0;
    my $j;
    # First handle "new" calls which map to functions so we can potentially apply scalar context to them
    if($TokenStr =~ /ii/) {
        # Case 1: new File::Temp
        #          i      i
        my $pos = $-[0];
        my $name = $ValPerl[$pos+1] . '::' . $ValPerl[$pos];
        if(exists $Perlscan::TokenType{$name}) {
            replace($pos+1,'f',$name, $Perlscan::keyword_tr{$name});
            destroy($pos,1);
            $did_something = 1;
        }
    } elsif($TokenStr =~ /iDi/) {
        # Case 2: File::Temp->new
        #             i     D i
        my $pos = $-[0];
        my $name = $ValPerl[$pos] . '::' . $ValPerl[$pos+2];
        if(exists $Perlscan::TokenType{$name}) {
            replace($pos+2,'f',$name, $Perlscan::keyword_tr{$name});
            destroy($pos,2);
            $did_something = 1;
        }
    }
    if($TokenStr eq 's=a' || $TokenStr eq 's=h' || $TokenStr =~ /^s=f/ || $TokenStr =~ /^s=\(\)/) {         # issue 65, goatse, issue 30, issue s254: remove the check for '=' at the end of ()
        $did_something |= apply_scalar_context(2) if(!$ValType[0] || $ValType[0] !~ /[@%]s/);  # issue s244h
    } elsif($TokenStr eq 'ts=a' || $TokenStr eq 'ts=h' || $TokenStr =~ /^ts=f/ || $TokenStr =~ /^ts=\(\)/) {    # issue 65, goatse, issue 30, issue s254: remove the check for '=' at the end of ()
        $did_something |= apply_scalar_context(3) if(!$ValType[1] || $ValType[1] !~ /[@%]s/);  # issue s244h
    } elsif($#ValClass > 5 && $ValClass[1] eq '(' && $ValClass[0] eq 's') {    # Array subscript or hashref
        $j=&::end_of_variable(0);                      # Look for $arr[ndx]=@arr or $arr[ndx]=func()
        if($j+2 <= $#ValClass && $ValClass[$j+1] eq '=' && $ValClass[$j+2] =~ /[ahf]/) {        # issue 30
            $did_something |= apply_scalar_context($j+2);
        }
    }
    # Handle the assigment being in a control statement
    if($ValClass[0] eq 'c' || $ValClass[0] eq 'C') {            # issue 37
        if($TokenStr =~ /^[cC]\(s=[ahf]/ || $TokenStr =~ /^[cC]\(s=\(\)/) {         # issue 65, goatse, issue 30
            $did_something |= apply_scalar_context(4);
        } elsif($TokenStr =~ /^[cC]\(f\(s=[ahf]/ && $ValPerl[2] eq 'defined') {         # issue s40: Added by handle_while_magic_function
            $did_something |= apply_scalar_context(6);                                  # issue s40
        } elsif($TokenStr =~ /^[cC]\(f/ && ($ValPerl[0] eq 'if' || $ValPerl[0] eq 'unless' || $ValPerl[0] eq 'elsif')) {   # issue s260
            $did_something |= apply_scalar_context(2);                                      # issue s260
        } elsif($TokenStr =~ /^[cC]f/ && ($ValPerl[0] eq 'if' || $ValPerl[0] eq 'unless' || $ValPerl[0] eq 'elsif')) {   # issue s260
            $did_something |= apply_scalar_context(1);                                      # issue s260
        } elsif($#ValClass > 7 && $ValClass[3] eq '(' && $ValClass[2] eq 's') {    # Array subscript or hashref
            $j=&::end_of_variable(2);                      # Look for $arr[ndx]=@arr or $arr[ndx]=func()
            if($j+2 <= $#ValClass && $ValClass[$j+1] eq '=' && $ValClass[$j+2] =~ /[ahf]/) {        # issue 30
                $did_something |= apply_scalar_context($j+2);
            }
        }
    }

    # issue 13: Handle the ',' operator in scalar context
    $j = 0;
    # issue s273: Check ValType to make sure we don't have @$var or %$var:
    if(($ValClass[0] eq 'c' && $ValPerl[0] =~ /if|while|until/ && $ValClass[1] ne 'a' && ($ValClass[1] eq '(' && $ValClass[2] ne 'a')) ||
       ($ValClass[0] eq 'C' && $ValPerl[0] eq 'elsif' && $ValClass[1] ne 'a' && ($ValClass[1] eq '(' && $ValClass[2] ne 'a')) ||
       ($#ValClass > 1 && $ValClass[0] eq 's' && $ValClass[1] eq '=' && (!defined $ValType[0] || $ValType[0] !~ /[@%]s/)) ||
       ($#ValClass > 2 && $ValClass[0] eq 't' && $ValClass[1] eq 's' && $ValClass[2] eq '=' && (!defined $ValType[1] || $ValType[1] !~ /[@%]s/)) ||
       ($#ValClass > 3 && $ValClass[0] eq 's' && (!defined $ValType[0] || $ValType[0] !~ /[@%]s/) && $ValClass[1] eq '(' && ($j=&::end_of_variable(0)+1) < $#ValClass &&
        $ValClass[$j] eq '=')) {
        $j = next_same_level_token('(', 1, $#ValClass) - 1 if($j == 0);
        if($ValClass[$j] =~ /[cC=]/ && $j+1 <= $#ValClass && $ValClass[$j+1] eq '(' && $ValPerl[$j+1] eq '(') {
            my $pos = $j+2;
            my $end_pos = next_same_level_tokens(',)', $pos, $#ValClass)-1;
            my $sub_or_function = next_same_level_tokens('if', $pos, $end_pos);
            if($sub_or_function != -1 && $ValClass[$sub_or_function+1] ne '(') {        # Assume this is a paren-less call and the comma belongs to the call
                $end_pos = next_same_level_token(')', $end_pos+2, $#ValClass)-1 if($ValClass[$end_pos+1] eq ',');
            }
            my $found_comma = ($ValClass[$end_pos+1] eq ',');
            while($end_pos >= $pos) {
                if($ValClass[$pos] =~ /[ahf]/) {        # issue 30
                    if(!$found_comma && $end_pos+4 <= $#ValClass && $ValPerl[$end_pos+2] eq '[') {  # issue s306: Being subscripted
                        ;
                    }  else {
                        $did_something |= apply_scalar_context($pos);
                    }
                }
                last if($ValClass[$end_pos+1] eq ')');
                $pos = $end_pos+2;
                $end_pos = next_same_level_tokens(',)', $pos, $#ValClass)-1;
            }
            if($ValClass[$end_pos+1] eq ')' && $found_comma) {
                if($ValClass[0] =~ /[Cc]/) {    # We have to insert an extra set of parens
                    insert($end_pos+1,')',')',')');
                    insert($j+1,'(','(','(');
                    $end_pos++;
                    $j++;
                }
                insert($end_pos+2,']',']',']');         # Subscript the tuple to get the last element
                insert($end_pos+2,'d','-1','-1');
                insert($end_pos+2,'[','[','[');
                $did_something |= 1;
            }
        }
    }

    my $last_special_function = -1;                     # issue s3: handle keys arr == 2
    my $last_special_function_end = -1;                 # issue s48
    my $in_function_until = -1;                         # issue s48
    for(my $i=0; $i<=$#ValClass; $i++) {
        if($in_function_until != -1 && $i <= $in_function_until && $ValClass[$i] ne ',') {      # issue s48
            # First check to see if we have an assignment in a function call, like chomp($cwd = `pwd`) and fix the context
            # of the RHS of the assignment.
            if($ValClass[$i] eq 's') {  # issue s48
                my $j = &::end_of_variable($i);
                if($j+2 <= $#ValClass && $ValClass[$j+1] eq '=') {
                    if($ValClass[$j+2] =~ /[ahf]/) {
                        $did_something |= apply_scalar_context($j+2);
                    }
                    if($last_special_function != -1) {
                        $did_something |= apply_scalar_context($last_special_function);
                        $last_special_function = -1;
                    }
                }
            }
            # issue s48: Get the required type of this arg, and if it's a scalar type, change the
            # operand to be in scalar context.
            my ($fname, $pname, $arg) = arg_from_pos($i);
            if(!defined $fname && $::debug >= 5) {
                say STDERR "Can't get type of token $i on function in =|$TokenStr|=, ValPy=@ValPy";
            }
            my $arg_type = arg_type($fname, $pname, $arg, 0);   # 0 = don't repeat the last arg if we're past the end
            # my $arg_type = arg_type($fname, $pname, $arg, 0, 1);   # 0 = don't repeat the last arg if we're past the end, issue s247: request if optional
            #say STDERR "arg_type($fname, $pname, $arg, 0) = $arg_type";         # TEMP
            # Check the next arg too because this array could just be splatted into multiple arguments like for timegm
            my $next_arg_type = 'u';
            $next_arg_type = arg_type($fname, $pname, $arg+1, 0, 1) if defined $arg;
            #say STDERR "arg_type($fname, $pname, $arg+1, 0, 1) = $next_arg_type" if defined $arg;  # TEMP
            $next_arg_type = '' unless defined($next_arg_type);
            # THIS FIX BREAKS issue_s48 so we can't do it this way!
            # if(defined $arg_type && $arg_type =~ /[sSIFN]\?/ && $ValClass[$i] eq 'a') {     # issue s247
            # $arg_type = $next_arg_type;         # issue s247
            # $next_arg_type = '';                # issue s247
            # }
            if(defined $arg_type && $arg_type =~ /[sSIFN]/ && $next_arg_type !~ /^[sSIFN]$/) {
                # For printf only (not sprintf), if we are passing an array where the first element is the format,
                # then don't apply scalar context to that
                if($fname eq 'printf' && $arg == 1 && $ValClass[$i] eq 'a') {
                    ;
                } else {
                    $did_something |= apply_scalar_context($i);
                }
            }
        } elsif($i > $in_function_until+1) {
            $last_special_function = -1;        # Don't keep this long past the end of the function call
        }
        # issue s246 if(index("+-*/.>%",$ValClass[$i]) >= 0) {        # Scalar operator, issue s246: add '%' operator
        if(is_scalar_operator($i)) {        # Scalar operator, issue s246
            if($i == 0) {
                ;
            } elsif($ValClass[$i] ne 'r' && $last_special_function != -1 && $i == $last_special_function_end+1) {     # issue s3, issue s307: only apply scalar to range operator on RHS of expression, else we mess up 'reverse 0..10'
                $did_something |= apply_scalar_context($last_special_function);
                $last_special_function = -1;
                $last_special_function_end = -1;
            } elsif($i-1 == 0 || ($ValClass[$i-2] ne 'f' && $ValClass[$i-2] ne "\\")) {   # function (like shift/pop) on an array - don't apply scalar context to the array, also skip if we're getting a reference to the object
                $did_something |= apply_scalar_context($i-1, 1);        # issue s341
            }
            $did_something |= apply_scalar_context($i+1);
        } elsif($ValClass[$i] eq 'f' and $ValPerl[$i] eq 'scalar' && ($did_something & 2) != 2) {
            # The 'scalar' function gets changed to 'len' which works unless it's applied to 'localtime'
            # or other functions that have different scalar interpretation, like 'reverse',
            # so we handle that here by fixing the function and removing the 'len' call.
            if($ValClass[$i+1] eq '(' && apply_scalar_context($i+2) == 1) {     # issue times
                my $close = matching_br($i+1);
                if($close != -1) {
                    destroy($close,1);
                    destroy($i,2);
                    $last_special_function-=2;       # issue s3
                    $last_special_function_end-=2;
                    $in_function_until-=2;           # issue s46
                    $i--;
                    $did_something = 1;
                }
            } elsif(apply_scalar_context($i+1) == 1) {
                destroy($i,1);
                $i--;
                $last_special_function--;       # issue s3
                $last_special_function_end--;
                $in_function_until--;           # issue s46
                $did_something = 1;
            }
        } elsif($ValClass[$i] eq 'f') {                 # issue s48: Examine all function args looking for scalar type requirements

            my $j = end_of_function($i);
            #say STDERR "end_of_function($i) =|$TokenStr|= $ValPerl[$i] = $j" if($::debug >= 5);
            if($j != -1 && $j > $in_function_until) {
                $in_function_until = $j;
            }
            if(exists $SPECIAL_FUNCTION_MAPPINGS{$ValPerl[$i]}) {  # issue s3
                $last_special_function = $i;
                $last_special_function_end = $j;
            }
        # issue s48 } else {                                # issue s3
        # issue s48    $last_special_function = -1;        # Don't apply to function long past in the expression
        }
    }
    if($::debug && $did_something) {
        say STDERR "After fix_scalar_context: =|$TokenStr|=, ValPy = @ValPy";
    }
}

sub _end_of_function                             # issue s3
# Find the end of this function call - returns the index of the last token that's still part of the call
{
    my $pos = shift;    # point to the function

    return $pos if($pos == $#ValClass);   # Function at end of statement with no params
    if($ValClass[$pos+1] eq '(' && $ValPerl[$pos+1] eq '(') {
        # easy case
        $e = matching_br($pos+1);
        return $e if($e >= 0);
        return $#ValClass;
    }
    my $f_type = undef;
    if(exists $PyFuncType{$ValPy[$pos]}) {
       $f_type = $PyFuncType{$ValPy[$pos]};
    } elsif(exists $FuncType{$ValPerl[$pos]}) {
        $f_type = $FuncType{$ValPerl[$pos]};
    }
    my ($j, $k, $limit);
    my $end_pos = $#ValClass;
    $limit = $#ValClass;                # issue s48
    # issue s151: Move this code up from below as the and/or/comparison was messing up $limit!
    my $t_pos = 0;
    if(($ValPerl[$pos] eq 'grep' || $ValPerl[$pos] eq 'map' || 
            $ValPerl[$pos] eq 'sort' || $ValPerl[$pos] eq 'exec') &&    # issue s247: add 'exec'
        $ValPerl[$pos+1] eq '{') {
        # this is like grep { function } @array - skip right to the array
        my $close = matching_br($pos+1);
        $pos = $close;
        $t_pos++;
        # issue s151 $end_pos = $limit;  # issue s48: the function may have a token '0o>' in it so point back to the end
    } else {            # issue s151
        # issue s207 $k = next_matching_tokens('0o>',$pos+1,$end_pos);  # stop at next and/or/comparison
        # issue s315 $k = next_matching_tokens('o>',$pos+1,$end_pos);  # issue s207: stop at next and/or/comparison, but not || or &&
        $k = next_same_level_tokens('o>',$pos+1,$end_pos);  # issue s207: stop at next and/or/comparison, but not || or &&
        $end_pos = $k-1 if($k != -1);
        return $end_pos unless defined $f_type;     # this is a guess
    }
    # if the entire function call w/parameters is parenthesized, then the function ends
    # at the next right paren
    if($pos != 0 && $ValClass[$pos-1] eq '(') {
        my $ep = matching_br($pos-1)-1;
        # This could be missing because in control() when generating the code of a for loop, we
        # eat the right paren before calling expression()
        $end_pos = $ep if($ep > 0 && $ep < $end_pos);
        $limit = $end_pos;              # issue s48
    } elsif($pos >= 2 && $ValClass[$pos-1] eq '!' && $ValClass[$pos-2] eq '(') {        # issue s48: Handle if(!func(args))
        my $ep = matching_br($pos-2)-1;
        $limit = $end_pos = $ep if($ep > 0);
    }elsif($pos != 0 && $ValPerl[$pos-1] eq '?') { # If we are in a ?...: operation, then the function has to end before the ':'
        my $colon = next_same_level_token(':', $pos+1, $limit);
        $limit = $end_pos = $colon-1 if($colon > 0);
    }
    my $op = 'F';
# issue s151     my $t_pos = 0;
# issue s151     if(($ValPerl[$pos] eq 'grep' || $ValPerl[$pos] eq 'map' || $ValPerl[$pos] eq 'sort') && $ValPerl[$pos+1] eq '{') {
# issue s151         # this is like grep { function } @array - skip right to the array
# issue s151         my $close = matching_br($pos+1);
# issue s151         $pos = $close;
# issue s151         $t_pos++;
# issue s151         $end_pos = $limit;  # issue s48: the function may have a token '0o>' in it so point back to the end
# issue s151     }
    my $balance = 0;
    my $pep = -1;		# issue s75
    my $last_t;         # test list util
    EOFLOOP:
    for($j = $pos+1; $j <= $end_pos; $j++) {
        if($ValClass[$j] eq '(') {
            $balance++;
        } elsif($ValClass[$j] eq ')') {
            $balance--;
            if($balance < 0) {  # if we see a ')' that we have no '(' for, then this must be the end
                $j--;
                last;
            }
        }
        my $comma = next_lower_or_equal_precedent_token($op, $j, $end_pos);
        if($ValClass[$j] eq 'f') {      # issue s48
            $j = end_of_function($j);
        } elsif($ValClass[$j] eq 's') { # issue s48
            $j = &::end_of_variable($j);
        }
        $op = ',' if $comma != -1 && $ValClass[$comma] eq ',';  # Now we are in a list
        # issue s48 my $close = next_same_level_token(')', $j, $end_pos);
        $ep = (($comma==-1) ? $end_pos : $comma-1);
        # issue s48 $ep = $close-1 if($close!=-1 && $close-1 < $ep);
        my $optional = 0;
        my $t = substr($f_type, $t_pos, 1);
        if($t eq 'a' && substr($f_type, $t_pos) =~ /^a of ?/) { # test list util: Allow 'a of N' and 'a of S'
            $t_pos += 5;                    # test list util
            $last_t = $t;                   # test list util
        }                                   # test list util
        $optional = 1 if(substr($f_type, $t_pos+1, 1) eq '?');
        $t = substr($f_type, ++$t_pos, 1) if($t eq '?');
        if($t eq ':') {
            if(defined $last_t) {        # test list util: could be 'a of ?' - can't just back up 1 symbol
                $t = $last_t; 
                $t_pos--;
            } else {
                $t = substr($f_type, --$t_pos, 1) if($t_pos > 0);   # issue s151
                $t = substr($f_type, --$t_pos, 1) if($t eq '?');
            }
            if($t ne 'a') {
                $j--;
        		$j = $pep unless $pep < 0;		# issue s75
                last;
            }
        }
        $t_pos++;
        if($t eq 'H' && $ValClass[$j] =~ /[isf]/) {      # e.g. print H a,b;
            $j = &::end_of_variable($j);
            $j++ if($j+1 == $comma);
            next;
        } elsif($optional && 
            ($j == 0 || $ValClass[$j-1] ne ',') &&              # issue s52
            # issue s52 index("^*~/%+-.HI>&|0or?:=,A", $ValClass[$j]) >= 0) {
            # issue s151 index("^*~/%.HI>&|0or?:=,A", $ValClass[$j]) >= 0) {  # issue s52: Eliminated unary ops here
            index("^*p/%.HI>&|0or?:=,A", $ValClass[$j]) >= 0) {  # issue s52: Eliminated unary ops here, issue s151
            $j--;
            last;
        # issue s246 } elsif(!$optional && $comma != -1 && $ValClass[$comma] ne ',' &&
        } 
        if($comma != -1 && $ValClass[$comma] ne ',' &&     # issue s246: Do this even if it's optional
                substr($f_type, $t_pos, 1) ne ':' && substr($f_type, $t_pos+1, 1) ne '?') {       # issue s46
            # issue s46: If we came to a lower-precedent operator that's not a comma, but
            # we still need more non-optional arguments to this function, then skip over that
            # looking for our real comma.
            # issue s246 $comma = next_same_level_token(',', $j, $end_pos);
            # issue s246 $ep = (($comma==-1) ? $end_pos : $comma-1);
            my $co = next_same_level_token(',', $comma+1, $end_pos);      # issue s246
            if($optional) {                                         # issue s246
                $ep = (($co==-1) ? $ep : $co-1);                    # issue s246
                $comma = $co if $co != -1;                          # issue s246
            } else {                                                # issue s246
                $ep = (($co==-1) ? $end_pos : $co-1);               # issue s246
                $comma = $co;                                       # issue s246
            }                                                       # issue s246
        } elsif($t ne ':' && $comma != -1 && 
            ($ValClass[$comma] eq '?' || ($ValClass[$comma] eq ':' && $ValPy[$comma] eq 'if'))) {    # issue s194
            # If we are in a ? : operation, skip past it
            $comma = next_lower_or_equal_precedent_token($op, $comma+1, $end_pos);
            if($comma != -1 && $ValClass[$comma] eq ':') {
                $comma = next_lower_or_equal_precedent_token($op, $comma+1, $end_pos);
                $ep = (($comma==-1) ? $end_pos : $comma-1);               # issue s246
            }
        }
	    $pep = $ep;			# issue s75
        if($comma < 0 || ($comma >= 0 && $ValClass[$comma] ne ',')) {
            for(my $p = $j+1; $p <= $ep; $p++) {        # see if we need to end earlier than $ep
                if($ValClass[$p] eq '(') {
                    $balance++;
                } elsif($ValClass[$p] eq ')') {
                    $balance--;
                    if($balance < 0) {
                        $j = $p-1;
                        last EOFLOOP;
                    }
                }
            }
            $j = $ep;
            last;
        }
        $j = $ep+1;
    }
    $k = $j;
    $k = $end_pos if($k > $end_pos);
    $k = &::end_of_variable($k);
    return $k;
}

sub end_of_function
{
    my $pos = $_[0];
    my $result = _end_of_function($pos);
    if($::debug >= 3) {
        debug_start_end("end_of_function($pos) for =|%|= $ValPerl[$pos]($ValPy[$pos]) $result", $pos, $result);
    }
    return $result;
}

sub debug_start_end
# Point out where an expression starts and ends in the token string
# Pass in the debug message with the token string position marked with a '%'
# and the start and optionally the end
{
    my ($msg, $start, $end) = @_;

    return unless $::debug;
    my $pos = index($msg, '%');
    $TokenStr = join('', @ValClass) if $PassNo == PASS_1;
    say STDERR substr($msg, 0, $pos) . $TokenStr . substr($msg, $pos+1);
    return unless $::debug >= 3;
    my $spaces = ' ' x ($pos + $start);
    if(!defined $end || $end <= $start) {
        say STDERR "$spaces^";
    } else {
        my $spaces2 = ' ' x ($end-$start-1);
        say STDERR "$spaces^$spaces2^";
    }
}

sub get_here
#
#Extract here string with delimiter specified as the first argument
#The second argument, if true, means to remove leading whitespace from the result like <<~ does
#
{
my $here_str='';        # issue 39
# issue stdin my $line=<>;		# issue 39
my $line=<SYSIN>;		# issue 39, issue stdin
   $line =~ s/[\r\n]+//sg;        # issue 39
   if($::debug > 2 && $PassNo != PASS_0) {
      say STDERR "get_here($_[0], $_[1]): line=$line, lno=$.";
   }
   if(!defined $line) {
      logme('S', "Unclosed here string - terminiator '$_[0]' not found");
      return '""""""';
   }
   $line =~ /^(\s*)/;
   my $spaces = length($1);
   my $len_eof = length($_[0]);         # SNOOPYJC
   while (!((substr($line,0,length($_[0])) eq $_[0] && length($line) == $len_eof) || 
           ($_[1] && substr($line,$spaces,length($_[0])) eq $_[0] && length($line) == $spaces+$len_eof) )){
      # issue 39 $here_str.=$line;
      $here_str.=$line."\n";
      # issue stdin $line=<>;                 # issue 39
      $line=<SYSIN>;                 # issue 39, issue stdin
      if(!defined $line) {
         logme('S', "Unclosed here string - terminiator '$_[0]' not found");
	 last;
      }
      $line =~ s/[\r\n]//sg;        # issue 39
      if($::debug > 2 && $PassNo != PASS_0) {
   	say STDERR "get_here:line=$line, lno=$., len_eof=$len_eof, length(line)=".length($line).", spaces=$spaces, defined line=".defined $line;
      }
   }
   if($_[1]) {                  # Have the <<~ ?
       if($::debug > 2 && $PassNo != PASS_0) {
   	   say STDERR "get_here:here_str=$here_str (before strip)";
       }
       $here_str =~ s/^\s{$spaces}//gm;
   }
   if($::debug > 2 && $PassNo != PASS_0) {
   	say STDERR "get_here:here_str=$here_str";
   }
   if($PassNo == PASS_1) {              # SNOOPYJC: Propagate the prior varclasses
       &Perlscan::propagate_varclass_for_here();
   }
   # issue 39 return '""""'."\n".$here_str."\n".'"""""'."\n";
   return '"""'.$here_str.'"""';	# issue 39
} # get_here


sub getline
#
#get input line. It has now ability to buffer line, which will be scanned by tokeniser next.
# issue 45: if you pass in a 0, this means to defer outputting of blank and comment lines, which
# issue 45: will then be output on the next call.  Pass in a 1 just to do that output.
# issue s73: Pass a 2 if we're in the middle of a multi-line string and need to NOT ignore blank lines and comment lines
#
{
state @buffer; # buffer to "postponed lines. Used for translation of postfix conditinals among other things.
   #say STDERR "getline(@_): BufferValClass=@Perlscan::BufferValClass, buffer=@buffer, special_buffer=@special_buffer";
   # issue 95 return $line if( scalar(@Perlscan::BufferValClass)>0  ); # block input if we process token buffer Oct 8, 2020 -- NNB
   state @special_buffer;  # issue 42
   state @output_buffer;   # issue 45
   $flag = -1;                  # issue 45
   if ( scalar(@_) == 1 && 
        length( do { no if $] >= 5.022, "feature", "bitwise"; no warnings "numeric"; $_[0] & "" } ) ) {
       $flag = shift;           # issue 45: LOL all this just to see if I passed in a number or a string!
   }
   if($flag == 1) {             # issue 45: just output any buffered lines
       my ($o, $l, $i, $lno);
       $l = $IntactLno;
       $i = $IntactLine;
       $lno = $.;
       while($o = shift @output_buffer) {
           $IntactLno = $o->{ilno};              # issue s6
           $IntactLine = $o->{iline};            # issue s6
           $. = $o->{lno};                       # issue s6
           say STDERR "pop $IntactLno: $IntactLine" if($TraceIntactLine);
           output_line(@{$o->{args}});
       }
       $IntactLno = $l;
       $IntactLine = $i;
       $. = $lno;
       say STDERR "getline(1) = $.:$line" if $::debug >= 6;
       return $line;
   }
   # issue 42: if(  scalar(@_)>0 ){
   if(scalar(@_) == 1){         # issue 42: only allow 1 line
       return if(scalar(@_) == 1 && $_[0] eq '');       # SNOOPYJC: Don't make extra blank lines
       # issue 42 push(@buffer,@_); # buffer lines in the order they listed; they will be injected in the next call;
       push(@buffer,$_[0]); # buffer lines in the order they listed; they will be injected in the next call;
       #if (scalar(@_)==3){
       #  say join('|',@_);
       #  $DB::single = 1;
       #}
       if($::debug >= 6) {
          my (undef, $fn, $ln) = caller(0);
          say STDERR "getline(@_): pushed to buffer, returns undef (called from $fn:$ln)";
       }
       return;
   } elsif(scalar(@_) == 2) {   # issue 42: 2nd arg means push to special_buffer
       push(@special_buffer,$_[0]); # buffer lines in the order they listed; they will be injected in the next call;
       if($::debug >= 6) {
          my (undef, $fn, $ln) = caller(0);
          say STDERR "getline($_[0], $_[1]): pushed to special buffer, returns undef (called from $fn:$ln)";
       }
       return;
   }
   return $line if( scalar(@Perlscan::BufferValClass)>0  ); # issue 95: block input if we process token buffer Oct 8, 2020 -- NNB
   my $output_line = sub {                      # issue 45
       return if($PassNo != PASS_2);
       if($flag == 0) {
            my @args = @_;      # make a copy
            my $nargs = scalar(@args);
            say STDERR "push $IntactLno: $IntactLine (for $nargs: @args)" if($TraceIntactLine);
            my $push_record = {lno=>$., ilno=>$IntactLno, iline=>$IntactLine, args=>\@args};       # issue s6
            #$IntactLine = '';                   # issue s6
            # issue s6 push @output_buffer, \@args;
            push @output_buffer, $push_record;          # issue s6
        } else {
            output_line(@_);
        }
   };

   while(1 ){
      #
      # firs we perform debufferization
      #
      if(  scalar(@buffer) ){
         $line=shift(@buffer);
	     say STDERR "getline(): got $line from buffer, buffer=@buffer" if $::debug >= 6;
      }elsif(scalar(@special_buffer)) {         # issue 42
         $line = shift(@special_buffer);
         say STDERR "was: $. $::saved_eval_lno " . scalar(@special_buffer) if $::debug >= 6;
         if(scalar(@special_buffer) > 1) {
            $. = $::saved_eval_lno - (scalar(@special_buffer) - 0);     # CHECKME!
            say STDERR "is:  $. $::saved_eval_lno " . scalar(@special_buffer) if $::debug >= 6;
         }
	     say STDERR "getline(): got $.:$line from special_buffer" if $::debug >= 6;
      }elsif(defined $::saved_eval_tokens) {    # issue 42: Signal EOF from string we pushed
         $line = undef;
         say STDERR "getline(): returns undef because \$::saved_eval_tokens" if $::debug >= 6;
         return $line;
      }else{
            # issue s70 if($PassNo == PASS_2 && &Softpano::get_verbosity() >= 1) {		# issue ddts
            # issue stdin $line=<>;
            $line=<SYSIN>;      # issue stdin
            if(defined $f_encoding) {                   # issue s70
                if($line && $line =~ /[^\x00-\x7f]/) {           # issue s70: Does line contain non-ascii characters?
                    $line =~ s/^\x{FEFF}// if $. == 1;  # issue s70: Remove BOM
                    if(defined $f_decodobj) {           # issue s70
                        $line = $f_decodobj->decode($line, 0);  # issue s70: 0 means to ignore errors
                    } else {                            # issue s70
                        $line = fix_latin($line);       # issue s70
                        $f_encodobj = find_encoding('utf8') unless defined $f_encodobj; # issue s70
                    }                                   # issue s70
                }                                       # issue s70
            } else {                                    # issue s70
                if($line && $line =~ /[^\x00-\x7f]/) {           # issue s70: Does line contain non-ascii characters?
                    if($line =~ /^\x{FEFF}/) {          # issue s70: Does line contain windows utf8 BOM?
                        $line =~ s/^\x{FEFF}// if $. == 1;     # issue s70: Remove BOM
                    }
                    if(defined $e_option) {             # issue s70
                        my ($perl_encoding, $python_encoding) = split(/,/, $e_option);  # issue s70
                        $python_encoding = $perl_encoding if !defined $python_encoding && $perl_encoding; # issue  s70
                        $python_encoding = 'utf8' if !$python_encoding; # issue s70
                        $f_decodobj = find_encoding($perl_encoding) if $perl_encoding;    # issue s70
                        $f_encodobj = find_encoding($python_encoding);  # issue s70
                        $f_encoding = $f_encodobj->name;          # issue s70
                        $f_encoding =~ s/-strict//;               # issue s70
                        $f_encoding =~ s/utf-8/utf8/;             # issue s70
                        if(defined $f_decodobj) {                 # issue s70
                            $line = $f_decodobj->decode($line, 0);  # issue s70: 0 means to ignore errors
                        } else {                                  # issue s70
                            $line = fix_latin($line);             # issue s70
                        }                                         # issue s70
                    } else {
                        $line = fix_latin($line);
                        $f_encoding = 'utf8';
                        $f_encodobj = find_encoding('utf8') unless defined $f_encodobj; # issue s70
                    }
                }
            }
            # issue s70 } else {
            # issue s70 no warnings 'utf8';			# issue ddts: only give warnings in one pass and not with -v0
            # issue stdin $line=<>;
            # issue s70 $line=<SYSIN>;      # issue stdin
	        # issue s70 }
         #my $l2 = $line;
         #$l2 =~ s/[\n\r]//g;
         #say STDERR "$. getline(): got $l2 from <>, tell=" . tell(STDIN);
         if(!defined $line && $::debug) {
             say STDERR "getline: EOF on $fname at lno $.";
         } elsif($::debug >= 6) {
             my $l2 = $line;
             $l2 =~ s/[\n\r]//g;
             say STDERR "getline(): got $.:$l2 from <>, tell=" . tell(SYSIN);
         }
         return $line unless (defined($line)); # End of file
      }

      chomp($line);
      if($flag != 2 && (length($line)==0 || $line=~/^\s*$/ )){  # issue s73: check flag
         $IntactLno = $. unless($IntactLine);       # issue s6
         while($IntactEndLno < $.) {         # issue s6
              if($IntactLine) {
                  $IntactLine .= "\n";
              } else {
                  $IntactLine = ' ';
              }
              $IntactEndLno++;
         }
         $IntactEndLno = $.;    # issue s6
         &$output_line('');             # issue 45: blank line
         next;
      }elsif(  $flag != 2 && $line =~ /^\s*(#.*$)/ ){   # issue s73: check flag
         # pure comment lines
         my $comm = $1;
         if(($PassNo==PASS_0 || ($PassNo==PASS_1 && !$pass_0_ran)) && $line =~ /#\s*pragma\s*pythonizer/) {      # SNOOPYJC, issue s63
             if(  substr($line,-1,1) eq "\r" ){
                chop($line);
             }
             $IntactLine = $line;
             $line =~ s/^\s*#\s*//;
             $line .= ';';
             say STDERR "getline(): $.:$line" if $::debug >= 6;
             return $line;
         } elsif($. <= 2 && $line =~ /^[ \t\f]*#.*?coding[:=][ \t]*([-_.a-zA-Z0-9]+)/) {   # issue s70: Source specifies encoding
             $f_decodobj = find_encoding($1);          # issue s70
             $f_encodobj = $f_decodobj;                # issue s70
             if(defined $f_decodobj) {                 # issue s70
                $f_encoding = $f_decodobj->name;          # issue s70
                $f_encoding =~ s/-strict//;               # issue s70
                $f_encoding =~ s/utf-8/utf8/;             # issue s70
                $comm = '';                                    # issue s70
             } else {
                 logme('W', "Can't find decoder for '$1' encoding - ignoring specified encoding!");
             }
         }
         $IntactLno = $. unless($IntactLine);       # issue s6
         while($IntactEndLno < $.) {         # issue s6
              if($IntactLine) {
                  $IntactLine .= "\n";
              } else {
                  $IntactLine = ' ';
              }
              $IntactEndLno++;
         }
         $IntactEndLno = $.;    # issue s6
         &$output_line('',$comm);          # issue 45
         next;
      }elsif(  $flag != 2 && ($line =~ /^__DATA__/ || $line =~ /^__END__/)){    # issue s73: Check flag
         # data block
         # SNOOPYJC return undef if(  $PassNo==0 );
         if(  $PassNo!=PASS_2 ) {            # SNOOPYJC
             # issue stdin while($line = <> ) {       # SNOOPYJC: Read in the rest of the file and discard so in the next pass we start over
             while($line = <SYSIN> ) {       # issue stdin, SNOOPYJC: Read in the rest of the file and discard so in the next pass we start over
                 ;
             }
             say STDERR "getline(): returns undef for __DATA__ or __END__" if $::debug >= 6;
             return undef;
         }

         open(SYSDATA,'>',"$source_file.data") || abend("Can't open file $source_file.data for writing. Check permissions" );
         logme('W',"Tail data after __DATA__ or __END__ line are detected in Perl Script. They are written to a separate file $source_file.data");
         # issue stdin while( $line=<> ){
         while( $line=<SYSIN> ){        # issue stdin
            print SYSDATA $line;
         }
         close SYSDATA;
         return $line;
      # SNOOPYJC }elsif(  substr($line,0,1) eq '=' ){
      }elsif(  $flag != 2 && substr($line,0,1) eq '=' && substr($line,1,1) =~ /\w/) {	# SNOOPYJC: Not '==', not '=~', etc, issue s73: check flag
         # POD block
         # issue 79 output_line('',q['''']);
         &$output_line('',q[''']);                # issue 79, issue 45
         &$output_line('',$line,1);               # issue 79, issue 45
         # issue stdin while($line=<>){
         while($line=<SYSIN>){  # issue stdin
             # issue 79 last if( $line eq '=cut');
            chomp($line);
            $line =~ s/'''/"""/g;             # issue s61: We can't support lines that contain '''
            &$output_line('',$line,1);            # issue 79, issue 45
            if( substr($line,0,4) eq '=cut') {      # issue 79
                # issue stdin $line = <>;                         # issue 79
                $line = <SYSIN>;                         # issue 79, issue stdin
                chomp($line) if defined $line;                   # SNOOPYJC
                last;
            }
         }
         # issue 79 output_line('',q['''']) if(  $PassNo);
         &$output_line('',q[''']);      # issue 79, issue 45
      }elsif( $flag != 2 && substr($line,0,5) eq 'goto ') {   # SNOOPYJC: strange way to skip some code, issue s73: check flag
         $line =~ /goto\s+([A-Za-z0-9_]+)/;
         $label = $1;
         if(!exists $Perlscan::all_labels{$label}) {        # issue error_goto
             &$output_line('',q[''']);              # issue 45
             &$output_line('',$line,1);             # issue 45
             # issue stdin while($line=<>){
             while($line=<SYSIN>){          # issue stdin
                &$output_line('', $line,1);         # issue 45
                if( $line =~ /^$label:/ ) {
                    # issue stdin $line = <>; 
                    $line = <SYSIN>;        # issue stdin
                    chomp($line);                   # SNOOPYJC
                    last;
                }
             }
             &$output_line('',q[''']);              # issue 45
         }
      }

      return $line if(!defined $line);          # issue 79 - gives lots of errors below if we hit EOF

      if(  substr($line,-1,1) eq "\r" ){
         chop($line);
      }
      # SNOOPYJC NOT GOOD IF WE ARE IN A STRING!! $line =~ s/\s+$//; # trim tailing blanks
      # SNOOPYJC NOT GOOD IF WE ARE IN A STRING!! $line =~ s/^\s+//; # trim leading blanks
      # SNOOPYJC if ($line eq '{' || $line eq '}') {
      if($PassNo != PASS_2) {
          $IntactLine = '';
      } elsif($IntactEndLno != $.) {            # issue s6
          #if ($line =~ m'^\s*[{]\s*$' || $line =~ m'^\s*[}]\s*$') { # SNOOPYJC
          #$IntactLine='';
          #}elsif($line eq '^') {            # issue s5
          while($IntactEndLno < $.) {         # issue s6
              if($IntactLine) {
                  $IntactLine .= "\n";
              } else {
                  $IntactLine = ' ';
              }
              $IntactEndLno++;
          }
          if($line eq '^') {            # issue s5
              if($IntactLine) {
                  $IntactLine .= "\n{" if($IntactLine ne '{');            # issue s5
              } else {
                  $IntactLine = "{";               # issue s5
                  $IntactLno = $.;
              }
          }else{
              # issue s5 $IntactLine=$line;
             my $il = $line;
             $il =~ s/\s+$//;       # SNOOPYJC
             $il =~ s/^\s+//;       # SNOOPYJC
             if($IntactLine) {                  # issue s5
                 $IntactLine .= "\n" . $il if($il && $il ne $IntactLine);     # issue s5
             } else {                           # issue s5
                 $IntactLine = $il;             # issue s5
                 $IntactLno = $.;
             }                                  # issue s5
          }
          $IntactEndLno = $.;                  # issue s6
          say STDERR "$IntactLno $IntactLine (endLno=$.)" if($TraceIntactLine);
          if(scalar(@output_buffer)) {          # issue s6
              $output_buffer[-1]->{iline} .= "\n" . $IntactLine;
              #$IntactLine = '';
              say STDERR "appended" if($TraceIntactLine);
          }
      } else {
          say STDERR "skipped $. $line" if($TraceIntactLine);
      }
      say STDERR "getline(): $.:$line" if $::debug >= 6;
      return  $line;
   }
}

#::output_line -- Output line shifted properly to the current nesting level
# arg 1 -- actual PseudoPython generated line
# arg 2 -- tail comment (added Dec 28, 2019)
# arg 3 -- copy without processing ( (added Sep 3, 2020))
sub output_line
{
return if ($PassNo!=PASS_2); # no output during the first passes
my $line=(scalar(@_)==0 ) ? $IntactLine : $_[0];
my $tailcomment=(scalar(@_)>=2 ) ? $_[1] : '';          # SNOOPYJC
my $indent=' ' x $::TabSize x $CurNest;
my $flag=( defined($main::TrStatus) && $main::TrStatus < 0 ) ? 'F' : ' ';
my $len=length($line);
my $prefix=sprintf('%4u',$.)." |".sprintf('%2u',$CurNest)." | ".sprintf('%1s',$flag)." |";
#my $prefix=sprintf('%4u',$IntactLno)." |".sprintf('%2u',$CurNest)." | ".sprintf('%1s',$flag)." |";
my $zone_size=($maxlinelen-length($prefix))/2; # length of prefix is 20
my $start_of_comment_zone=$zone_size+length($prefix); #  the start of comment_zone is 20+80=100.
#                                                   So the total line length=180
my $orig_tail_len=length($tailcomment);
$tailcomment .= ' # I_M_P_O_R_T' if &Perlscan::in_starting_BEGIN();     # issue s325: Put this BEGIN block's code first
my $i;
$tailcomment = $f_encodobj->encode($tailcomment, 0) if $tailcomment && defined $f_encodobj;   # issue s70
my $orig_tail_comment = $tailcomment;

   $GeneratedCode = (scalar(@_) > 0 && $line);          # issue 96
   if(  $tailcomment){
       if (scalar(@_) < 3) {            # SNOOPYJC
           $tailcomment=($tailcomment=~/^\s+(.*)$/ ) ? $indent.$1 : $indent.$tailcomment;
       }
       $tailcomment =~ s/[\r]//g;       # SNOOPYJC - remove CR when run on Windoze
   }
   # Special case of empty line or "pure" comment that needs to be indented
   if(  $len==0 ){
      if(  $::TrStatus < 0 ){
         # issue bootstrap out($prefix,join(' ',@::ValPy)." #FAIL $IntactLine");
         # issue bootstrap say SYSOUT join(' ',@::ValPy)." #FAIL $IntactLine";
         out($prefix,join(' ',@ValPy)." #FAIL $IntactLine");	# issue bootstrap
         say SYSOUT join(' ',@ValPy)." #FAIL $IntactLine";	# issue bootstrap
      }else{
         out($prefix,$tailcomment);
         say SYSOUT $tailcomment;
      }
      return;
   }
   if(  scalar(@_)<3){
      $line=($line=~/^\s+(.*)$/ )? $indent.$1 : $indent.$line;
   }
   $line = $f_encodobj->encode($line, 0) if $line && defined $f_encodobj;   # issue s70
   if($orig_tail_comment) {     # SNOOPYJC
      say SYSOUT "$line    $orig_tail_comment";       # SNOOPYJC
   } else {
      say SYSOUT $line;
   }
   $line=$prefix.$line;
   $len=length($line); # new length woth prefix containing line no and nesting
my (@lineblock,$filler);
   $IntactLine = $f_encodobj->encode($IntactLine, 0) if $IntactLine && defined $f_encodobj;   # issue s70
   if( scalar(@_)==1){
      # no tailcomment
      if(  $IntactLine=~/^\s+(.*)$/ ){
         $IntactLine=$1;
      }
      if(  $len > $start_of_comment_zone ){
         # long line
         if(  length($IntactLine) > $zone_size ){
            out($line);
            if (index($IntactLine,"\n")==-1){
                print_intactline($IntactLine,$zone_size,$start_of_comment_zone);
                $IntactLine = '';       # issue s6
                #$IntactLno++;           # issue s6
            }else{
               @lineblock=split("\n",$IntactLine);
               print_intactline($lineblock[0],$zone_size,$start_of_comment_zone);
               #$IntactLno++;           # issue s6
               # issue s6 for(my $i=1; $i<@lineblock;$i++){
               for(my $i=1; $i<$#lineblock;$i++){       # issue s6
                  $IntactLno++;           # issue s6
                  print_intactline($lineblock[$i],$zone_size,$start_of_comment_zone);
               }
               $IntactLine = $lineblock[-1];            # issue s6
            }
         }else{
            out($line,' #PL: ',$IntactLine);
            #$IntactLno++ if($IntactLine);        # issue s6
            $IntactLine = '';       # issue s6
         }
     }else{
         # short line without tail comment
         $filler=' ' x ($start_of_comment_zone-$len);
          if (index($IntactLine,"\n")==-1){
              out($line,$filler,' #PL: ',$IntactLine);
              #$IntactLno++ if($IntactLine);        # issue s6
              $IntactLine = '';       # issue s6
          }else{
             @lineblock=split("\n",$IntactLine);
             out($line,$filler,' #PL: ',$lineblock[0]); # its short so this is OK
             #$IntactLno++;           # issue s6
             # issue s6 for( $i=1; $i<@lineblock;$i++){
             for( $i=1; $i<$#lineblock;$i++){   # issue s6
                $IntactLno++;           # issue s6
                print_intactline($lineblock[$i],$zone_size,$start_of_comment_zone);
             }
             $IntactLine = $lineblock[-1];            # issue s6
          }
      }
   }else{
     #line with tail comment
     $i=index($tailcomment,"\n");
     if($i==-1) {
        out($line,' ',$tailcomment); # output with the original comment instead of Perl source
        print_intactline(substr($IntactLine,0,-$orig_tail_len),$zone_size,$start_of_comment_zone); # print Perl source
        $IntactLine = '';       # issue s6
        $IntactLno++;           # issue s6
     }else{
        @lineblock=split("\n",$IntactLine);
        out($line,' ',$tailcomment); # output with tail comment instead of Perl comment
        print_intactline(substr($lineblock[0],0,-$orig_tail_len),$zone_size,$start_of_comment_zone);
        $IntactLno++;           # issue s6
        # issue s6 for( $i=1; $i<@lineblock;$i++){
        for( $i=1; $i<$#lineblock;$i++){        # issue s6
            print_intactline($lineblock[$i],$zone_size,$start_of_comment_zone);
            $IntactLno++;           # issue s6
        }
        $IntactLine = $lineblock[-1];            # issue s6
     }
   }
   #$IntactLine = '';            # issue s6

} # output_line
sub print_intactline
{
my ($IntactLine,$zone_size,$start_of_comment_zone)=@_;
my $filling=' ' x $start_of_comment_zone;
   if(  length($IntactLine) > $zone_size ){
      out( $filling,' #PL: ',substr($IntactLine,0,$zone_size));
      out( $filling,' #+ : ',substr($IntactLine,$zone_size));
   }else{
      out($filling,' #PL: ',$IntactLine);
   }
}

sub correct_nest
# Ensure proper indenting of the lines. Accepts two arguments
#  if no arguments given it sets $CurNest=$NextNest;
#  If only 1 ARG given inrements/decreaments $NextNest;
#     NOTE: If zero is given sets NextNest to zero.
#  if two arguments are given increments/decrements both NexNext and $CurNest
#     NOTE: Special case -- if 0,0 is passed both set to zero
# Each argument checked against the min and max threholds befor processing. If the threshold exceeded the operation ignored.
{
    say STDERR "correct_nest(@_)" if($::debug >= 5 && $PassNo != PASS_0);
my $delta;
   if(  scalar(@_)==0 ){
      # if no arguments given  set NextNest equal to CurNest
      $CurNest=$NextNest;
      return;
   }
   $delta=$_[0];
   if(  $delta==0 && scalar(@_)==1 ){
      $NextNest=0;
      return;
   }
   if(  $NextNest+$delta > $MAXNESTING ){
      if ($::debug>2) {
         logme('E',"Attempt to set next nesting level above the threshold($MAXNESTING) ignored");
	 #$DB::single = 1;
      }
   }elsif(  $NextNest+$delta < 0 ){
      if ($::debug>2 ) {
         logme('S',"Attempt to set the next nesting level below zero ignored");
	 #$DB::single = 1;
      }
   }else{
     $NextNest+=$delta;
   }

   if( scalar(@_)==2){
       $delta=$_[1];
       if(  $delta==0 && $_[0]==0){
          $CurNest=$NextNest=0;
          return;
       }
       if(  $delta+$CurNest>$MAXNESTING ){
          logme('E',"Attempt to set current nesting level above the treshold($MAXNESTING) ignored");
       }elsif( $delta+$CurNest<0){
          logme('S',"Attempt to set the curent nesting level below zero ignored");
       }else{
         $CurNest+=$delta;
       }
   }
}

sub save_nest       # issue s155
{
    say STDERR "save_nest() = [$CurNest, $NextNest, $GeneratedCode]" if($::debug);
    return [$CurNest, $NextNest, $GeneratedCode];
}

sub restore_nest    # issue s155
{
    my $saved = $_[0];
    $CurNest = $saved->[0];
    $NextNest = $saved->[1];
    $GeneratedCode = $saved->[2];
    say STDERR "restore_nest([$CurNest, $NextNest, $GeneratedCode])" if($::debug);
}

# based on https://www.geeksforgeeks.org/topological-sorting/
sub toposort_util
{
    my ($deps, $node, $visited, $stack) = @_;

    $visited->{$node} = 1;
    my @depa = $deps->($node);
    for my $i (@depa) {
        toposort_util($deps, $i, $visited, $stack) unless($visited->{$i});
    }
    push @{$stack}, $node;
}

sub toposort
{
# Given a dependency graph $deps = ('a' => ['b', 'c'], b => ['d'], ... z=> []), and a list of elements ($in),
# return a sorted list
  my ($deps, $in) = @_;
  my @stack = ();
  my %visited = ();
  for my $node (@{$in}) {
      toposort_util($deps, $node, \%visited, \@stack) unless($visited{$node});
  }
  my @out = reverse @stack;
  wantarray ? @out : \@out;
}

sub move_defs_before_refs		# SNOOPYJC: move definitions up before references in the output file
# NOTE: Issue s155 made this a bit more complicated because it generates nested subs that we have to move
# in order to generate correct code.  The nested subs can be anywhere in the outer sub, which is typically
# a BEGIN {...}, but can also just be a {...}.
{
    #return;     # TEMP
    close SYSOUT;
    open(SYSOUT,'<',$output_file);
    # Pass 1 - find all the defs
    my %defs = ();
    no warnings 'utf8';
    chomp(my @lines = <SYSOUT>);
    close SYSOUT;
    if($::debug >= 6) {
        say STDERR "---------- Generated code before move_defs_before_refs ----------";
        for(my $i = 1; $i <= @lines; $i++) {
            say STDERR "$i: " . $lines[$i-1];
        }
    }
    my $preserve_output = 0;    # TEMP
    if($preserve_output) {
        open(TMPOUT, '>', $output_file . '.bak');
        for my $line (@lines) {
            say TMPOUT $line;
        }
        close(TMPOUT);
    }
    #$DB::single = 1;
    $lno = 0;
    my @unsorted = ();
    my %dependencies = ('__main__'=>[]);
    my $insertion_point = 0;
    my @init_package_lnos = ();
    my @import_lnos = ();                       # issue s18
    my @nested = ();                            # issue s3
    for my $line (@lines){
        $lno++;
        # issue 24 $insertion_point = $lno+1 if($line =~ /^$PERL_ARG_ARRAY = sys.argv/ && !$insertion_point);              # SNOOPYJC
        $insertion_point = $lno+1 if($line =~ /^pass # LAST_HEADER/ && !$insertion_point);          # issue 24
        next if(!$insertion_point);     # Ignore everything above our insertion point
        # issue s126: if($line =~ /^def ([A-Za-z0-9_]+)/ || $line =~ /^class ([A-Za-z0-9_]+)/ ||
        # issue s126:    $line =~ /^(_[A-Za-z][A-Za-z0-9_]+) = _[A-Za-z][A-Za-z0-9_]/) {  # issue test coverage: handle _ArrayHashClass = _partialclass(_ArrayHash, ArrayHash) as a def
        # issue s126:                                                                    # but don't match _d = _d[0:-1]
        if($line =~ /# I_M_P_O_R_T/) {         # issue s18, issue s325
            push @import_lnos, $lno;                # issue s18
        } elsif($line =~ /^\s+def ((?:$ANONYMOUS_SUB)[A-Za-z0-9_]+)/) {            # issue s3, issue s340 (moved code up)
            my $func = $1;
            push @nested, $func;
            $defs{$func} = $lno;
        } elsif($line =~ /^def ([A-Za-z0-9_]+)/ || $line =~ /^class ([A-Za-z0-9_]+)/ ||
           $line =~ /^(_(?:PACK_TO_STRUCT|TEMPLATE_LENGTH|decoding_map|encoding_map|fileinput_iter|finditer_pattern|finditer_string|finditer_iter)) =/ ||   # issue s270
           $line =~ /^(Data\.Dumper\.[A-Za-z0-9_]+) =.*# InIt/      # issue s270
          ) {  # issue s126: Don't match _ArrayHashClass = _partialclass(...) as a def so we don't move it
            my $i;
            my $func = $1;
            push @unsorted, $func;
            $dependencies{$func} = [];
            if($line =~ /^(?:def|class) /) {            # issue s270: Only pull in blank lines or comments on real def/class statements, not special vars
                for($i = $lno-1; $i >= 1; $i--) {
                    # Grab any prior blank lines or comments or decorators
                    if($lines[$i-1] =~ /^\s*$/ || $lines[$i-1] =~ /^\s*#/ || $lines[$i-1] =~ m'^@') {
                        ;
                    } else {
                        $i++;
                        last;
                    }
                }
            } else {            # issue s270
                $i = $lno;      # issue s270
            }                   # issue s270
            $defs{$func} = $i;
        } elsif($line =~ /^_init_package\(/ || $line =~ /^$PERLLIB\.init_package\(/) {
            push @init_package_lnos, $lno unless exists $::deferred_init_package_lines{$line};      # issue s18
        }
    }
    # Pass 2 - find all the refs
    my @words = keys %defs;
    say STDERR "move_defs_before_refs: Defs @{[%defs]}" if($::debug >= 3);
    my %refs = ();
    $insertion_point = 0;
    $lno = 0;
    my $in_def = undef;
    my $in_def2 = undef;                # issue s155: Allow defs to be nested up to 2 levels
    my %def_package = ();               # issue s18: What package is this def in?
    my %f_refs=();
    my %if_tracker=();          # issue s340: Tracks 'if' lno
    my $in_elif = 0;            # issue s340
    my $track_lno;              # issue s340
    for my $Line (@lines) {
        $lno++;
        # issue 24 $insertion_point = $lno+1 if($Line =~ /^$PERL_ARG_ARRAY = sys.argv/ && !$insertion_point);              # SNOOPYJC
        $insertion_point = $lno+1 if($Line =~ /^pass # LAST_HEADER/ && !$insertion_point);          # issue 24
        #say STDERR "$lno: $line";	# TEMP
        $line = eat_strings($Line);     # we change variables so eat_strings doesn't modify @lines
        if($in_elif) {                  # issue s340: elif may be several lines long e.g. if it contains a multi-line string
            if($line =~ /:(?:\s+#.*)?$/) {  # issue s340
                $in_elif = 0;               # issue s340
            }                               # issue s340
        } else {                            # issue s340
            $track_lno = $lno;              # issue s340: Track a reference in an elif back to the if
        }                                   # issue s340
        if($line =~ /^(\s*if)\b/) {     # issue s340
            $if_tracker{$1} = $lno;     # issue s340
        } elsif($line =~ /^(\s*elif)\b/) {  # issue s340
            my $my_if = $1;             # issue s340
            $my_if =~ s/elif$/if/;      # issue s340
            $track_lno = $if_tracker{$my_if} if exists $if_tracker{$my_if}; # issue s340
            $in_elif = 1 unless $line =~ /:(?:\s+#.*)?$/;    # issue s340
        } elsif($line =~ /^(\s*else)\b/) {  # issue s340
            my $my_if = $1;             # issue s340
            $my_if =~ s/else$/if/;      # issue s340
            delete $if_tracker{$my_if}; # issue s340
        }                               # issue s340
        if($in_def) {
            # issue s126 $in_def = undef if($line !~ /^def / && $line !~ /^class / && length($line) >= 1 && $line !~ /^\s*#/ && $line !~ /^\s/ && !$multiline_string_sep);
            if($line =~ /^([A-Za-z0-9.]+)[.]$in_def = types[.]MethodType\($in_def,/ ||
  # issue s216 $line =~ /^([A-Za-z0-9.]+)[.]$in_def = lambda \*_args: $in_def\(/ ||
  # issue s304 $line =~ /^([A-Za-z0-9.]+)[.]$in_def = lambda \*_args.*tie_call\($in_def,/ ||   # issue s216
               $line =~ /^([A-Za-z0-9.]+)[.]$in_def = .*add_tie_call\($in_def,/ ||   # issue s304
               $line =~ /^([A-Za-z0-9.]+)[.]$in_def = $in_def$/) {     # issue s18
               $def_package{$in_def} = $1;                             # issue s18
            }                                                          # issue s18
            if($in_def eq '_encoding_map') {        # issue s270: This one is only 1 line
                $in_def = $in_def2;                 # issue s270
                $in_def = undef;                    # issue s270
            }                                       # issue s270
            if($line !~ /^def / && $line !~ /^class / && length($line) >= 1 && $line !~ /^\s*#/ && $line !~ /^\s/ && !$multiline_string_sep && # issue s126
                               $line !~ /^_[A-Za-z][A-Za-z0-9_]+ = $in_def\(/) {       # issue s126: still in_def on _ArrayHashClass = _partialclass(...)
                # issue s155 $in_def = undef;
                $in_def = $in_def2;                 # issue s155
                $in_def2 = undef;                   # issue s155
                #say STDERR "Not in_def on $line" unless defined $in_def;	# TEMP
            }
        }
        # issue s126 if($line =~ /^def ([A-Za-z0-9_]+)/ || $line =~ /^class ([A-Za-z0-9_]+)/ ||
        # issue s126    $line =~ /^(_[A-Za-z][A-Za-z0-9_]+) = _[A-Za-z][A-Za-z0-9_]/) {          # issue test coverage
        if($line =~ /^def ([A-Za-z0-9_]+)/ || $line =~ /^class ([A-Za-z0-9_]+)/ ||
           $line =~ /^(_encoding_map) =/                                  # issue s270
           ) {  # issue s126: Don't handle _ArrayHashClass = _partialclass(...) as a def
            $in_def2 = $in_def;             # issue s155
            $in_def = $1;
            #say STDERR "in_def $in_def on $line";	# TEMP
        }
        ### YES THEY DO!!  next if($in_def);               # Refs inside of defs don't matter
        next if($line =~ /^def / || $line =~ /^class /);
        next if($line =~ /^\s*#/);      # ignore comments
        #my @found = grep { $line =~ /\b$_\(/ } @words;  # Look for calls of this function only
        # issue s270 my @found = grep { $line =~ /\b$_[(),]/ } @words;  # issue s3: Look for calls of this function and other references
        my @found = grep { $line =~ /\b$_[(),:}=\] ]/ } @words;  # issue s3: Look for calls of this function and other references, issue s270: add ':}=] '
        #say STDERR "found @found in $lno: $line" if(@found);	# TEMP
        foreach $f (@found) {
            next if $line =~ /^\s+def $f/;      # issue test coverage: Not a ref of __add__ if this is a separate def of __add__ like in a different class
            next if $line =~ /\bself\.$f/;      # issue test coverage; Not a ref of __str__ if this is a self.__str__ ref - that's a different one!
            if($in_def) {
	            #say STDERR "Adding f_refs{$in_def}{$f} = 1 on $lno: $line";	# TEMP
                $f_refs{$in_def}{$f} = 1;
                #push @{$dependencies{$in_def}}, $f;
                #say STDERR "Adding $in_def to dependencies{$f} on $lno: $line" if($f ne $in_def);  # TEMP
                push @{$dependencies{$f}}, $in_def if($f ne $in_def);   # Ignore recursive refs
            }
            if(!defined $refs{$f}) {    # Only put in the first one
                #say STDERR "Adding refs{$f} = $lno: $line";			# TEMP
                # issue s340 $refs{$f} = $lno;
                $refs{$f} = $track_lno;             # issue s340: Real lno or lno of 'if' if we are in 'elif'
                #push @{$dependencies{main}}, $f;
                #say STDERR "Adding __main__ to dependencies{$f} on $lno: $line";			# TEMP
                push @{$dependencies{$f}}, '__main__';
                if($f eq '_partialclass') {                         # issue s126
                    push @{$dependencies{$f}}, '_init_package';     # issue s126
                }                                                   # issue s126
            }
        }
    }
    say STDERR "move_defs_before_refs: Refs @{[%refs]}" if($::debug >= 3);
    return if(!$insertion_point);
    #
    # We need to put _init_package() first so we can insert all the calls to it right after the def,
    # we do that by making it dependent on everything else
    #

    if(exists $refs{_init_package}) {
        for my $f (@unsorted) {
            next if($f eq '_init_package');     # Don't make it dependent on itself
            if(exists($PYF_CALLS{_init_package})) {             # issue test coverage: Don't make it dependent on things it depends on
                next if(index($PYF_CALLS{_init_package}, $f) >= 0);     # these dependencies happens if is_class and autovivification are both true
            }
            push @{$dependencies{_init_package}}, $f;
        }
    }

    if($::debug >= 3) {
        $Data::Dumper::Indent=0;
        $Data::Dumper::Terse = 1;
        say STDERR "dependencies: ";
        say STDERR Dumper(\%dependencies);
    }

    my $children = sub { @{$dependencies{$_[0]} || []} };
    push @unsorted, '__main__';
    @ordered_to_move = toposort($children, \@unsorted);

    my $size = scalar(@ordered_to_move);
    return if(!cleanup_imports(\@lines) && $size == 0);      # nothing to do
    #say STDERR "to_move_first: @{[%to_move_first]}" if($::debug >= 3);
    #say STDERR "to_move: @{[%to_move]}" if($::debug >= 3);
    say STDERR "ordered_to_move: @ordered_to_move" if($::debug >= 3);

    my %nested_issues = ();                     # issue s3: map from insertion point lno to the lno of the nested function
    say STDERR "\@nested: " . Dumper(\@nested) if(scalar @nested && $::debug >= 3);
    for my $n (@nested) {                       # issue s3
        if(exists $refs{$n} && $refs{$n} < $defs{$n}) {
            if(exists $nested_issues{$refs{$n}}) {      # issue s340
                $nested_issues{$refs{$n}} .= ',' . $defs{$n};   # issue s340
            } else {                                    # issue s340
                $nested_issues{$refs{$n}} = $defs{$n};
            }
        }
    }
    #say STDERR "nested_issues: @{[%nested_issues]}" if($::debug >= 3);  # issue s3
    say STDERR "nested_issues: " . Dumper(\%nested_issues) if($::debug >= 3);  # issue s3

    if(%nested_issues) {                        # issue s3
        my $lno = 0;
        my @output_lines = ();
        my %moved_lines = ();
        for my $line (@lines) {
            $lno++;
            if(exists $nested_issues{$lno}) {                       # issue s3
                # we have a reference to a function that's defined later in the code - move
                # that function code here and adjust any nesting issues
                $line =~ /^(\s*)/;
                my $target_indent = length($1);
                my $function_lnos = $nested_issues{$lno};       # issue s340
                my @function_lnos = split /,/, $function_lnos;  # issue s340
                # issue s340 my $function_lno = $nested_issues{$lno};
                foreach my $function_lno (@function_lnos) {     # issue s340
                    say STDERR "Handling nested issue on line $function_lno with ref on line $lno" if($::debug >= 5);
                    $lines[$function_lno-1] =~ /^(\s*)/;
                    my $source_indent = length($1);
                    my $indent = ' ' x ($target_indent - $source_indent);
                    my $moved_def = 0;
                    for(my $i=$function_lno-1; $i<scalar(@lines); $i++) {
                        $lines[$i] =~ /^(\s*)/;
                        my $cur_indent = length($1);
                        last if $cur_indent <= $source_indent && $moved_def;
                        $moved_def = 1 if($lines[$i] =~ /^\s*def /);
                        $moved_lines{$i+1} = 1;
                        push @output_lines, ($indent . $lines[$i]);
                    }
                }                                               # issue s340
                push @output_lines, $line;
            } elsif(!exists $moved_lines{$lno}) {
                push @output_lines, $line;
            }
        }
        @lines = @output_lines;
        if($::debug >= 6) {
            say STDERR "---------- Generated code after fixing nested_issues ----------";
            for(my $i = 1; $i <= @lines; $i++) {
                say STDERR "$i: " . $lines[$i-1];
            }
        }
    }
    
    # Pass 3 - regenerate the output file in the right order

    open($sysout,'>',$output_file);
    $lno = 0;
    my %moved_lines = ();
    my $multiline_string_sep = '';
    # issue s18: test case is RefsMain.pm.  Contains a "require Exporting" and also @ISA='Exporting' so
    # we have to import Exporting, then do the init_package for RefsMain.  Only after then can we
    # put code that sets or uses RefsMain, such as "RefsMain.set_main = set_main".
    # We use %deferred_lines to hold the lines of "def set_main" until it's package is defined
    my %deferred_lines = ();                    # issue s18: Package => lines
    my %packages_initialized = ();              # issue s18
    for my $line (@lines) {
        $lno++;
        next if($line eq '^');          # This means "delete this line"
        if($lno < $insertion_point) {
           my $gen_try_fcntl = 0;                       # issue test coverage
           if((!$::import_perllib) && $line =~ /^import / && ($^O eq 'MSWin32' || $^O eq 'msys') && $line =~ /\bfcntl/) {   # issue test coverage
                $line =~ s/ fcntl,/ /;
                $line =~ s/,fcntl//;
                $gen_try_fcntl = 1;
           }
           pep8($sysout, $line);
           if($gen_try_fcntl) {
               pep8($sysout, 'try:');
               pep8($sysout, '    import fcntl');
               pep8($sysout, 'except Exception:');
               pep8($sysout, '    pass');
           }
           next
        }
        for my $ip_lno (@import_lnos) {             # issue s18
            my $ln = $lines[$ip_lno-1];             # issue s18
            $ln =~ s/ # I_M_P_O_R_T//;              # issue s18
            pep8($sysout, $ln);                     # issue s18
            $moved_lines{$ip_lno} = 1;              # issue s18
        }                                           # issue s18
        @import_lnos = ();                          # issue s18
        if($::import_perllib) {
            for my $ip_lno (@init_package_lnos) {
                my $ln = $lines[$ip_lno-1];        # issue s18
                if($ln =~ /^$PERLLIB\.init_package\('([A-Za-z0-9._]+)'/) {  # issue s18
                    $packages_initialized{$1} = 1;                          # issue s18
                }                                                           # issue s18
                pep8($sysout, $ln);                 # issue s18
                $moved_lines{$ip_lno} = 1;
            }
            @init_package_lnos = ();
        }
        for my $func (@ordered_to_move) {
            next if $func eq '__main__';
            next if !exists $defs{$func};         # issue code coverage: e.g. class Die is referenced but the definition is not found
            $start_line = $defs{$func};
            say STDERR "Handling $func on line $start_line" if($::debug >= 5);
            my $moved_def = 0;
            my $lines_moved = 0;
            my $already_moved = 0;
            $multiline_string_sep = '';
            for(my $i=$start_line-1; $i<scalar(@lines); $i++) {
                if($multiline_string_sep) {
                    unless(exists $moved_lines{$i+1}) {
                        say $sysout $lines[$i];
                        $moved_lines{$i+1} = 1;
                        $lines_moved++;
                    } else {
                        $already_moved++;
                    }
                    $multiline_string_sep = '' if(index($lines[$i], $multiline_string_sep) >= 0);
                    next;
                } elsif(($lines[$i] =~ /"""/ || $lines[$i] =~ /'''/) && $lines[$i] !~ /^\s*#/) {
                    # "'''" and '"""' are NOT the start of a multi-line comment
                    my $pos = 0;
                    my $ndx;
                    while(1) {
                        my $comment_start = index($lines[$i], ' #', $pos);
                        $ndx = index($lines[$i], '"', $pos);
                        $ndx = index($lines[$i], "'", $pos) if $ndx < 0;
                        last if($ndx < 0 || ($comment_start >=0 && $ndx > $comment_start));
                        my $quote = substr($lines[$i],$ndx,1);
                        my $we3 = substr($lines[$i],$ndx,3);
                        if($we3 ne '"""' && $we3 ne "'''") {        # we have a single or double-quoted string, possibly with the ''' or """ inside
                            my $found_close = 0;
                            for(my $j = $ndx+1; $j < length($lines[$i]); $j++) {
                                if(substr($lines[$i],$j,1) eq $quote && !&Perlscan::is_escaped($lines[$i],$j)) {
                                    $pos = $j+1;
                                    $found_close = 1;
                                    last;
                                }
                            }
                            last if(!$found_close);
                        } else {        # We found a triple-quote

                            # $ndx = index($lines[$i], '"""');
                            # $ndx = index($lines[$i], "'''") if $ndx < 0;
                            $multiline_string_sep = substr($lines[$i],$ndx,3);
                            # if the string terminates on the same line, then it's not a multiline string
                            $multiline_string_sep = '' if(index($lines[$i], $multiline_string_sep, $ndx+3) >= 0);
                            last;
                        }
                    }
                }
                if($lines[$i] =~ /^\s+/ || $lines[$i] =~ /^def $func\(/ || $lines[$i] =~ /^class $func[(:]/ ||
                        $lines[$i] =~ /^$func = _/ ||           # issue test coverage
                        $lines[$i] =~ /^_[A-Za-z0-9_]+ = $func\(_/ ||           # issue s126: handle _ArrayHashClass = _partialClass(...)
                        $lines[$i] =~ /^\s*$/ || $lines[$i] =~ /^\s*#/ || $lines[$i] =~ m'^@' ||
			            $lines[$i] =~ /^${func}_[\w]+ =/ ||	 # state variable like func_var = init
                        $lines[$i] =~ /[.]$func = types[.]MethodType\($func,/ ||     # issue s3
           # issue s216 $lines[$i] =~ /[.]$func = lambda \*_args: $func\(/ ||     # issue s154
           # issue s304 $lines[$i] =~ /[.]$func = lambda \*_args.*tie_call\($func,/ ||     # issue s154, issue s216
                        $lines[$i] =~ /[.]$func = .*add_tie_call\($func,/ ||     # issue s154, issue s216, issue s304
                        (($lines[$i] =~ /^_(?:PACK_TO_STRUCT|TEMPLATE_LENGTH|decoding_map|encoding_map|fileinput_iter|finditer_pattern|finditer_string|finditer_iter) =/ ||   # issue s270
                          $lines[$i] =~ /^Data\.Dumper\.[A-Za-z0-9_]+ =.* # InIt/) && $i==$start_line-1) ||     # issue s270
                        $lines[$i] =~ /[.]$func = $func$/) {     # e.g. main.func = func
                        say STDERR "Found def $func on line " . ($i+1) . ": $lines[$i]" if $::debug >= 7;
                    if(exists $moved_lines{$i+1}) {         # Don't include it twice
                        $already_moved++;
                        next;
                    }
                    last if($lines[$i] =~ m'^@' and $moved_def);
                    $moved_def = 1 if($lines[$i] =~ /^def $func\(/ || $lines[$i] =~ /^class $func[(:]/ ||
                                      $lines[$i] =~ /^$func = _/);      # issue test coverage
                    $moved_lines{$i+1} = 1;
                    say STDERR "writing lines[$i] ($lines[$i])" if $::debug >= 7;
                    $lines_moved++;
                    if(exists $def_package{$func} && !exists $packages_initialized{$def_package{$func}}) {  # issue s18
                        push @{$deferred_lines{$def_package{$func}}}, $lines[$i];        # issue s18
                    } else {                                                # issue s18
                        pep8($sysout, $lines[$i]);
                    }
                } elsif(exists $moved_lines{$i+1}) {            # issue s155
                    say STDERR "skipped writing as this was already moved: $lines[$i]" if $::debug >= 7;
                    next;
                } elsif(exists $moved_lines{$i} && $lines[$i] =~ /^\s+#/ && ($i+1 >= scalar(@lines) || $lines[$i+1] !~ /^\s+#/)) {  # issue test_comments
                    # If we just moved a sub and we have exactly one comment below it, that comment gets moved with the sub
                    $moved_lines{$i+1} = 1;
                    $lines_moved++;
                    if(exists $def_package{$func} && !exists $packages_initialized{$def_package{$func}}) {  # issue s18
                        push @{$deferred_lines{$def_package{$func}}}, $lines[$i];        # issue s18
                    } else {                                                # issue s18
                        pep8($sysout, $lines[$i]);
                    }
                } else {
                    if($lines[$i] eq 'pass') {          # issue s155: Effectively use up the 'pass' we inserted to stop movement so code of the outer block can be moved
                        $moved_lines{$i+1} = 1;         # issue s155
                        if(exists $moved_lines{$i} && $i+1 < scalar(@lines) && $lines[$i+1] =~ /^\s*#/ && ($i+2 >= scalar(@lines) || $lines[$i+2] !~ /^\s*#/)) {  # issue test_comments
                            # If we just moved a sub and we have exactly one comment below it, that comment gets moved with the sub
                            $moved_lines{$i+2} = 1;
                            $lines_moved++;
                            if(exists $def_package{$func} && !exists $packages_initialized{$def_package{$func}}) {
                                push @{$deferred_lines{$def_package{$func}}}, $lines[$i+1];
                            } else {
                                pep8($sysout, $lines[$i+1]);
                            }
                        }
                    }                                   # issue s155
                    say STDERR "stopped writing as we found $lines[$i]" if $::debug >= 7;    # TEMP
                    last;
                }
            }
            say STDERR " moved $lines_moved lines (skipped $already_moved)" if($::debug >= 5);
            # Special case - move all _init_package calls right after it's definition
            if($func eq '_init_package') {
                for my $ip_lno (@init_package_lnos) {
                    my $ln = $lines[$ip_lno-1];                                 # issue s18
                    pep8($sysout, $ln);                                         # issue s18
                    if($ln =~ /^_init_package\('([A-Za-z0-9._]+)'/) {           # issue s18
                        $packages_initialized{$1} = 1;                          # issue s18
                        if(exists $deferred_lines{$1}) {                        # issue s18
                            foreach $ln (@{$deferred_lines{$1}}) {              # issue s18
                                say STDERR "Outputing deferred_line: $ln" if $::debug >= 7;
                                pep8($sysout, $ln);                             # issue s18
                            }                                                   # issue s18
                            delete $deferred_lines{$1};                         # issue s18
                        }                                                       # issue s18
                    }                                                           # issue s18
                    $moved_lines{$ip_lno} = 1;
                }
            }
        }
        @ordered_to_move = ();
        next if(exists $moved_lines{$lno});
        if($multiline_string_sep) {
            say $sysout $line;
            $multiline_string_sep = '' if(index($line, $multiline_string_sep) >= 0);
            next;
        } elsif(($line =~ /"""/ || $line =~ /'''/) && $line !~ /^\s*#/) {
            $ndx = index($line, '"""');
            $ndx = index($line, "'''") if $ndx < 0;
            $multiline_string_sep = substr($line,$ndx,3);
            # if the string terminates on the same line, then it's not a multiline string
            $multiline_string_sep = '' if(index($line, $multiline_string_sep, $ndx+3) >= 0);
        }
        say STDERR "Outputing line $line" if $::debug >= 7;
        pep8($sysout, $line);
        if($line =~ /^$PERLLIB\.init_package\('([A-Za-z0-9._]+)'/ ||
           $line =~ /^_init_package\('([A-Za-z0-9._]+)'/) {         # issue s18
            $packages_initialized{$1} = 1;                          # issue s18
            if(exists $deferred_lines{$1}) {                        # issue s18
                foreach $ln (@{$deferred_lines{$1}}) {              # issue s18
                    say STDERR "Outputing deferred_line: $ln" if $::debug >= 7;
                    pep8($sysout, $ln);                             # issue s18
                }                                                   # issue s18
                delete $deferred_lines{$1};                         # issue s18
            }                                                       # issue s18
        }                                                           # issue s18
    }
    close $sysout;
}

sub pep8                # Generate blank lines where they should be, and eliminate extra ones
# Also gets rid of extra "pass" statements generated by eval{...};
{
    state $last_was_blank = 0;
    state $last_indent = 0;

    my $out = shift;
    my $line = shift;

    #$DB::single = 1;
    $this_is_blank = $line =~ /^\s*$/;
    $this_is_comment = $line =~ /^\s*#/;
    $line =~ /^(\s*)/;
    $this_indent = length($1);
    #$this_indent = 0 if($this_is_blank);
    $this_indent = $last_indent if($this_is_blank);
    if($this_is_comment) {              # Just ignore and spit out comment lines
        say $out $line;
        $last_was_blank = 0;
        return;
    } elsif($this_is_blank && $last_was_blank) {        # eliminate multiple blank lines
        return;
    } elsif($this_indent <= $last_indent && ($line =~ /^\s*pass$/ || $line =~ /^pass # LAST_HEADER$/)) {
        return;                 # Get rid of extra "pass" statements
    #} elsif($line =~ /^\s*def / && !$last_was_blank) {
    } elsif($this_indent < $last_indent && !$this_is_blank && $line !~ /^\s*except / &&
            $line !~ /^\s*else:/ && $line !~ /^\s*elif /) {
        say $out "";    # generate a blank line
    } elsif($this_indent == 0 && !$this_is_blank && $line =~ /^def / && !$last_was_blank) {
        say $out "";    # generate a blank line
    }
    say $out $line;
    $last_was_blank = $this_is_blank;
    #$last_indent = $this_indent if(!$this_is_blank);
    $last_indent = $this_indent;
}

sub cleanup_imports
{
    # Minimize the amount of imports we need based on what we actually reference in the code
    # Return 1 if any changes are made

    my $line_ref = shift;

    my $lno = 0;
    my $import_lno = 0;
    my $import_as_lno = 0;              # import time as tm_py
    my $die_def_lno = 0;                # class Die(Exception):
    my $die_import_lno = 0;             # from perllib import Die
    my $loop_control_def_lno = 0;       # class LoopControl(Exception):
    my $as_what = '';
    my @imports = ();
    my %referenced_imports = ();
    my @globals = keys %GLOBALS;
    my %global_lnos = ();
    my %referenced_globals = ();
    my $import_as_referenced = 0;
    my $_bn_lno = 0;			# issue s117
    my $_bn_referenced = 0;		# issue s117
    my $_pb_lno = 0;			# issue s124
    my $_pb_referenced = 0;		# issue s124
    my $_sl_lno = 0;			# issue s308
    my $_sl_referenced = 0;		# issue s308
    my $_str_lno = 0;
    my $_str_referenced = 0;
    my $die_referenced = 0;
    my $loop_control_referenced = 0;
    my $eval_return_lno = 0;            # class $EVAL_RETURN_EXCEPTION(
    my $eval_referenced = 0;
    my $import_as_global = '';
    my $loop_control = label_exception_name(undef);     # issue 94
    my @gl;
    #my $list_sep_lno = 0;
    #my $list_sep_referenced = 0;
    #my $script_start_lno = 0;
    #my $script_start_referenced = 0;
    for my $Line (@$line_ref) {
        $lno++;
        $line = eat_strings($Line);     # we change variables so eat_strings doesn't modify @lines
	next if($line =~ /^\s*$/);	# skip blank lines
	next if($line =~ /^\s*#/);	# skip comment lines
	if($line =~ /^import /) {
            my $import_s = $line =~ s/^import //r;
            if(!$import_as_lno && index($import_s, ' as ') > 0) {      # import time as tm_py
                ($as_what) = $line =~ / as ([a-z_]+)/;
                $import_as_lno = $lno;
            } elsif(!$import_lno){
                @imports = split /,/, $import_s;
                $import_lno = $lno;
                #say STDERR "import_lno=$import_lno";
            }
        } elsif($line =~ /^class Die\(/) {
            $die_def_lno = $lno;
        } elsif($line =~ /^from $PERLLIB import Die$/) {
            $die_import_lno = $lno;
        } elsif($line =~ /^class $loop_control\(/) {      # issue 94
            $loop_control_def_lno = $lno;
        } elsif($line =~ /^class $EVAL_RETURN_EXCEPTION\(/) {
            $eval_return_lno = $lno;
        } elsif($line =~ /^_bn = lambda/) {		# issue s117
            $_bn_lno = $lno;				# issue s117
        } elsif($line =~ /^_pb = lambda/) {		# issue s124
            $_pb_lno = $lno;				# issue s124
        } elsif($line =~ /^_sl = lambda/) {		# issue s308
            $_sl_lno = $lno;				# issue s308
        } elsif($line =~ /^_str = lambda/) {
            $_str_lno = $lno;
        } elsif((@gl = grep { $line =~ /^$_ = / } @globals)) {
            $g = $gl[0];
            $global_lnos{$g} = $lno unless exists $global_lnos{$g}; # issue s288: Only patch out the first one we find
            if($line =~ /\b$as_what\./) {
                $import_as_global = $g;
            }
        } elsif($import_lno) {
            my @found = grep { $line =~ /\b$_[.,]/ } @imports;
            foreach my $f (@found) {
                #say STDERR "Found fcntl here: $line" if($f eq 'fcntl');
                $referenced_imports{$f} = 1;
            }
            my @gl = grep { $line =~ /\b$_\b/ } @globals;
            foreach my $g (@gl) {
                $referenced_globals{$g} = 1;
                if($g eq $import_as_global) {   # this one references our import as
                    $import_as_referenced = 1;
                }
            }
            if($line =~ /\b$as_what\./) {
                $import_as_referenced = 1;
                #say STDERR $line;
                #} elsif($line =~ /\bLIST_SEPARATOR\b/) {
                #$list_sep_referenced = 1;
            }
            if($line =~ /\b_bn\b/) {	# issue s117
                $_bn_referenced = 1;	# issue s117
            }				            # issue s117
            if($line =~ /\b_pb\b/) {	# issue s124
                $_pb_referenced = 1;	# issue s124
            }				            # issue s124
            if($line =~ /\b_sl\b/) {	# issue s308
                $_sl_referenced = 1;	# issue s308
            }				            # issue s308
            if($line =~ /\b_str\b/) {
                $_str_referenced = 1;
            }
            if($line =~ /\bDie\b/) {
                $die_referenced = 1;
            }
            if($line =~ /\b$loop_control\b/) {
                $loop_control_referenced = 1;
            }
            if($line =~ /\b$EVAL_RETURN_EXCEPTION\b/) {
                $eval_referenced = 1;
            }
        }
    }
    say STDERR "cleanup_imports import_lno=$import_lno, refs=@{[%referenced_imports]}, imports=@imports, as_what=$as_what, import_as_referenced=$import_as_referenced, import_as_lno=$import_as_lno, die_referenced=$die_referenced, die_def_lno=$die_def_lno" if($::debug >= 5);
    if($import_lno) {
        my $size = keys %referenced_imports;
        if($size) {
            # issue s127 $line_ref->[$import_lno-1] = 'import ' . join(',', keys %referenced_imports);
            $line_ref->[$import_lno-1] = 'import ' . join(',', sort keys %referenced_imports);  # issue s127
        } else {
            $line_ref->[$import_lno-1] = '^';
        }
        if($import_as_lno && !$import_as_referenced) {
            $line_ref->[$import_as_lno-1] = '^';
        }
        if($die_import_lno && !$die_referenced) {
            $line_ref->[$die_import_lno-1] = '^';   # from perllib import Die
        } elsif($die_def_lno && !$die_referenced) {
            $line_ref->[$die_def_lno-1] = '^';   # class Die(Exception):
            $line_ref->[$die_def_lno] = '^';     #     pass or def __init__(...):
            if($::traceback) {     #     traceback
                $line_ref->[$die_def_lno+1] = '^';    # (super)...
                $line_ref->[$die_def_lno+2] = '^';    # if TRACEBACK...
                $line_ref->[$die_def_lno+3] = '^';    #     _cluck()
            }
        }
        if($_bn_lno && !$_bn_referenced) {		# issue s117
            $line_ref->[$_bn_lno-1] = '^';		# issue s117
        }						                # issue s117
        if($_pb_lno && !$_pb_referenced) {		# issue s124
            $line_ref->[$_pb_lno-1] = '^';		# issue s124
        }						                # issue s124
        if($_sl_lno && !$_sl_referenced) {		# issue s308
            $line_ref->[$_sl_lno-1] = '^';		# issue s308
        }						                # issue s308
        if($_str_lno && !$_str_referenced) {
            $line_ref->[$_str_lno-1] = '^';
        }
        if($loop_control_def_lno && !$loop_control_referenced) {
            $line_ref->[$loop_control_def_lno-1] = '^';   # class LoopControl(Exception):
            $line_ref->[$loop_control_def_lno] = '^';     #     pass
        }
        if($eval_return_lno && !$eval_referenced) {
            $line_ref->[$eval_return_lno-1] = '^';   # class $EVAL_RETURN_EXCEPTION(Exception):
            $line_ref->[$eval_return_lno] = '^';     #     pass
        }
        foreach my $g (keys %global_lnos) {
            if(!exists $referenced_globals{$g}) {
                $line_ref->[$global_lnos{$g}-1] = '^';
            }
        }
        return 1;
    }
    return 0;
}

sub pretty_print_python
# SNOOPYJC: Run the black pretty printer on the python code (-k option)
{
    my $nul = ($^O eq 'MSWin32') ? 'nul' : '/dev/null';
    `$PRETTY_PRINTER -l$::black_line_length "$output_file" 2>$nul`
}

sub create_link_if_needed           # issue s211
# Create a hard link from our output file to file/__init__.py if we need to create a package
{
    return unless $fname =~ /\.pm$/;
    return unless -d $source_file;
    link $output_file, "$source_file/__init__.py";      # Create a package
}

sub get_fstring_items
# helper function for eat_strings - returns an array of {...} items from an f-string, but not {{...}}
{
    my $line = shift;

    $line =~ s/\{\{//g;
    $line =~ s/\}\}//g;
    my @result = ();
    while($line =~ /\{([^}]+)\}/g) {
        push @result, $1;
    }
    return @result;
}

sub eat_strings
# Given a python line, eat any strings in it.  Handle multi-line strings with ''' or """ too!
# For f'...' strings and rf'...' strings (and fr'...' strings) we need to keep the references in the
# {...} but not anything in {{...}}.
{
    state $mstring_sep = '';
    state $fstring = 0;
    my $line = shift;
    my $ndx;
    #print STDERR "eat_strings($line)=";
    my @fstring_items = ();
    if($mstring_sep) {
        if(($ndx = index($line, $mstring_sep)) >= 0) {
            #say STDERR "END_S:   $line";    # TEMP
            $mstring_sep = '';
            push @fstring_items, get_fstring_items(substr($line,0,$ndx)) if($fstring);
            $line = substr($line, $ndx+3);
            $fstring = 0;
        } else {
            push @fstring_items, get_fstring_items($line) if($fstring);
            $line = '';
        }
    }
    if($mstring_sep) {
        ;
    } elsif($line =~ /^\s*#/) {		# Comment line
        ;
    } else {
        $fstring = 0;
#       my @quotes = ('"', "'");
        my $p;
#        for my $quote (@quotes) {
	    OUTER:
#            while(1) {
            for($ndx = 0; $ndx < length($line); $ndx++) {
                my $quote = substr($line,$ndx,1);
                #$ndx = index($line, $quote);
                #last if($ndx < 0);
                next unless($quote eq '"' || $quote eq "'");
                last if(($p = index($line, '#')) >= 0 && $p < $ndx);            # Ignore strings in comments
                last if(substr($line, $ndx, 3) eq "'''");        # handled below
                last if(substr($line, $ndx, 3) eq '"""');        # handled below
                my $start = $ndx;
                while($start > 0) {
                    my $c = substr($line,$start-1,1);
                    if($c eq 'f' || $c eq 'r') {   # Eat the 'f' from f-strings, and 'r' likewise.  Also handles rf"..." and fr"..."
                        $fstring = 1 if($c eq 'f');
                        $start--;
                    } else {
                        last;
                    }
                }
                while(1) {
                    $ndx2 = index($line, $quote, $ndx+1);
                    if($ndx2 >= 0) {
                        if(&Perlscan::is_escaped($line, $ndx2)) {
                            $ndx = $ndx2;
                            next;
                        }
                        #substr($line,$start,$ndx2+1-$start) = '';
                        push @fstring_items, get_fstring_items(substr($line,$start,($ndx2-$start)+1)) if($fstring);
                        $line = substr($line,0,$start).substr($line,$ndx2+1);
                        $ndx = -1;
                        last;
                    } else {
                        last OUTER;
                    }
                }
            }
#        }
        if(($line =~ /"""/ || $line =~ /'''/) && $line !~ /^\s*#/) {
            $fstring = 0;
            $ndx = index($line, '"""');
            $ndx = index($line, "'''") if $ndx < 0;
            $mstring_sep = substr($line,$ndx,3);
            while($ndx > 0) {
               my $c = substr($line,$ndx-1,1);
               if($c eq 'f' || $c eq 'r') {    # Eat the 'f' from f-strings, and 'r' likewise.  Also handles rf"..." and fr"..."
                  $fstring = 1 if($c eq 'f');
                  $ndx--;
               } else {
                   last;
               }
            }
            if(($p = index($line, '#')) >= 0 && $p < $ndx) {            # Ignore strings in comments
                $mstring_sep = '';
            } elsif(($ndx2 = index($line, $mstring_sep, $ndx+3)) >= 0) {
                # if the string terminates on the same line, then it's not a multiline string
                $mstring_sep = '';
                #substr($line,$ndx,$ndx2+4-$ndx) = '';
                push @fstring_items, get_fstring_items(substr($line,$ndx,($ndx2-$ndx)+1)) if($fstring);
                $line = substr($line,0,$ndx).substr($line,$ndx2+3);
            } else {                # Start of a multi-line string
                #substr($line,$ndx) = '';
                #say STDERR "START_S: $line";    # TEMP
                push @fstring_items, get_fstring_items(substr($line,$ndx)) if($fstring);
                $line = substr($line,0,$ndx);
            }
        }
    }
    $line =~ s/\s+#.*$//;          # Eat comments
    if(@fstring_items) {
        $line .= ' ' . join(' ', @fstring_items);
    }
    #say STDERR "$line";
    return $line;
}

sub trash_global_types
# issue bootstrap - if we call a sub, that sub may wind up setting a global variable
# that we think we know the type of to a value of another type.  This happened in
# bootstrapping for the -b option, where option processesing sets 'main.breakpoint_v' to 
# a string and we were assuming it was an integer.
{
    my $pot_sub = $_[0];

    for my $varname (keys %VarType) {
        my $pDot = rindex($varname, '.');
        next if $pDot < 0;                              # not global var
        my $packageName = substr($varname, 0, $pDot);
        next if !exists $Packages{$packageName};        # not ours (including things like os. sys. and _m.)
        for my $sub (keys %{$VarType{$varname}}) {
            my $type = $VarType{$varname}{$sub};
            my $otype = $type;
            next if($type =~ /^[ahsmuHR]$/);     # issue code coverage: added 'HR' as we need to know what's a file handle and a regex
            if($type =~ /^[ahs]/) {     # if it's like "a of S", change to just 'a'
                $type = common_type($type, substr($type,0,1));
            } else {
                $type = 'm';
            }
            say STDERR "trash_global_types($pot_sub) - setting VarType{$varname}{$sub} = $type (was $otype)" if($::debug >= 5);
            $VarType{$varname}{$sub} = $type;
        }
    }
}

sub new_anonymous_sub                   # issue s26
# Create a new anonymous sub and return the name
{
    my $result = "$ANONYMOUS_SUB$.";
    if(exists $anonymous_subs_used{$result}) {
        my $suffix = $anonymous_subs_used{$result};
        if($suffix eq '') {
            $suffix = 'a';
        } else {
            $suffix = chr((ord $suffix) + 1);
        }
        $anonymous_subs_used{$result} = $suffix;
        $result .= $suffix;
    } else {
        $anonymous_subs_used{$result} = '';
    }
    return $result;
}

sub declared_in_statement                   # issue s362
# Is this name being declared in this statement?
{
    my $name = shift;

    for(my $i = 0; $i <= $#ValClass; $i++) {
        if($ValClass[$i] eq 't' && ($ValPerl[$i] eq 'my' || $ValPerl[$i] eq 'local' || $ValPerl[$i] eq 'state')) {
            return 1 if $i+1 <= $#ValClass && $ValPy[$i+1] eq $name;
            if($ValClass[$i+1] eq '(') {
                my $match = matching_br($i+1);
                $match = scalar(@ValClass) if $match < 0;
                for(my $j = $i+1; $j < $match; $j++) {
                    return 1 if $ValPy[$j] eq $name;
                }
                $i = $match;
            }
        }
    }
    return 0;
}

sub being_declared_here                         # issue bootstrap
# we have a "my" or similar statement, and a pointer to a variable - is this variable being declared here?
# Returns 0 if it's being used in a subscript or on the RHS of an assignment
{
    my $pos = shift;
    my $split = next_same_level_token('=', 0, $#ValClass);

    return 0 if($split >= 0 && $pos > $split);
    my $class = $ValClass[$pos];
    my $limit = $#ValClass;
    $limit = $split-1 if($split >= 0);

    # We need to find us either at the same level, or within the top-level parens (if any)

    my $st = 0;
    while($st = next_same_level_token($class, $st, $limit)) {
        last if($st < 0);
        return 1 if($st == $pos);       # found us w/o parens!
        $st++;
    }

    return 0 if($ValClass[1] ne '(');
    $limit = matching_br(1)-1;
    return 0 if($limit < 0);
    $st = 2;
    while($st = next_same_level_token($class, $st, $limit)) {
        last if($st < 0);
        return 1 if($st == $pos);       # found us inside parens!
        $st++;
    }
    return 0;
}

sub is_foreach_loop				# issue s103
{
    my $pos = shift;

    for(my $p = $pos; $p <= $#ValClass; $p++) {
        return 0 if $ValClass[$p] eq ';';
    }
    return 1 if $ValPy[$pos] eq 'for';     # issue s235
    return 0;                           # issue s235
}

sub function_modifies_sub_arg       # issue s183
# For a function that has an out parameter, is the out parameter part of a sub arg list?
# (if so, we have to copy the arglist from a tuple to a list)
{
    my $pos = shift;        # Point to the 'f'

    my $limit = end_of_function($pos);

    my $cs = &Perlscan::cur_sub();                      # issue s185
    my $which_arg = $PYF_OUT_PARAMETERS{$ValPy[$pos]};
    for(my $k = $pos+1; $k <= $limit; $k++) {
        my $result;
        if(($ValClass[$k] eq 's' && $ValPerl[$k] eq '$_') ||
           ($ValClass[$k] eq 'a' && $ValPerl[$k] eq '@_')) {
             $result = $k;
        } elsif($ValClass[$k] eq 's' && $ValPerl[$k] eq '$' && $k+3 <= $#ValClass && $ValClass[$k+1] eq '(' &&
               $ValPerl[$k+1] eq '{' && $ValClass[$k+2] eq 's' && $ValClass[$k+3] eq ')' && ($ValPy[$k+2] =~ /\[\d+\]$/ ||
                   # issue s241 (exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arg_copies} &&
                   # issue s241 exists $SubAttributes{$cs}{arg_copies}{$ValPerl[$k+2]}))) {
                 (defined get_sub_attribute($cs, 'arg_copies') &&                       # issue s241
                  exists ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k+2]}))) {   # issue s241
             $result = $k+2;
             $ValType[$result] = 'ss';
        } elsif($ValClass[$k] eq 's' && $ValType[$k] eq 'ss' &&
            # issue s241 exists $SubAttributes{$cs} && exists $SubAttributes{$cs}{arg_copies} &&
            # issue s241 exists $SubAttributes{$cs}{arg_copies}{$ValPerl[$k]}) {
                defined get_sub_attribute($cs, 'arg_copies') &&
                exists ${get_sub_attribute($cs, 'arg_copies')}{$ValPerl[$k]}) {
             $result = $k;
        }
        if(defined $result) {
           my ($prl, $py, $arg) = arg_from_pos($k);
           if($arg+1 == $which_arg) {            # arg_from_pos counts from 0
               say STDERR "function_modifies_sub_arg(@ValPerl[$pos..$limit]) = 1" if($::debug);
               return $result;
           }
        }
        if($ValClass[$k] eq 'f') {
            $k = end_of_function($k);
        } elsif($ValClass[$k] ne '(') {
            $k = &::end_of_variable($k);
        }
    }
    say STDERR "function_modifies_sub_arg(@ValPerl[$pos..$limit]) = 0" if($::debug);
    return 0;
}

sub get_function_out_parameter       # issue s241
# For a function that has an out parameter, get the pointer to that out parameter
{
    my $pos = shift;        # Point to the 'f'

    my $limit = end_of_function($pos);

    my $which_arg = $PYF_OUT_PARAMETERS{$ValPy[$pos]};
    for(my $k = $pos+1; $k <= $limit; $k++) {
        next if $ValClass[$k] eq ',';
        my ($prl, $py, $arg) = arg_from_pos($k);
        if(defined $arg && $arg+1 == $which_arg) {            # arg_from_pos counts from 0
           say STDERR "get_function_out_parameter(@ValPerl[$pos..$limit]) = $k" if($::debug);
           return $k;
        }
        if($ValClass[$k] eq 'f') {
            $k = end_of_function($k);
        } elsif($ValClass[$k] ne '(') {
            $k = &::end_of_variable($k);
        }
    }
    say STDERR "ERROR: get_function_out_parameter(@ValPerl[$pos..$limit]) = undef" if($::debug);
    return undef;
}

sub track_potential_sub_parameter_copies       # issue s185
# This is a 'my' statement in a sub - see if it copies the sub arguments, and if so,
# keep track of that in order to check for reference out parameters
{
    # my $self = shift;
    # my $i = $_[0];
    # my ($i, $j, $k) = (shift, shift, shift);
    # my ($i, $j) = @_;
    # my ($i, $j) = ($_[0], $_[1]);

    return if &Perlscan::in_conditional(1);
    my $cs = &Perlscan::cur_sub();
    my $eq = next_same_level_token('=', 1, $#ValClass);
    my $rhs = $eq+1;
    my $lhs = 1;
    if($ValClass[$lhs] eq '(') {           # my (...)
        if($rhs == $#ValClass && $ValClass[$rhs] eq 'a' && $ValPerl[$rhs] eq '@_') {        # Easy case: my (...) = @_;
            # issue s241 my $which = (exists $SubAttributes{$cs}{arglist_shifts}) ? $SubAttributes{$cs}{arglist_shifts} : 0;
            my $which = get_sub_attribute($cs, 'arglist_shifts',0,0);  # issue s241
            for(my $p = $lhs+1; $p < $eq; $p++) {
                if($ValClass[$p] eq 's') {
                    # issue s241 $SubAttributes{$cs}{arg_copies}{$ValPerl[$p]} = $which;
                    my $ac = get_sub_attribute($cs, 'arg_copies', 0, {});       # issue s241
                    $ac->{$ValPerl[$p]} = $which;                               # issue s241
                    set_sub_attribute($cs, 'arg_copies', $ac);                  # issue s241
                    $which++;
                }
            }
        } elsif($ValClass[$rhs] eq '(' && $ValClass[$rhs+1] eq 'a' && $ValPerl[$rhs+1] eq '@_') {   # Another easy case: my (...) = (@_);
            # issue s241 my $which = (exists $SubAttributes{$cs}{arglist_shifts}) ? $SubAttributes{$cs}{arglist_shifts} : 0;
            my $which = get_sub_attribute($cs, 'arglist_shifts',0,0);  # issue s241
            for(my $p = $lhs+1; $p < $eq; $p++) {
                if($ValClass[$p] eq 's') {
                    # issue s241 $SubAttributes{$cs}{arg_copies}{$ValPerl[$p]} = $which;
                    my $ac = get_sub_attribute($cs, 'arg_copies', 0, {});       # issue s241
                    $ac->{$ValPerl[$p]} = $which;                               # issue s241
                    set_sub_attribute($cs, 'arg_copies', $ac);                  # issue s241
                    $which++;
                }
            }
        } elsif($ValClass[$rhs] eq '(') {
            # issue s241 my $which = (exists $SubAttributes{$cs}{arglist_shifts}) ? $SubAttributes{$cs}{arglist_shifts} : 0;
            my $which = get_sub_attribute($cs, 'arglist_shifts',0,0);  # issue s241
            for(my $p = $rhs+1; $p < $#ValClass; $p++) {       # Start by reducing $which by the number of shifts
                if($ValClass[$p] eq 'f' && $ValPerl[$p] eq 'shift') {
                    $which--;
                }
            }
            my $q = $rhs+1;
            for(my $p = $lhs+1; $p < $eq; $p++) {
                if($ValClass[$p] eq 's') {
                    if($ValClass[$q] eq 'f' && $ValPerl[$q] eq 'shift') {
                        # issue s241 $SubAttributes{$cs}{arg_copies}{$ValPerl[$p]} = $which;
                        my $ac = get_sub_attribute($cs, 'arg_copies', 0, {});       # issue s241
                        $ac->{$ValPerl[$p]} = $which;                               # issue s241
                        set_sub_attribute($cs, 'arg_copies', $ac);                  # issue s241
                        $which++;
                    } elsif($ValClass[$q] eq 's' && $ValPy[$q] =~ /\[(\d+)\]$/) {
                        # issue s241 $SubAttributes{$cs}{arg_copies}{$ValPerl[$lhs]} = $1 + $which;
                        my $ac = get_sub_attribute($cs, 'arg_copies', 0, {});       # issue s241
                        $ac->{$ValPerl[$lhs]} = $1 + $which;                        # issue s241
                        set_sub_attribute($cs, 'arg_copies', $ac);                  # issue s241
                    }
                }
                next if $ValClass[$p] eq ',';
                my $next = next_same_level_tokens(',)', $q, $#ValClass);
                $q = $next+1 unless $next < 0;
                last if($q > $#ValClass);           # issue s308
            }
        }
    } elsif($eq == 2) {                 # my $var = ...
        if($ValClass[$rhs] eq 'f' && $ValPerl[$rhs] eq 'shift' && ($rhs == $#ValClass || $ValPerl[$rhs+1] eq '@_')) {
            # issue s241 $SubAttributes{$cs}{arg_copies}{$ValPerl[$lhs]} = $SubAttributes{$cs}{arglist_shifts}-1;    # We already incremented it
            my $ac = get_sub_attribute($cs, 'arg_copies', 0, {});       # issue s241
            $ac->{$ValPerl[$lhs]} = get_sub_attribute($cs, 'arglist_shifts')-1;
            set_sub_attribute($cs, 'arg_copies', $ac);                  # issue s241
        } elsif($rhs == $#ValClass && $ValPerl[$rhs] eq '$_' && $ValPy[$rhs] =~ /\[(\d+)\]$/) {
            # issue s241 if(exists $SubAttributes{$cs}{arglist_shifts}) {
            # issue s241 $SubAttributes{$cs}{arg_copies}{$ValPerl[$lhs]} = $1 + $SubAttributes{$cs}{arglist_shifts};
            # issue s241 } else {
            # issue s241 $SubAttributes{$cs}{arg_copies}{$ValPerl[$lhs]} = $1;
            # issue s241 }
            my $ac = get_sub_attribute($cs, 'arg_copies', 0, {});       # issue s241
            if(defined get_sub_attribute($cs, 'arglist_shifts')) {
                $ac->{$ValPerl[$lhs]} = $1 + get_sub_attribute($cs, 'arglist_shifts');
            } else {
                $ac->{$ValPerl[$lhs]} = $1;
            }
            set_sub_attribute($cs, 'arg_copies', $ac);                  # issue s241
        }
    }
}

sub set_out_parameter                   # issue s184
{
    my $cs = shift;
    my $arg = shift;

    if($arg eq 'var') {
       # issue s241 $SubAttributes{$cs}{out_parameters} = ['var'];
       set_sub_attribute($cs, 'out_parameters', ['var']);
    } else {
       no warnings 'numeric';       # handle 1r, etc
       # issue s241 if(exists $SubAttributes{$cs}{out_parameters}) {
       if(defined get_sub_attribute($cs, 'out_parameters')) {
           # issue s241 if(!grep {($_+0) == ($arg+0) || $_ eq 'var'} @{$SubAttributes{$cs}{out_parameters}}) {
           # issue s241 push @{$SubAttributes{$cs}{out_parameters}}, $arg;
           if(!grep {($_+0) == ($arg+0) || $_ eq 'var'} @{get_sub_attribute($cs, 'out_parameters')}) {   # issue s241
              push @{get_sub_attribute($cs, 'out_parameters')}, $arg;    # issue s241
              if(exists $SubAttributes{'->'.$cs}) {                     # issue s353: It's a copy
                  push @{get_sub_attribute($cs, 'out_parameters', 1)}, $arg;    # issue s353: Method call
              }
           }                                                              # issue s184
       } else { 
           # issue s241 $SubAttributes{$cs}{out_parameters} = [$arg];
           set_sub_attribute($cs, 'out_parameters',  [$arg]);
       }
   }
   # issue s241 if(exists $Perlscan::SpecialVarsUsed{'bless'} && exists $Perlscan::SpecialVarsUsed{'bless'}{$CurPackage}) {  # issue s18
   # issue s241 $SubAttributes{'->'.$cs} = dclone($SubAttributes{$cs});
   # issue s241 }
   # issue s241 $SubAttributes{$CurPackage . '.' . $cs} = $SubAttributes{$cs};
   # issue s241 $SubAttributes{'main.' . $CurPackage . '.' . $cs} = $SubAttributes{$cs} unless $CurPackage eq 'main';
}

sub set_sub_attribute               # issue s241
# Set SubAttributes for the specified sub to the specified value, propogating it as appropriate
{
    my $py_name = shift;
    my $attr = shift;
    my $val = shift;

    my $package = &Perlscan::cur_raw_package();
    my $escaped_package = &Perlscan::cur_package();

    my $ld = rindex($py_name, '.');
    if($ld >= 0) {
        $package = substr($py_name, 0, $ld);
        $py_name = substr($py_name, $ld+1);
    }
    $SubAttributes{$package . '.' . $py_name}{$attr} = $val;
    if(exists $Perlscan::SpecialVarsUsed{'bless'} && exists $Perlscan::SpecialVarsUsed{'bless'}{$package}) {
        $SubAttributes{'->'.$py_name} = dclone($SubAttributes{$package . '.' . $py_name});
    }
    if((defined $CurPackage && $package eq $CurPackage) || (!defined $CurPackage && $package eq $DEFAULT_PACKAGE)) {
        $SubAttributes{$py_name} = $SubAttributes{$package . '.' . $py_name};
    }
    if($package ne $escaped_package) {
        $SubAttributes{$escaped_package . '.' . $py_name} = $SubAttributes{$package . '.' . $py_name};
        $SubAttributes{'main.' . $escaped_package . '.' . $py_name} = $SubAttributes{$py_name} unless $escaped_package eq 'main';
    }
    $SubAttributes{'main.' . $package . '.' . $py_name} = $SubAttributes{$py_name} unless $package eq 'main';
}

sub get_sub_attribute_at            # issue s241
# Get a SubAttribute for the token at pos
{
    my $pos = shift;
    my $attr = shift;
    my $default = scalar(@_) ? $_[0] : undef;

    my $method_call = 0;
    my $py_name = $ValPy[$pos];
    $method_call = 1 if($pos != 0 && $ValClass[$pos-1] eq 'D');
    return get_sub_attribute($py_name, $attr, $method_call, $default);
}

sub get_sub_attribute               # issue s241
# Get a specified SubAttribute for the specified sub
{
    my $py_name = shift;
    my $attr = shift;
    my $method_call = scalar(@_) ? $_[0] : 0;
    my $default = scalar(@_) >= 2 ? $_[1] : undef;

    my $package = &Perlscan::cur_raw_package();

    my $ld = rindex($py_name, '.');
    if($ld >= 0) {
        $package = substr($py_name, 0, $ld);
        $py_name = substr($py_name, $ld+1);
    }
    if($method_call) {
        if(exists $SubAttributes{'->'.$py_name})  {
            if(exists $SubAttributes{'->'.$py_name}{$attr}) {
                return $SubAttributes{'->'.$py_name}{$attr};
            }
            return $default;
        }
    }
    if(exists $SubAttributes{$package . '.' . $py_name}) {
        if(exists $SubAttributes{$package . '.' . $py_name}{$attr}) {
            return $SubAttributes{$package . '.' . $py_name}{$attr};
        }
        return $default;
    }
    if(exists $SubAttributes{$py_name}) {
        if(exists $SubAttributes{$py_name}{$attr}) {
            return $SubAttributes{$py_name}{$attr};
        }
    }
    return $default;
}

sub clone_sub_attributes               # issue s241
# Clone the sub attributes, used for like *sub = \%my_sub;
{
    my $from_py_name = shift;
    my $to_py_name = shift;

    my $package = &Perlscan::cur_raw_package();

    my $ld = rindex($from_py_name, '.');
    if($ld >= 0) {
        $package = substr($from_py_name, 0, $ld);
        $from_py_name = substr($from_py_name, $ld+1);
    }
    if(exists $SubAttributes{$package . '.' . $from_py_name}) {
        for my $attr (keys %{$SubAttributes{$package . '.' . $from_py_name}}) {
            set_sub_attribute($to_py_name, $attr, $SubAttributes{$package . '.' . $from_py_name}{$attr});
        }
        return;
    }
    if(exists $SubAttributes{$from_py_name}) {
        for my $attr (keys %{$SubAttributes{$from_py_name}}) {
            set_sub_attribute($to_py_name, $attr, $SubAttributes{$from_py_name}{$attr});
        }
    }
}

sub propagate_sub_attributes_for_bless      # issue s184
# The first time we see a 'bless', propagate the OO form of all SubAttributes
{
    foreach (keys %SubAttributes) {
        unless(/^->/ || /[.]/) {
            $SubAttributes{'->'.$_} = $SubAttributes{$_};
        }
    }
}

sub for_loop_uses_default_var       # issue s235
# Does this for(each) loop use the default variable?
# The case that caused this to be written is: $selected{$_}++ for $self->param($name);
# which needs to return True!!
{
    my $pos = shift;

    return 0 unless is_foreach_loop($pos);
    return 1 if $ValClass[1] eq '(';    # for (...)
    return 0 if $ValClass[1] eq 't';    # for my ...
    # issue s312 return 0 if $ValClass[1] eq 's' && $ValClass[2] eq '('; # for $s (
    return 1 if $ValClass[1] =~ /[ahfG]/;       # issue s312: for @array, etc
    return 1 if $ValClass[1] eq 's' && defined $ValType[1] && $ValType[1] =~ /[@%]s/;   # issue s312: for @$arrayref
    return 0 if $ValClass[1] eq 's' && 2 <= $#ValClass && $ValClass[2] eq '('; # for $s (      # issue s312
    return 1;
}

sub is_scalar_operator      # issue s246
# Is this a scalar operator?
{
    my $pos = shift;

    # issue s307 if(index("+-*/.>%&|",$ValClass[$pos]) >= 0) {
    if(index("+-*/.>%&|r",$ValClass[$pos]) >= 0) {      # issue s307: add 'r'
        if($pos == 0) {
            return 1 if($ValClass[$pos] eq '-');    # Unary - is all that counts here
            return 0;
        }
        return 1 if $ValClass[$pos] eq '-';     # issue s260
        return 1 if is_term($pos-1); # Previous is a term
    }
    if($ValClass[$pos] eq '!') {     # issue 260: not
        return 1 if $pos == 0;
        return 0 if $ValClass[$pos-1] eq 'f' && $ValPerl[$pos-1] eq 'grep'; # see issue s153
        return 1;
    }
    return 0;
}

sub is_term                 # issue s246
# Is this a term in an expression?
{
    my $pos = shift;

    if(index('dshaf)"', $ValClass[$pos]) != -1) {
        if($ValClass[$pos] eq 'f') {
            $arg_type = arg_type($ValPerl[$pos], $ValPy[$pos], 0, 0, 1);
            if($arg_type eq '' || length($arg_type) == 2) {  # Empty or ends with a '?'
                say STDERR "is_term(f: $ValPerl[$pos] ($ValPy[$pos]) arg_type=$arg_type) = 1" if $::debug >= 5 && $PassNo != PASS_0;
                return 1;
            }
            say STDERR "is_term(f: $ValPerl[$pos] ($ValPy[$pos]) arg_type=$arg_type) = 0" if $::debug >= 5 && $PassNo != PASS_0;
            return 0;
        }
        say STDERR "is_term($ValClass[$pos]: $ValPerl[$pos] ($ValPy[$pos])) = 1" if $::debug >= 5 && $PassNo != PASS_0;
        return 1;
    }
    say STDERR "is_term($ValClass[$pos]: $ValPerl[$pos] ($ValPy[$pos])) = 0" if $::debug >= 5 && $PassNo != PASS_0;
    return 0;
}
1;
