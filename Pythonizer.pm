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
use Perlscan qw(tokenize $TokenStr @ValClass @ValPerl @ValPy @ValType);
use Softpano qw(abend logme out getopts standard_options);
use config;				# issue 32
use Data::Dumper;       # SNOOPYJC
require Exporter;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw(preprocess_line correct_nest getline prolog output_line %LocalSub %GlobalVar);
our  ($IntactLine, $output_file, $NextNest,$CurNest, $line);
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
   # issue 32 $maxlinelen=188;
   $maxlinelen=$MAXLINELEN;
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
            `cp -p $fname $fname.bak && tr -d "\r" < $fname.bak > $fname`; # just in case
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
               $DeclaredVarH{$ValPy[$i]}=1; # this hash is need only for particular sub
            }
         }
         if( $i<$#ValClass ){
            for( $k=$i+1; $k<@ValClass; $k++ ){
               if( $ValClass[$k]=~/[sah]/ ){
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
      }elsif( $ValClass[0] eq '}' ) {		# issue 45
	 if($we_are_in_sub_body && $NextNest == 0) {	# issue 45
	     $we_are_in_sub_body = 0;		# issue 45
	     $CurSubName='main';		# issue 45
	 }					# issue 45
      }else{
         for( $k=0; $k<@ValClass; $k++ ){
             if(  $ValClass[$k]=~/[sah]/ ){
                next if exists($DeclaredVarH{$ValPy[$k]});
                next if(  defined($ValType[$k]) && $ValType[$k] eq 'X');
                $VarSubMap{$ValPy[$k]}{$CurSubName}='+';
                if( $ValPy[$k] =~/[\[\(]/){
                   $InLineNo = $.;
                   say "=== Pass 1 INTERNAL ERROR in processing line $InLineNo Special variable is $ValPerl[$k] as $ValPy[$k], k=$k, ValType=@ValType";
                   $DB::single = 1;
                }
              }
          } # for
      } # statements
   } # while

   if($::debug == 5) {
       print STDERR "VarSubMap = ";
       $Data::Dumper::Indent=1;
       say STDERR Dumper(\%VarSubMap);
   }

   foreach $varname (keys %VarSubMap ){
      next if(  $varname=~/[\(\[]/ );
      next if(  length($varname)==1 );
      $var_usage_in_subs=scalar(keys %{$VarSubMap{$varname}} );
      if(  $var_usage_in_subs>1){
         # Varible that is present in multiple subs assumed to be global
         foreach $subname (keys %{$VarSubMap{$varname}} ){
            $GlobalVar{$subname}.=','.$varname;
         }
      }
   }
   ($::debug) && out("\nDETECTED GLOBAL VARIABLES:");
   foreach $subname (keys %GlobalVar ){
      $GlobalVar{$subname}='global '.substr($GlobalVar{$subname},1);
      ($::debug) && out "\t$subname: $GlobalVar{$subname}";
   }
   ($::debug) && out("\nList of local subroutines:");
   ($::debug) && out(join(' ', keys %LocalSub));
   #here we have already populated array Sub2name with the list of subs and $global_list with the list of global variables
}

sub get_here
#
#Extract here string with delimiter specified as the first argument
#
{
my $here_str;
   $line=getline();		# issue 39
   if($::debug > 2) {
      say STDERR "get_here($_[0]): line=$line\n";
   }
   if(!$line) {
      logme('S', "Unclosed here string - terminiator '$_[0]' not found");
   }
   while (substr($line,0,length($_[0])) ne $_[0] ){
      # issue 39 $here_str.=$line;
      $here_str.=$line."\n";
      $line=getline();
      if($::debug > 2) {
   	say STDERR "get_here:line=$line\n";
      }
      if(!$line) {
         logme('S', "Unclosed here string - terminiator '$_[0]' not found");
	 last;
      }
   }
   # issue 39 return '""""'."\n".$here_str."\n".'"""""'."\n";
   return '"""'.$here_str.'"""';	# issue 39
} # get_here


sub getline
#
#get input line. It has now ability to buffer line, which will be scanned by tokeniser next.
#
{
state @buffer; # buffer to "postponed lines. Used for translation of postfix conditinals among other things.
   return $line if( scalar(@Perlscan::BufferValClass)>0  ); # block input if we process token buffer Oct 8, 2020 -- NNB
   if(  scalar(@_)>0 ){
       push(@buffer,@_); # buffer lines in the order they listed; they will be injected in the next call;
       #if (scalar(@_)==3){
       #  say join('|',@_);
       #  $DB::single = 1;
       #}
       return;
   }
   while(1 ){
      #
      # firs we perform debufferization
      #
      if(  scalar(@buffer) ){
         $line=shift(@buffer);
      }else{
         $line=<>;
         return $line unless (defined($line)); # End of file
      }

      chomp($line);
      if(  length($line)==0 || $line=~/^\s*$/ ){
         output_line('') if(  $PassNo); # blank line
         next;
      }elsif(  $line =~ /^\s*(#.*$)/ ){
         # pure comment lines
         output_line('',$1) if(  $PassNo);
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
         output_line('',q[''']) if( $PassNo);                # issue 79
         output_line('',$line,1) if(  $PassNo);              # issue 79
         while($line=<>){
             # issue 79 last if( $line eq '=cut');
            output_line('',$line,1) if(  $PassNo);  # issue 79
            if( substr($line,0,4) eq '=cut') {      # issue 79
                $line = <>;                         # issue 79
                last;
            }
         }
         # issue 79 output_line('',q['''']) if(  $PassNo);
         output_line('',q[''']) if(  $PassNo);      # issue 79
      }elsif( substr($line,0,5) eq 'goto ') {   # SNOOPYJC: strange way to skip some code
         $line =~ /goto\s+([A-Za-z0-9_]+)/;
         $label = $1;
         output_line('',q[''']) if( $PassNo);
         output_line('',$line,1) if( $PassNo);
         while($line=<>){
            output_line('', $line,1) if(  $PassNo);
            if( $line =~ /^$label:/ ) {
                $line = <>; 
                last;
            }
         }
         output_line('',q[''']) if(  $PassNo);
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
        next if($in_def);               # Refs inside of defs don't matter
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
    }
    say $out $line;
    $last_was_blank = $this_is_blank;
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
    my $as_what = '';
    my @imports = ();
    my %referenced_imports = ();
    my $import_as_referenced = 0;
    my $die_referenced = 0;
    my $eval_return_lno = 0;            # class $EVAL_RETURN_EXCEPTION(
    my $eval_referenced = 0;
    my $list_sep_lno = 0;
    my $list_sep_referenced = 0;
    my $script_start_lno = 0;
    my $script_start_referenced = 0;
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
        } elsif($line =~ /^class $EVAL_RETURN_EXCEPTION\(/) {
            $eval_return_lno = $lno;
        } elsif($line =~ /^LIST_SEPARATOR = /) {
            $list_sep_lno = $lno;
        } elsif($line =~ /^$SCRIPT_START = /) {
            $script_start_lno = $lno;   # doesn't count for $import_as_referenced
        } elsif($import_lno) {
            my @found = grep { $line =~ /\b$_\./ } @imports;
            foreach $f (@found) {
                $referenced_imports{$f} = 1;
            }
            if($line =~ /\b$as_what\./) {
                $import_as_referenced = 1;
                #say STDERR $line;
            } elsif($line =~ /\bLIST_SEPARATOR\b/) {
                $list_sep_referenced = 1;
            } elsif($line =~ /\bDie\b/) {
                $die_referenced = 1;
            } elsif($line =~ /\b$EVAL_RETURN_EXCEPTION\b/) {
                $eval_referenced = 1;
            } elsif($line =~ /\b$SCRIPT_START\b/ || $line =~ /\b_get[ACM]\b/) {
                $script_start_referenced = 1;
                $import_as_referenced = 1;      # yes, this references that!
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
        if($eval_return_lno && !$eval_referenced) {
            $line_ref->[$eval_return_lno-1] = '';   # class $EVAL_RETURN_EXCEPTION(Exception):
            $line_ref->[$eval_return_lno] = '';     #     pass
        }
        if($list_sep_lno && !$list_sep_referenced) {
            $line_ref->[$list_sep_lno-1] = '';
        }
        if($script_start_lno && !$script_start_referenced) {
            $line_ref->[$script_start_lno-1] = '';
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
