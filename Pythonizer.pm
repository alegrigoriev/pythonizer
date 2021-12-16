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
use Perlscan qw(tokenize $TokenStr @ValClass @ValPerl @ValPy @ValType %token_precedence);  # SNOOPYJC
use Softpano qw(abend logme out getopts standard_options);
use config;				# issue 32
use Data::Dumper;       # SNOOPYJC
require Exporter;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw(preprocess_line correct_nest getline prolog output_line %LocalSub %GlobalVar %InitVar %VarType init_val matching_br reverse_matching_br next_matching_token next_same_level_token next_same_level_tokens next_lower_or_equal_precedent_token); # SNOOPYJC
our  ($IntactLine, $output_file, $NextNest,$CurNest, $line, $fname);
   # issue 32 $::TabSize=3;
   $::TabSize=$TABSIZE;         # issue 32
   $::breakpoint=0;
   $NextNest=$CurNest=0;
   # issue 32 $MAXNESTING=9;
   $VERSION = '0.80';
   $refactor=0;  # option -r flag (invocation of pre-pythonizer)
   $PassNo=0; # EXTERNAL VAR:  0 -- the first pass ( reading from @InputTextA); 1 -- the second pass(reading from STDIN)
   $InLineNo=0; # counter, pointing to the current like in InputTextA during the first pass
   %LocalSub=(); # list of local subs
   %GlobalVar=(); # generated "external" declaration with the list of global variables.
   %InitVar=(); # SNOOPYJC: generated initialization
   # issue 32 $maxlinelen=188;
   $maxlinelen=$MAXLINELEN;
   $GeneratedCode=0;    # issue 96: used to see if we generated any real code between { and }
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
      getopts("AThd:v:r:b:t:l:",\%options);     # SNOOPYJC
#
# Three standard otpiotn -h, -v and -d
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
      if(   exists $options{'t'}  ){
         $options{'t'}=1 if $options{'t'} eq '';
         if(  $options{'t'}>1  && $options{'t'}<10 ){
            $::TabSize=$options{'t'};
         }else{
            logme('S',"Range for options -t (tab size) is 2-10. You specified: $options('t')\n");
            exit 255;
         }
      }
      if( exists $options{'w'} ){
         if($options{'w'}<100 && $options{'w'}>256  ){
            $maxlinelen=$options{'w'};
            if( $maxlinelen//2==1 ){
               $maxlinelen-=1;
            }
         }else{
            logme('S',"Incorrect value for length of the line in protocol of tranlation: $options{'w'}\n Minimum  is 100. Max is 256. Default value 188 is assumned \n");
         }
      }#

      # SNOOPYJC - add more options
      if( exists $options{'T'} ) {
          $::traceback = 1;
      }
      if( exists $options{'A'} ) {
          $::autodie = 1;
      }
#
# Application arguments
#
      if(  scalar(@ARGV)==1 ){
         $fname=$ARGV[0];
         unless( -f $fname ){
            abend("Input file $fname does not exist");
         }
         $source_file=substr($ARGV[0],0,rindex($ARGV[0],'.'));
         $output_file=$source_file.'.py';
         out("Results of transcription are written to the file  $output_file");
         if(  $refactor ){
             out("Option -r (refactor) was specified. file refactored using $refactor as the fist pass over the source code");
            `pre_pythonizer -v 0 $fname`;
         }
         unless( -f "$fname.bak" ){
            `cp -p "$fname" "$fname.bak" && tr -d "\r" < "$fname.bak" > "$fname"`; # just in case
         }
         $fsize=-s $fname;
         if ($fsize<10){
            abend("The size of the file is $fsize. Nothing to do. Exiting");
         }
         unless( -r $fname ){
            abend("File does not have read permissions for the user");
         }
          open (STDIN, '<',$fname) || die("Can't open $fname for reading $!");
      }else{
          abend("Input file should be supplied as the first argument");
      }
      if( $debug){
          print STDERR "ATTENTION!!! Working in debugging mode debug=$debug\n";
      }
      out("=" x 121,"\n");
      get_globals();
      close STDIN;
      open (STDIN, '<',$fname) || die("Can't open $fname for reading");
      $PassNo=1;
      open(SYSOUT,'>',$output_file) || die("Can't open $output_file for writing");
      return;
} # prolog

%VarType = ('sys.argv'=>{main=>'a of S'},
            'os.name'=>{main=>'S'},
            EVAL_ERROR=>{main=>'S'},
            'os.environ'=>{main=>'h of S'}); # SNOOPYJC: {varname}{sub} = type (a, h, s, I, S, F, N, u, m)
%NeedsInitializing = ();        # SNOOPYJC: {sub}{varname} = type
# SNOOPYJC: initialized means it is set before it's being used
%initialized = (main=>{'sys.argv'=>'a of S',
                       'os.name'=>'S',
                       EVAL_ERROR=>'S',
                       'os.environ'=>'h of S'});       # {sub}{varname} = type

for my $g (keys %GLOBAL_TYPES) {                # SNOOPYJC
    my $t = $GLOBAL_TYPES{$g};
    $initialized{main}{$g} = $t;
    $VarType{$g}{main} = $t;
}


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
my %VarSubMap=(); # matrix  var/sub that allows to create list of global for each sub
   $CurSubName='main';
   $LocalSub{'main'}=1;
   foreach my $g (keys %GLOBALS) {             # SNOOPYJC
      $VarSubMap{$g}{$CurSubName}='+';         # SNOOPYJC
   }                                           # SNOOPYJC
   my $PriorExprType = undef;                  # SNOOPYJC: used to type the function result
   while(1){
      if( scalar(@Perlscan::BufferValClass)==0 ){
         $line=getline(); # get the first meaningful line, skipping commenets and  POD
         last unless(defined($line));
         if( $::debug==2 && $.== $::breakpoint ){
            say STDERR "\n\n === Line $. Perl source: $line ===\n";
            $DB::single = 1;
         }
         Perlscan::tokenize($line);
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
      if( $ValClass[0] eq 't' && $ValPerl[0] eq 'my' ){
         for($i=1; $i<=$#ValClass; $i++ ){
            last if( $ValClass[$i] eq '=' );
            if( $ValClass[$i] =~/[sah]/ ){
               check_ref($CurSubName, $i);              # SNOOPYJC
               $DeclaredVarH{$ValPy[$i]}=1; # this hash is need only for particular sub
            }
         }
         if( $i<$#ValClass ){
            for( $k=$i+1; $k<@ValClass; $k++ ){
               if( $ValClass[$k]=~/[sah]/ ){
                  check_ref($CurSubName, $k);           # SNOOPYJC
                  next if exists($DeclaredVarH{$ValPy[$k]});
                  next if( defined($ValType[$k]) && $ValType[$k] eq 'X');
                  $VarSubMap{$ValPy[$k]}{$CurSubName}='+';
               }
            } # for
         }
      # SNOOPYJC }elsif(  $ValPerl[0] eq 'sub' && $#ValClass==1 ){
      }elsif(  $ValPerl[0] eq 'sub' && $#ValClass >= 1) {         # SNOOPYJC: handle sub xxx() (with parens)
         $CurSubName=$ValPy[1];
         $LocalSub{$CurSubName}=1;
         %DeclaredVarH=(); # this is the list of my varible for given sub; does not needed for any other sub
	 $we_are_in_sub_body=1;			# issue 45
         if($::debug > 3) {
             say STDERR "get_globals: switching to '$CurSubName' at line $.";
         }
         correct_nest(0,0);                             # issue 45
      }elsif( $ValClass[0] eq '{') {                    # issue 45
          correct_nest(1);                              # issue 45
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
             $VarType{$CurSubName}{main} = merge_types($CurSubName, 'main', $typ);
	     $we_are_in_sub_body = 0;		# issue 45
	     $CurSubName='main';		# issue 45
	 }					# issue 45
      }else{
         for( $k=0; $k<@ValClass; $k++ ){
             if(  $ValClass[$k]=~/[sah]/ ){
                check_ref($CurSubName, $k);                  # SNOOPYJC
                if($k != 0 && $ValClass[$k-1] eq 't' && $ValPerl[$k-1] eq 'my') {       # SNOOPYJC e.g. for(my $i=...)
                    $DeclaredVarH{$ValPy[$k]} = 1;
                }
                next if exists($DeclaredVarH{$ValPy[$k]});
                next if(  defined($ValType[$k]) && $ValType[$k] eq 'X');
                next if($ValPy[$k] eq '');      # Undefined special var
                $VarSubMap{$ValPy[$k]}{$CurSubName}='+';
                if( $ValPy[$k] =~/[\[\(]/){
                   $InLineNo = $.;
                   say "=== Pass 1 INTERNAL ERROR in processing line $InLineNo Special variable is $ValPerl[$k] as $ValPy[$k], k=$k, ValType=@ValType";
                   $DB::single = 1;
                }
              }
          } # for
          if(scalar(@ValClass) > 0 && $ValClass[0] eq 'k' && $ValPerl[0] eq 'return') {         # SNOOPYJC: return statement
              $typ = 'm';
              if(scalar(@ValClass) > 1) {
                  $typ = expr_type(1, $#ValClass, $CurSubName);
              }
              $VarType{$CurSubName}{main} = merge_types($CurSubName, 'main', $typ);
          }
      } # statements
      # SNOOPYJC: Capture the prior expr type in case of implicit function return (as done by pythonizer::finish())
      # If we determine it's a mixed type ('m'), then stop checking
      if(scalar(@ValClass) == 0) {                              # SNOOPYJC
          $PriorExprType = 'm';                 # We couldn't have inserted a "return" here
      } elsif(exists $VarType{$CurSubName}{main} && $VarType{$CurSubName}{main} eq 'm') {   # SNOOPYJC: not worth checking
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
      correct_nest();                           # issue 45
   } # while

   if($::debug == 5) {
       print STDERR "VarSubMap = ";
       $Data::Dumper::Indent=1;
       say STDERR Dumper(\%VarSubMap);
       print STDERR "VarType = ";
       say STDERR Dumper(\%VarType);
       print STDERR "initialized = ";
       say STDERR Dumper(\%initialized);
       print STDERR "NeedsInitializing = ";
       $Data::Dumper::Indent=1;
       say STDERR Dumper(\%NeedsInitializing);
       print STDERR "sub_external_last_nexts = ";
       say STDERR Dumper(\%Perlscan::sub_external_last_nexts);
       print STDERR "line_needs_try_block = ";
       say STDERR Dumper(\%Perlscan::line_needs_try_block);
   }

   foreach $varname (keys %VarSubMap ){
      next if(  $varname=~/[\(\[]/ );
      # SNOOPYJC next if(  length($varname)==1 );
      next if($varname !~ /^[A-Za-z_][A-Za-z0-9_]*$/);   # SNOOPYJC: has to be a valid python var name
      $var_usage_in_subs=scalar(keys %{$VarSubMap{$varname}} );
      # SNOOPYJC if(  $var_usage_in_subs>1){
         # Varible that is present in multiple subs assumed to be global
         foreach $subname (keys %{$VarSubMap{$varname}} ){
            if($var_usage_in_subs>1 || exists $NeedsInitializing{$subname}{$varname}) { # SNOOPYJC
                $GlobalVar{$subname}.=','.$varname;
                # SNOOPYJC: Since this var exists in $VarSubMap, it's not a "my" variable and if
                # it needs initializing, we need to do it in the top-level scope, not in the sub
                if($subname ne 'main' && exists $NeedsInitializing{$subname}{$varname}) {     # SNOOPYJC
                    $VarType{$varname}{main} = merge_types($varname, $subname, $NeedsInitializing{$subname}{$varname});        # SNOOPYJC
                    $VarSubMap{$varname}{main} = '+';                   # SNOOPYJC
                    $NeedsInitializing{main}{$varname} = $NeedsInitializing{$subname}{$varname};        # SNOOPYJC
                    delete $NeedsInitializing{$subname}{$varname};      # SNOOPYJC
                }                                                       # SNOOPYJC
            }
         }
      # SNOOPYJC }
   }
   foreach $subname (keys %NeedsInitializing) {         # SNOOPYJC
       foreach $varname (keys %{$NeedsInitializing{$subname}}) {
           next if($varname !~ /^[A-Za-z_][A-Za-z0-9_]*$/);   # Has to be a valid python var name
           next if(!exists $VarSubMap{$varname}{$subname});   # if it's not in VarSubMap, then it's a "my" variable, which is handled in pythonizer
           $InitVar{$subname} .= "\n$varname = ".init_val($NeedsInitializing{$subname}{$varname});
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
}

sub init_val            # SNOOPYJC: Get the initializer value for the var, given the type
{
   $type = shift;

   my $val = 'None';
   $val = '0' if($type =~ /[IN]/);      # Integer or Number
   $val = '0.0' if($type eq 'F');       # Float
   $val = "''" if($type eq 'S');        # String
   $val = '[]' if($type eq 'a');        # array
   $val = '{}' if($type eq 'h');        # hash 
   return $val;
}

sub check_ref           # SNOOPYJC: Check references to variables so we can type them or later initialize them
{
    my $CurSub = shift;
    my $k = shift;      # Points to a scalar, hash, or array name

    my $name = $ValPy[$k];
    my $class;
    my $type = undef;
    $class = $ValClass[$k];
    if($::debug >= 3) {
        say STDERR "check_ref($CurSub, $name) at $k";
    }

    if($k > 0) {
        if($ValClass[$k-1] eq '^') {      # pre ++ or --
            $type = 'I';
            $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
        } elsif($ValClass[$k-1] eq 'f' && $ValPerl[$k-1] eq 'defined') {
            # If they are checking if this var is defined, then we have to init it to "None" if
            # we're called on to init it, so set the type to 'm' for "mixed".  This means we
            # need to convert it using _num and _str each time we reference it so we don't get
            # any NoneType exceptions.
            $type = 'm';
        }
    }

    return if(!$name);

    if($k+1 <= $#ValClass) {
        if($ValClass[$k+1] eq '=') {
            $type = expr_type($k+2, $#ValClass, $CurSub);
            my $op = $ValPerl[$k+1];
            if($op eq '=') {     # e.g. not +=
                $initialized{$CurSub}{$name} = $type;
            } elsif($op eq '.=') {
                $type = 'S';
                $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
            } else {                # +=, -=, *=, /=, |=, &=
                $type = 'N' unless($type eq 'I' || $type eq 'F');        # numeric
                $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
            }
        } elsif($ValClass[$k+1] eq '^') {   # ++ or --
            $type = 'I';
            $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
        } elsif(!defined $type) {
            $m = next_same_level_tokens(')', $k, $#ValClass); 
            #say STDERR "m = $m";
            if($m != -1 && $m < $#ValClass && $ValClass[$m+1] eq '=') {        # like ($v1, $v2) = RHS;
                $rhs_type = expr_type($m+2, $#ValClass, $CurSub);
                if($rhs_type =~ /^a of (.*)$/) {            # like a of S
                    $type = $1;
                    $initialized{$CurSub}{$name} = $type;
                }
            }
        }
    }
    if($k == 1 && $ValClass[0] eq 'c' && $ValPy[0] eq 'for') {  # Var in a foreach loop is initialized
        $type = expr_type($k+1, $#ValClass, $CurSub);
        $type =~ s/^a of //;
        $initialized{$CurSub}{$name} = $type;
    } elsif(($k >=1 && $ValClass[$k-1] eq 'f' && ($ValPerl[$k-1] eq 'open' || $ValPerl[$k-1] eq 'opendir')) ||  # open $fh
           ($k >=2 && $ValClass[$k-1] eq '(' && $ValClass[$k-2] eq 'f' && ($ValPerl[$k-2] eq 'open' || $ValPerl[$k-2] eq 'opendir'))  ||  # open($fh
           ($k >=3 && $ValClass[$k-1] eq 't' && $ValClass[$k-2] eq '(' && $ValClass[$k-3] eq 'f' && ($ValPerl[$k-3] eq 'open' || $ValPerl[$k-3] eq 'opendir'))) { # open(my $fh
        $type = 'H';
        $initialized{$CurSub}{$name} = $type;
    }

    if(defined $type) {
        $VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type);
        $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
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
                $rhs_type = 'I';
            }
        }
        if(defined $rhs_type) {
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, "$type of $rhs_type");
        } else {
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, "$type of u");
        }
    } elsif($class eq 'a' || $class eq 'h') {    # e.g. if(@arr) or if(%hash) or push @arr, ...
        $NeedsInitializing{$CurSub}{$name} = $class if(!exists $initialized{$CurSub}{$name});
   } elsif(!defined $type) {                            # Scalar reference - try to find what type it needs to be
        $type = scalar_reference_type($k);
        if($::debug >= 3) {
            say STDERR "scalar_reference_type($k) = $type";
        }
        # Don't override an assigned type with a referenced type, since normally
        # we will change references to use _num() or _str(), but if this var
        # is not initialized, then we can set it's type here, e.g. if it's used as an array ref.
        if(!exists $VarType{$name}{$CurSub} || $VarType{$name}{$CurSub} eq 'u') {
            $VarType{$name}{$CurSub} = merge_types($name, $CurSub, $type);
        }
        $NeedsInitializing{$CurSub}{$name} = $type if(!exists $initialized{$CurSub}{$name});
    }
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
                for(my $j=$i+2; $j<=$k; $j++) {
                    last if($k == $j);
                    $arg++ if($ValClass[$j] eq ',');
                    $j = matching_br($j) if($ValClass[$j] eq '(');
                    return 'u' if($j < 0);
                }
            }
            my $ty = arg_type($fname, $arg);
            if($::debug > 3) {
                say STDERR "arg_type($fname, $arg) = $ty";
            }
            return $ty if(defined $ty);
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
    return 'u';
}

sub arg_type            # Given the name of a built-in function, and the arg#, return the required type
{
    my $name = shift;
    my $arg = shift;

    return 'u' if(!exists $Perlscan::FuncType{$name});
    my $ft = $Perlscan::FuncType{$name};
    my $argc = 0;
    for(my $i = 0; $i < length($ft); $i++) {
        my $c = substr($ft,$i,1);
        return 'u' if($c eq ':');       # We reached the end
        if($c eq 'H' && substr($ft,$i+1,1) eq '?') {
            $i++;
            $argc++;
            next;
        }
        next if($c eq '?');
        if($argc == $arg) {
            return $c;
        }
        if($c eq 'a') {
            return 's';                 # unknown scalar
        }
        $argc++;
    }
    return undef;                 # probably not part of this function
}

sub merge_types         # SNOOPYJC: Merge type of object when we get new info
{
    my $name = shift;
    my $CurSub = shift;
    my $type = shift;

    if($::debug >= 3) {
        say STDERR "merge_types($name, $CurSub, $type)";
    }

    if(!defined $type) {
        $type = 'u';
    }
    if(!exists $VarType{$name}{$CurSub}) {
        return $type;
    }
    $otype = $VarType{$name}{$CurSub};
    if($::debug >= 3) {
        say STDERR "merge_types: otype=$otype";
    }
    if($otype eq 'u') {         # unknown - treat like we have no info yet
        return $type;
    }
    if($type eq 'u') {
        return $otype;
    }
    return $type if($type eq $otype);   # Same type
    if(($otype eq 'a' || $otype eq 'h') && $type =~ /$otype of/) {
        return $type;           # we have more specific info
    }
    if(($type eq 'a' || $type eq 'h') && $otype =~ /$type of/) {
        return $otype;           # we have less specific info
    }
    if(($otype =~ /[ah] of/) && ($type =~ /[ah] of/)) {
        @olist = split / of /,$otype;
        @list = split / of /,$type;
        my $len = (scalar(@olist) >= scalar(@list) ? scalar(@list) : scalar(@olist));
        for(my $i = 0; $i < $len; $i++) {
            if($list[$i] ne $olist[$i]) {
                if($list[$i] eq 'u') {          # Was undef, now defined
                    return join(' of ', @olist);
                } elsif($olist[$i] eq 'u') {
                    return join(' of ', @list);
                }
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
    } elsif(($otype eq 's' || $otype eq 'u') && ($type =~ /[NIFSH]/)) {        # more specific type
        return $type;
    } elsif($otype eq 'N' && ($type =~ /[IF]/)) {   # Numeric -> Int or Float
        return $type;
    } elsif($type eq 'N' && ($otype =~ /[IF]/)) {   # Numeric -> Int or Float
        return $otype;
    } elsif(($type =~ /[IF]/) && ($otype =~ /[IF]/)) {  # int vs float
        return 'F';             # Float wins
    } elsif($otype eq 'u' && $type eq 's') {
        return $type;
    }
    return 'm';         # Mixed
}

sub expr_type           # Attempt to determine the type of the expression
{
    my $k = shift;
    my $e = shift;
    my $CurSub = shift;

    my $class = $ValClass[$k];
    if($::debug >= 3) {
        say STDERR "expr_type($k, $e, $CurSub)";
    }
    if($class eq 'f') {         # built-in function call
        return func_type($ValPerl[$k]);
    } elsif($k == $#ValClass) {      # we have one thing
        if($class eq 'd') {             # Digits
            if($ValPy[$k] =~ /^(?:0[xbo])?\d+$/) {
                return 'I';             # Integer
            }
            return 'F';                 # Float
        } elsif($class eq 's') {        # Scalar
            return $VarType{$ValPy[$k]}{$CurSub} if(exists $VarType{$ValPy[$k]}{$CurSub});
            return 's';                 # scalar
        } elsif($class eq '"' || $class eq 'x') {       # string or `exec`
            return 'S';                 # string
        }
        return 'u';
    } elsif($class eq 'i') {    # bare word
        my $name = $ValPy[$k];
        if($LocalSub{$name} || exists $VarType{$name}{main}) {
            return $VarType{$name}{main} if(exists $VarType{$name}{main});
            return 'm';
        } elsif($k+1 <= $#ValClass && $ValClass[$k+1] eq '(') {
            return $VarType{$name}{main} if(exists $VarType{$name}{main});
            return 'm';
        }
        return 'S';             # will be changed to a string
    } elsif($class ne '(') {            # Non-parenthesized expression
        my $m = next_same_level_tokens('>+-*/%0o.', $k, $#ValClass);
        if($m != -1) {
            if($ValClass[$m] eq '.') {
                return 'S';             # String concat
            } elsif($ValClass[$m] eq '>') {     # could be like < or like lt
                return 'S' if($ValPerl[$m] =~ /^[a-z][a-z]$/);  # like eq, gt, etc
                return 'I';     # boolean is an Int in perl
            }
            return 'N';         # Numeric
        } elsif($class eq 's' && $ValClass[$k+1] eq '(') {    # An array with possible subscript or hash with key
            my $name = $ValPy[$k];
            if(exists $VarType{$name}{$CurSub} && index(' of ', $VarType{$name}{$CurSub}) > 0) {
                my $typ = $VarType{$name}{$CurSub};
                my $p = $k+1;
                while($ValClass[$p] eq '(') {
                    $q = matching_br($p);
                    last if($q < 0);
                    $typ =~ s/^. of //;
                    $p = $q+1;
                }
                return $typ if($typ);
            }
        }
        return 'u';
    } else {                    # '('
        # Handle (a, b) = ...
        my $m = matching_br($k);
        if($m > 0 && $m+1 < $#VarClass && $VarClass[$m+1] eq '=') {
            return 'u';
        }
        # Check for list first
        $m = next_same_level_tokens(',', $k+1, $#ValClass-1);
        if($m != -1) {
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
                    my $o = next_same_level_tokens(',)', $m+1, $#ValClass-1);
                    last if($o < 0);
                    my $u = expr_type($m+1, $o-1, $CurSub);
                    $t = common_type($t, $u);
                    last if($ValClass[$o] eq ')');
                    $m = $o;
                }
            }
            return "a of $t";
        } else {        # Not a list, just a parenthesized expression
            return expr_type($k+1, $#ValClass-1, $CurSub);           # Just get the type of the expression in the (...)
        }
    }
}

sub common_type         # Create a common type from 2 types
{
    my $t1 = shift;
    my $t2 = shift;

    return $t1 if($t1 eq $t2);          # That was easy!
    return $t2 if($t1 eq 'u');          # u = undefined
    return $t1 if($t2 eq 'u');
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
        return substr($t1,0,$lcp) . common_type(substr($t1,$lcp), substr($t2,$lcp));
    }
    return 'm';
}

sub lcp {               # Longest common prefix - LOL don't ask me how it works!
    (join("\0", @_) =~ /^ ([^\0]*) [^\0]* (?:\0 \1 [^\0]*)* $/sx)[0];
}

sub func_type                   # Get the result type of this built-in function
{
    my $fname = shift;          # send us ValPerl

    return 'u' if(!exists $Perlscan::FuncType{$fname});
    my $type = $Perlscan::FuncType{$fname};
    $type =~ s/^.*://;
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
  return $#TokenStr;
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
  return 0;
} # reverse_matching_br

sub next_matching_token                 # SNOOPYJC
# get the next matching token
{
my $t=$_[0];
my $scan_start=$_[1];
my $scan_end=$_[2];
    $k = index(substr($TokenStr, $scan_start, $scan_end-$scan_start+1), $t);
    return $k if($k < 0);
    return $k + $scan_start;
} # next_matching_token

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
      }
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
          }
      }
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

sub get_here
#
#Extract here string with delimiter specified as the first argument
#The second argument, if true, means to remove leading whitespace from the result like <<~ does
#
{
my $here_str='';        # issue 39
my $line=<>;		# issue 39
   $line =~ s/[\r\n]+//sg;        # issue 39
   if($::debug > 2) {
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
      $line=<>;                 # issue 39
      if(!defined $line) {
         logme('S', "Unclosed here string - terminiator '$_[0]' not found");
	 last;
      }
      $line =~ s/[\r\n]//sg;        # issue 39
      if($::debug > 2) {
   	say STDERR "get_here:line=$line, lno=$., len_eof=$len_eof, length(line)=".length($line).", spaces=$spaces, defined line=".defined $line;
      }
   }
   if($_[1]) {                  # Have the <<~ ?
       if($::debug > 2) {
   	   say STDERR "get_here:here_str=$here_str (before strip)";
       }
       $here_str =~ s/^\s{$spaces}//gm;
   }
   if($::debug > 2) {
   	say STDERR "get_here:here_str=$here_str";
   }
   # issue 39 return '""""'."\n".$here_str."\n".'"""""'."\n";
   return '"""'.$here_str.'"""';	# issue 39
} # get_here


sub getline
#
#get input line. It has now ability to buffer line, which will be scanned by tokeniser next.
# issue 45: if you pass in a 0, this means to defer outputting of blank and comment lines, which
# issue 45: will then be output on the next call.  Pass in a 1 just to do that output.
#
{
state @buffer; # buffer to "postponed lines. Used for translation of postfix conditinals among other things.
   #say STDERR "getline(@_): BufferValClass=@Perlscan::BufferValClass, buffer=@buffer";
   # issue 95 return $line if( scalar(@Perlscan::BufferValClass)>0  ); # block input if we process token buffer Oct 8, 2020 -- NNB
   state @output_buffer = ();   # issue 45
   $flag = -1;                  # issue 45
   if ( scalar(@_) == 1 && 
        length( do { no if $] >= 5.022, "feature", "bitwise"; no warnings "numeric"; $_[0] & "" } ) ) {
       $flag = shift;           # issue 45: LOL all this just to see if I passed in a number or a string!
   }
   if($flag == 1) {             # issue 45: just output any buffered lines
       while($o = pop @output_buffer) {
           output_line(@$o);
       }
       return $line;
   }
   if(  scalar(@_)>0 ){
       return if(scalar(@_) == 1 && $_[0] eq '');       # SNOOPYJC: Don't make extra blank lines
       push(@buffer,@_); # buffer lines in the order they listed; they will be injected in the next call;
       #if (scalar(@_)==3){
       #  say join('|',@_);
       #  $DB::single = 1;
       #}
       #say STDERR "getline(@_): pushed to buffer";
       return;
   }
   return $line if( scalar(@Perlscan::BufferValClass)>0  ); # issue 95: block input if we process token buffer Oct 8, 2020 -- NNB
   my $output_line = sub {                      # issue 45
       return if(!$PassNo);
       if($flag == 0) {
            my @args = @_;      # make a copy
            push @output_buffer, \@args;
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
         #say STDERR "getline(): got $line from buffer, buffer=@buffer";
      }else{
         $line=<>;
         #my $l2 = $line;
         #$l2 =~ s/[\n\r]//g;
         #say STDERR "getline(): got $l2 from <>";
         return $line unless (defined($line)); # End of file
      }

      chomp($line);
      if(  length($line)==0 || $line=~/^\s*$/ ){
         &$output_line('');             # isue 45: blank line
         next;
      }elsif(  $line =~ /^\s*(#.*$)/ ){
         # pure comment lines
         &$output_line('',$1);          # issue 45
         next;
      }elsif(  $line =~ /^__DATA__/ || $line =~ /^__END__/){
         # data block
         return undef if(  $PassNo==0 );
         open(SYSDATA,'>',"$source_file.data") || abend("Can't open file $source_file.data for writing. Check permissions" );
         logme('W',"Tail data after __DATA__ or __END__ line are detected in Perl Script. They are written to a separate file $source_file.data");
         while( $line=<> ){
            print SYSDATA $line;
         }
         close SYSDATA;
         return $line;
      }elsif(  substr($line,0,1) eq '='){
         # POD block
         # issue 79 output_line('',q['''']);
         &$output_line('',q[''']);                # issue 79, issue 45
         &$output_line('',$line,1);               # issue 79, issue 45
         while($line=<>){
             # issue 79 last if( $line eq '=cut');
            &$output_line('',$line,1);            # issue 79, issue 45
            if( substr($line,0,4) eq '=cut') {      # issue 79
                $line = <>;                         # issue 79
                last;
            }
         }
         # issue 79 output_line('',q['''']) if(  $PassNo);
         &$output_line('',q[''']);      # issue 79, issue 45
      }elsif( substr($line,0,5) eq 'goto ') {   # SNOOPYJC: strange way to skip some code
         $line =~ /goto\s+([A-Za-z0-9_]+)/;
         $label = $1;
         &$output_line('',q[''']);              # issue 45
         &$output_line('',$line,1);             # issue 45
         while($line=<>){
            &$output_line('', $line,1);         # issue 45
            if( $line =~ /^$label:/ ) {
                $line = <>; 
                last;
            }
         }
         &$output_line('',q[''']);              # issue 45
      }

      return $line if(!defined $line);          # issue 79 - gives lots of errors below if we hit EOF

      if(  substr($line,-1,1) eq "\r" ){
         chop($line);
      }
      $line =~ s/\s+$//; # trim tailing blanks
      $line =~ s/^\s+//; # trim leading blanks
      if ($line eq '{' || $line eq '}') {
          $IntactLine='';
      }else{
         $IntactLine=$line;
      }
      return  $line;
   }
}

#::output_line -- Output line shifted properly to the current nesting level
# arg 1 -- actual PseudoPython generated line
# arg 2 -- tail comment (added Dec 28, 2019)
# arg 3 -- copy without processing ( (added Sep 3, 2020))
sub output_line
{
return if ($PassNo==0); # no output during the first pass
my $line=(scalar(@_)==0 ) ? $IntactLine : $_[0];
my $tailcomment=(scalar(@_)>=2 ) ? $_[1] : '';          # SNOOPYJC
my $indent=' ' x $::TabSize x $CurNest;
my $flag=( defined($main::TrStatus) && $main::TrStatus < 0 ) ? 'F' : ' ';
my $len=length($line);
my $prefix=sprintf('%4u',$.)." |".sprintf('%2u',$CurNest)." | ".sprintf('%1s',$flag)." |";
my $zone_size=($maxlinelen-length($prefix))/2; # length of prefix is 20
my $start_of_comment_zone=$zone_size+length($prefix); #  the start of comment_zone is 20+80=100.
#                                                   So the total line length=180
my $orig_tail_len=length($tailcomment);
my $i;
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
         out($prefix,join(' ',@::ValPy)." #FAIL $IntactLine");
         say SYSOUT join(' ',@::ValPy)." #FAIL $IntactLine";
      }else{
         out($prefix,$tailcomment);
         say SYSOUT $tailcomment;
      }
      return;
   }
   if(  scalar(@_)<3){
      $line=($line=~/^\s+(.*)$/ )? $indent.$1 : $indent.$line;
   }
   if($orig_tail_comment) {     # SNOOPYJC
      say SYSOUT "$line    $orig_tail_comment";       # SNOOPYJC
   } else {
      say SYSOUT $line;
   }
   $line=$prefix.$line;
   $len=length($line); # new length woth prefix containing line no and nesting
my (@lineblock,$filler);
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
            }else{
               @lineblock=split("\n",$IntactLine);
               print_intactline($lineblock[0],$zone_size,$start_of_comment_zone);
               for(my $i=1; $i<@lineblock;$i++){
                  print_intactline($lineblock[$i],$zone_size,$start_of_comment_zone);
               }
            }
         }else{
            out($line,' #PL: ',$IntactLine);
         }
     }else{
         # short line without tail comment
         $filler=' ' x ($start_of_comment_zone-$len);
          if (index($IntactLine,"\n")==-1){
              out($line,$filler,' #PL: ',$IntactLine);
          }else{
             @lineblock=split("\n",$IntactLine);
             out($line,$filler,' #PL: ',$lineblock[0]); # its short so this is OK
             for( $i=1; $i<@lineblock;$i++){
                print_intactline($lineblock[$i],$zone_size,$start_of_comment_zone);
             }
          }
      }
   }else{
     #line with tail comment
     $i=index($tailcomment,"\n");
     if($i==-1) {
        out($line,' ',$tailcomment); # output with the original comment instead of Perl source
        print_intactline(substr($IntactLine,0,-$orig_tail_len),$zone_size,$start_of_comment_zone); # print Perl source
     }else{
        @lineblock=split("\n",$IntactLine);
        out($line,' ',$tailcomment); # output with tail comment instead of Perl comment
        print_intactline(substr($lineblock[0],0,-$orig_tail_len),$zone_size,$start_of_comment_zone);
        for( $i=1; $i<@lineblock;$i++){
            print_intactline($lineblock[$i],$zone_size,$start_of_comment_zone);
        }
     }
   }

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
         logme('E',"Attempt to set next nesting level above the treshold($MAXNESTING) ignored");
         $DB::single = 1;
      }
   }elsif(  $NextNest+$delta < 0 ){
      if ($::debug>2 ) {
         logme('S',"Attempt to set the next nesting level below zero ignored");
         $DB::single = 1;
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

sub move_defs_before_refs		# SNOOPYJC: move definitions up before references in the output file
{
    close SYSOUT;
    open(SYSOUT,'<',$output_file);
    # Pass 1 - find all the defs
    my %defs = ();
    chomp(my @lines = <SYSOUT>);
    close SYSOUT;
    $lno = 0;
    for my $line (@lines){
        $lno++;
        if($line =~ /^def ([A-Za-z0-9_]+)/) {
            my $i;
            my $func = $1;
            for($i = $lno-1; $i >= 1; $i--) {
                # Grab any prior blank lines or comments
                if($lines[$i-1] =~ /^\s*$/ || $lines[$i-1] =~ /^\s*#/) {
                    ;
                } else {
                    $i++;
                    last;
                }
            }
            $defs{$func} = $i;
        }
    }
    # Pass 2 - find all the refs
    my @words = keys %defs;
    #say STDERR "Defs: @words";
    my %refs = ();
    my $insertion_point = 0;
    $lno = 0;
    my $in_def = 0;
    for my $Line (@lines) {
        $lno++;
        $insertion_point = $lno+1 if($Line =~ /^$PERL_ARG_ARRAY = sys.argv/ && !$insertion_point);
        #say STDERR "$lno: $line";
        $line = eat_strings($Line);     # we change variables so eat_strings doesn't modify @lines
        if($in_def) {
            $in_def = 0 if($line !~ /^def / && length($line) >= 1 && $line !~ /^\s*#/ && $line !~ /^\s/ && !$multiline_string_sep);
            #say STDERR "Not in_def on $line" if(!$in_def);
        } else {
            $in_def = 1 if($line =~ /^def /);
            #say STDERR "in_def on $line" if($in_def);
        }
        ### YES THEY DO!!  next if($in_def);               # Refs inside of defs don't matter
        next if($line =~ /^\s*#/);      # ignore comments
        my @found = grep { $line =~ /\b$_\b/ } @words;
        foreach $f (@found) {
            if(!defined $refs{$f}) {    # Only put in the first one
                $refs{$f} = $lno;
            }
        }
    }
    #say STDERR "Refs @{[%refs]}";
    return if(!$insertion_point);
    # Create the move group
    my %to_move = ();
    for my $ref (keys %refs) {
        $ref_lno = $refs{$ref};
        $def_lno = $defs{$ref};
        if($ref_lno < $def_lno) {
            $to_move{$ref} = 1;
        }
    }
    my $size = keys %to_move;
    return if(!cleanup_imports(\@lines) && $size == 0);      # nothing to do
    #say STDERR "to_move: @{[%to_move]}";
    #say STDERR "defs @{[%defs]}";
    # Pass 3 - regenerate the output file in the right order
    open($sysout,'>',$output_file);
    $lno = 0;
    my %moved_lines = ();
    $multiline_string_sep = '';
    for my $line (@lines) {
        $lno++;
        if($lno < $insertion_point) {
           pep8($sysout, $line);
           next
        }
        for my $func (keys %to_move) {
            $start_line = $defs{$func};
            for(my $i=$start_line-1; $i<scalar(@lines); $i++) {
                if($multiline_string_sep) {
                    unless(exists $moved_lines{$i+1}) {
                        say $sysout $lines[$i];
                        $moved_lines{$i+1} = 1;
                    }
                    $multiline_string_sep = '' if(index($lines[$i], $multiline_string_sep) >= 0);
                    next;
                } elsif(($lines[$i] =~ /"""/ || $lines[$i] =~ /'''/) && $lines[$i] !~ /^\s*#/) {
                    $ndx = index($lines[$i], '"""');
                    $ndx = index($lines[$i], "'''") if $ndx < 0;
                    $multiline_string_sep = substr($lines[$i],$ndx,3);
                    # if the string terminates on the same line, then it's not a multiline string
                    $multiline_string_sep = '' if(index($lines[$i], $multiline_string_sep, $ndx+3) >= 0);
                }
                if($lines[$i] =~ /^\s+/ || $lines[$i] =~ /^def $func\(/ ||
                        $lines[$i] =~ /^\s*$/ || $lines[$i] =~ /^\s*#/) {
                        #say STDERR "Found def $func";
                    next if(exists $moved_lines{$i+1});         # Don't include it twice
                    $moved_lines{$i+1} = 1;
                    #say STDERR "writing lines[$i] ($lines[$i])";
                    pep8($sysout, $lines[$i]);
                } else {
                    last;
                }
            }
        }
        %to_move = ();
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
        pep8($sysout, $line);
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

    $this_is_blank = $line =~ /^\s*$/;
    $this_is_comment = $line =~ /^\s*#/;
    $line =~ /^(\s*)/;
    $this_indent = length($1);
    $this_indent = 0 if($this_is_blank);
    if($this_is_comment) {              # Just ignore and spit out comment lines
        say $out $line;
        $last_was_blank = 0;
        return;
    } elsif($this_is_blank && $last_was_blank) {        # eliminate multiple blank lines
        return;
    } elsif($this_indent <= $last_indent && $line =~ /^\s*pass$/) {
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
    $last_indent = $this_indent if(!$this_is_blank);
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
    my $loop_control_def_lno = 0;       # class LoopControl(Exception):
    my $as_what = '';
    my @imports = ();
    my %referenced_imports = ();
    my @globals = keys %GLOBALS;
    my %global_lnos = ();
    my %referenced_globals = ();
    my $import_as_referenced = 0;
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
    for my $line (@$line_ref) {
        $lno++;
        if($line =~ /^import /) {
            my $import_s = $line =~ s/^import //r;
            if(index($import_s, ' as ') > 0) {      # import time as tm_py
                ($as_what) = $line =~ / as ([a-z_]+)/;
                $import_as_lno = $lno;
            } else {
                @imports = split /,/, $import_s;
                $import_lno = $lno;
            }
        } elsif($line =~ /^class Die\(/) {
            $die_def_lno = $lno;
        } elsif($line =~ /^class $loop_control\(/) {      # issue 94
            $loop_control_def_lno = $lno;
        } elsif($line =~ /^class $EVAL_RETURN_EXCEPTION\(/) {
            $eval_return_lno = $lno;
            #} elsif($line =~ /^LIST_SEPARATOR = /) {
            #$list_sep_lno = $lno;
            #} elsif($line =~ /^$SCRIPT_START = /) {
            #$script_start_lno = $lno;   # doesn't count for $import_as_referenced
        } elsif((@gl = grep { $line =~ /^$_ = / } @globals)) {
            $g = $gl[0];
            $global_lnos{$g} = $lno;
            if($line =~ /\b$as_what\./) {
                $import_as_global = $g;
            }
        } elsif($import_lno) {
            my @found = grep { $line =~ /\b$_\./ } @imports;
            foreach my $f (@found) {
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
            } elsif($line =~ /\bDie\b/) {
                $die_referenced = 1;
            } elsif($line =~ /\b$loop_control\b/) {
                $loop_control_referenced = 1;
            } elsif($line =~ /\b$EVAL_RETURN_EXCEPTION\b/) {
                $eval_referenced = 1;
                #} elsif($line =~ /\b$SCRIPT_START\b/ || $line =~ /\b_get[ACM]\b/) {
                #$script_start_referenced = 1;
                #$import_as_referenced = 1;      # yes, this references that!
            }
        }
    }
    #say STDERR "cleanup_imports import_lno=$import_lno, refs=@{[%referenced_imports]}, imports=@imports, as_what=$as_what, import_as_referenced=$import_as_referenced, import_as_lno=$import_as_lno, die_referenced=$die_referenced, die_def_lno=$die_def_lno";
    if($import_lno) {
        my $size = keys %referenced_imports;
        if($size) {
            $line_ref->[$import_lno-1] = 'import ' . join(',', keys %referenced_imports);
        } else {
            $line_ref->[$import_lno-1] = '';
        }
        if($import_as_lno && !$import_as_referenced) {
            $line_ref->[$import_as_lno-1] = '';
        }
        if($die_def_lno && !$die_referenced) {
            $line_ref->[$die_def_lno-1] = '';   # class Die(Exception):
            $line_ref->[$die_def_lno] = '';     #     pass or def __init__(...):
            $line_ref->[$die_def_lno+1] = '' if($::traceback);     #     traceback
        }
        if($loop_control_def_lno && !$loop_control_referenced) {
            $line_ref->[$loop_control_def_lno-1] = '';   # class LoopControl(Exception):
            $line_ref->[$loop_control_def_lno] = '';     #     pass
        }
        if($eval_return_lno && !$eval_referenced) {
            $line_ref->[$eval_return_lno-1] = '';   # class $EVAL_RETURN_EXCEPTION(Exception):
            $line_ref->[$eval_return_lno] = '';     #     pass
        }
        #if($list_sep_lno && !$list_sep_referenced) {
        #$line_ref->[$list_sep_lno-1] = '';
        #}
        #if($script_start_lno && !$script_start_referenced) {
        #$line_ref->[$script_start_lno-1] = '';
        #}
        foreach my $g (keys %global_lnos) {
            if(!exists $referenced_globals{$g}) {
                $line_ref->[$global_lnos{$g}-1] = '';
            }
        }
        return 1;
    }
    return 0;
}

sub eat_strings
# Given a python line, eat any strings in it.  Handle multi-line strings with ''' or """ too!
{
    state $mstring_sep = '';
    my $line = shift;
    #print STDERR "eat_strings($line)=";
    if($mstring_sep) {
        if(($ndx = index($line, $mstring_sep)) >= 0) {
            $mstring_sep = '';
            $line = substr($line, $ndx+3);
        }
        $line = '';
    } elsif(($line =~ /"""/ || $line =~ /'''/) && $line !~ /^\s*#/) {
        $ndx = index($line, '"""');
        $ndx = index($line, "'''") if $ndx < 0;
        $mstring_sep = substr($line,$ndx,3);
        # if the string terminates on the same line, then it's not a multiline string
        if($ndx > 0) {
           my $c = substr($line,$ndx-1,1);
           $ndx-- if($c eq 'f' || $c eq 'r');   # Eat the 'f' from f-strings, and 'r' likewise
        }
        if(($ndx2 = index($line, $mstring_sep, $ndx+3)) >= 0) {
            $mstring_sep = '';
            #substr($line,$ndx,$ndx2+4-$ndx) = '';
            $line = substr($line,0,$ndx).substr($line,$ndx2+3);
        } else {                # Start of a multi-line string
            #substr($line,$ndx) = '';
            $line = substr($line,0,$ndx);
        }
    } else {
        my @quotes = ('"', "'");
        for my $quote (@quotes) {
	    OUTER:
            while(1) {
                $ndx = index($line, $quote);
                last if($ndx < 0);
                my $start = $ndx;
                if($start > 0) {
                    my $c = substr($line,$start-1,1);
                    $start-- if($c eq 'f' || $c eq 'r');   # Eat the 'f' from f-strings, and 'r' likewise
                }
                while(1) {
                    $ndx2 = index($line, $quote, $ndx+1);
                    if($ndx2 >= 0) {
                        if(substr($line,$ndx2-1,1) eq "\\" && ($ndx2-2<0 || substr($line,$ndx2-2,1) ne '\\')) {
                            $ndx = $ndx2;
                            next;
                        }
                        #substr($line,$start,$ndx2+1-$start) = '';
                        $line = substr($line,0,$start).substr($line,$ndx2+1);
                        last;
                    } else {
                        last OUTER;
                    }
                }
            }
        }
    }
    #say STDERR $line;
    return $line;
}

1;
