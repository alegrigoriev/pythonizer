package Pass0;
#
## ABSTRACT: Initial source code scanner for pythonizer
## Reads thru and tokenizes the code and determines if this is
## a self-contained module or not.  If it's self-contained,
## it turns on the '-m' (make global variables into 'my' variables)
## which makes the generated python code easier to read, as
## global variables in python are file-scoped, where in perl they
## are truly global across files.
## Also handles "# pragma pythonizer -flags" and "# pragma pythonizer options"

use v5.10.1;
use warnings;
use strict 'subs';
use Perlscan qw(tokenize $TokenStr @ValClass @ValPerl @ValPy @ValType);
use Pyconfig;
use open qw(:std :utf8);
require Exporter;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw(pass_0 %line_no_convert_regex);

$say_why = 0;
@implied_options = ();
%line_no_convert_regex = ();

sub pass_0
{
    my $line;
    my $use_implicit_my = undef;
    my $looks_like_script = 0;
    my $CurSub = '__main__';
    my $lines_in_main = 0;
    my $lines_in_subs = 0;
    my $global_init_lines = 0;
    my %FileHandlesOpened = ();
    my %FileHandlesClosed = ();
    my %ConstantVars = ();

    $say_why = (&Softpano::get_verbosity() >= 1);
    $extra_info = (&Softpano::get_verbosity() >= 3);

    while(1) {
        $line = &Pythonizer::getline();
        last unless(defined($line));

        say STDERR "\n === Pass0: Line-$. Perl source:".$line."===" if($::debug >= 6);
        next if(defined $use_implicit_my);

        &Perlscan::tokenize($line);

        unless(defined($ValClass[0])){
             next;
        }
        #say STDERR "=|$TokenStr|= $line (@ValPerl)";

        if($CurSub eq '__main__') {
            $lines_in_main++;
            if($#ValClass >= 2 && $ValClass[0] =~ /[ahsG]/ && $ValClass[1] eq '=' &&
               is_constant_expr(2, $#ValClass, \%ConstantVars)) {
                $global_init_lines++;
                $ConstantVars{$ValPerl[0]} = 1;
            } elsif($ValClass[0] eq 'd') {
                $global_init_lines++;
            }
        } else {
            $lines_in_subs++;
        }
        if($#ValClass >= 2 && $ValClass[0] eq 'i' && $ValPerl[0] eq 'pragma' && $ValPerl[1] eq 'pythonizer') {
            my $uim = handle_pragma_pythonizer();
            $use_implicit_my = $uim if(defined $uim);
        } elsif($ValClass[0] eq 'c' && $ValPerl[0] eq 'package') {
            $use_implicit_my = 0;
            say STDERR "Using -M due to package" if($say_why);
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'sub') {
            $global_init_lines++;
            $CurSub = $ValPerl[1];
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'require' && $#ValClass >= 1) {
            if($ValClass[1] eq 's' || $ValClass[1] eq '"') {
                $use_implicit_my = 0;
                say STDERR "Using -M due to require" if($say_why);
            }
        } elsif($ValClass[0] eq 'k' && $ValPerl[0] eq 'return' && $CurSub eq '__main__' &&
                !&Perlscan::in_eval()) {
            $use_implicit_my = 0;   # will die if in a script
            say STDERR "Using -M due to return not in sub" if($say_why);
        } elsif(($ValClass[0] =~ m'[*@%&$]' || ($ValClass[0] eq 's' && $ValPerl[0] =~ m'^[*@%&$]$')) && 
                3 <= $#ValClass && $ValClass[1] eq '(' && 
                $ValPerl[1] eq '{' && contains_colon_colon(2, &Pythonizer::matching_br(1)-1)) { # issue s244
            $use_implicit_my = 0;           # issue s244
            say STDERR "Using -M due to dynamic package" if($say_why);  # issue s244
        } elsif($ValClass[0] eq '{') {
            &Pythonizer::correct_nest(1);
        } elsif($ValClass[0] eq '}' && $#ValClass == 0) {
            &Pythonizer::correct_nest(-1);
            if($CurSub ne '__main__' && $Pythonizer::NextNest == 0) {
                $CurSub = '__main__';
            }
        } elsif($ValClass[0] eq 'f' && $ValPerl[0] eq 'print' && $Pythonizer::NextNest == 0 &&
                (scalar(@ValClass) == 1 || (($fh=$ValPerl[1]) =~ /^STD/ || $ValClass[1] =~ /[s+"]/) ||
                ($ValClass[1] eq '(' && ($#ValClass >=2 && ($fh=$ValPerl[2]) =~ /^STD/ || $ValClass[2] =~ /[s+"]/)))) {
                my $conditional = 0;
                for(my $i = 2; $i <= $#ValClass; $i++) {
                    if($ValClass[$i] eq 'c') {
                        $conditional = 1;
                        last;
                    }
                }
                if(scalar(@ValClass) > 1 && $fh =~ /^STD/ && exists $FileHandlesOpened{$fh}) {
                    $conditional = 1;   # No good if they change STDxxx to some other file
                }
                $prints_to_stdout_stderr = 1 unless($conditional);
        } else {

            for(my $i = 0; $i <= $#ValClass; $i++) {
                if($ValClass[$i] eq 'k' && $ValPerl[$i] eq 'require' && $i+1 <= $#ValClass) {
                    if($ValClass[$i+1] eq 's' || $ValClass[$i+1] eq '"') {
                        $use_implicit_my = 0;
                        say STDERR "Using -M due to require" if($say_why);
                        last;
                    }
                } elsif($ValClass[$i] eq 'f' && $ValPerl[$i] eq 'GetOptions') {
                    $looks_like_script = 1;
                } elsif($ValClass[$i] eq 'f' && $ValPerl[$i] eq 'shift' &&
                        $CurSub eq '__main__' && $i == $#ValClass) {    # Shift of @ARGV
                    $looks_like_script = 1;
                } elsif($ValClass[$i] eq 'f' && $ValPerl[$i] eq 'open') {
                    if($ValClass[$i+1] eq 'i') {
                        $FileHandlesOpened{$ValPerl[$i+1]} = 1;
                    } elsif($ValClass[$i+1] eq '(' && $ValClass[$i+2] eq 'i') {
                        $FileHandlesOpened{$ValPerl[$i+2]} = 1;
                    }
                } elsif($ValClass[$i] eq 'f' && $ValPerl[$i] eq 'close') {
                    if($ValClass[$i+1] eq 'i') {
                        $FileHandlesClosed{$ValPerl[$i+1]} = 1;
                    } elsif($ValClass[$i+1] eq '(' && $ValClass[$i+2] eq 'i') {
                        $FileHandlesClosed{$ValPerl[$i+2]} = 1;
                    }
                } elsif($ValClass[$i] eq 's' && $ValPerl[$i] eq '$ARGV' &&
                        $i+1 <= $#ValClass && $ValPerl[$i+1] eq '[') {
                    $looks_like_script = 1;
                } elsif($ValClass[$i] eq 'a' && $ValPerl[$i] eq '@ARGV') {
                    $looks_like_script = 1;
                }
            }
        }
    }

    return $use_implicit_my if(defined $use_implicit_my);
    # example: cmt/dcEnding.pl has just "close LOG; exit;"
    for my $fh (keys %FileHandlesClosed) {
        if(!exists $FileHandlesOpened{$fh}) {
            $use_implicit_my = 0;
            say STDERR "Using -M due to close without open" if($say_why);
            last;
        }
    }
    return $use_implicit_my if(defined $use_implicit_my);

    # Apply heuristics at this point, leaning towards setting $use_implicit_my to 0:

    if(!$lines_in_main) {
        $use_implicit_my = 0;
        say STDERR "Using -M due to no lines in main" if($say_why);
    } elsif($global_init_lines == $lines_in_main) {
        $use_implicit_my = 0;
        say STDERR "Using -M due to all of the lines in main are static inits" if($say_why);
    } elsif($lines_in_main > 4 && $global_init_lines > $lines_in_main * 0.9) {
        # Over 90% of the code is static inits
        $use_implicit_my = 0;
        say STDERR "Using -M due to >= 90% of lines in main are static inits" if($say_why);
    } elsif($prints_to_stdout_stderr) {
        $use_implicit_my = 1;
        push @implied_options, '-m';
        say STDERR "Using -m due to unconditional print to STDOUT/STDERR" if($say_why);
    } elsif($looks_like_script) {    # Check this last
        $use_implicit_my = 1;
        push @implied_options, '-m';
        say STDERR "Using -m due to looks_like_script (GetOptions/ARGV)" if($say_why);
    }
    if($say_why and !defined $use_implicit_my) {
        if($extra_info) {
            say STDERR "Using -M: heuristics are indeterminate (lines in main: $lines_in_main, lines in subs: $lines_in_subs, global init lines: $global_init_lines)";
        } else {
            say STDERR "Using -M: heuristics are indeterminate";
        }
    }
    return $use_implicit_my;
}

sub is_constant_expr
# Return 1 if this is a constant expression
{
    my $start = shift;
    my $end_pos = shift;
    my $constant_vars = shift;

    for(my $i=$start; $i <= $end_pos; $i++) {
        $vc = $ValClass[$i];
        next if($vc eq '(' || $vc eq ')' || $vc eq ',' || $vc eq 'A');  # punctuation
        next if($vc eq '"' || $vc eq 'd' || $vc eq 'q');
        next if($vc eq 's' && exists $constant_vars->{$ValPerl[$i]});
        #say STDERR "is_constant_expr(=|$TokenStr|=) = 0";
        return 0;
    }
    #say STDERR "is_constant_expr(=|$TokenStr|=) = 1";
    return 1;
}

sub handle_pragma_pythonizer
# process the pragma pythonizer, setting appropriate global flags.  Returns the
# value of the -m/-M flag if any.
{
    my $mFlag = undef;
    my $MFlag = undef;
    my $SFlag = undef;
    my $PFlag = undef;
    my $NFlag = undef;                      # issue s132
    my $UFlag = undef;
    my $KFlag = undef;
    my $YFlag = undef;
    my $v0Flag = undef;
    my $v1Flag = undef;
    my $v2Flag = undef;
    my $v3Flag = undef;
    my $implicit_global_my = undef;

    my %flags = (T=>\$::traceback, A=>\$::autodie, m=>\$mFlag, M=>\$MFlag, s=>\$::pythonize_standard_library,
	    	     n=>\$::trace_run, k=>\$::black, K=>\$KFlag, u=>\$::replace_usage, U=>\$UFlag,
                 a=>\$::gen_author,	# issue s19
                 y=>\$::replace_run, Y=>\$YFlag,	# issue s87
                 e=>\$Pythonizer::e_option,         # issue s70
                 v0=>\$v0Flag, v1=>\$v1Flag, v2=>\$v2Flag, v3=>\$v3Flag,
                 S=>\$SFlag, p=>$::import_perllib, P=>\$PFlag, N=>\$NFlag);     # issue s132
    my %options = (traceback=>\$::traceback, autodie=>\$::autodie, implicit=>\$implicit_global_my,
                   pythonize=>\$::pythonize_standard_library, import=>\$::import_perllib, 
		           trace=>\$::trace_run, black=>\$::black, replace=>\$::replace_usage,
		           pl_to_py=>\$::replace_run,
		           author=>\$::gen_author,	# issue s19
                   verbose=>\$v2Flag,
                   verbosity=>\$v2Flag,
                   convert=>undef,              # issue s64
                   encoding=>\$Pythonizer::e_option,    # issue s70
                   autovivification=>\$::autovivification);

    my $set_option_from_flag = sub {            # issue bootstrap
        my ($flag, $val) = @_;
        if($flag eq 'T') {
            $::traceback = $val;
        } elsif($flag eq 'A') {
            $::autodie = $val;
        } elsif($flag eq 'a') {		# issue s19
            $::gen_author = $val;	# issue s19
        } elsif($flag eq 'e') {     # issue s70
            $Pythonizer::e_option = $val;   # issue s70
        } elsif($flag eq 'm') {
            $mFlag = $val;
        } elsif($flag eq 'M') {
            $MFlag = $val;
        } elsif($flag eq 's') {
            $::pythonize_standard_library = $val;
        } elsif($flag eq 'n') {
            $::trace_run = $val;
        } elsif($flag eq 'k') {
            $::black = $val;
        } elsif($flag eq 'K') {
            $KFlag = $val;
        } elsif($flag eq 'u') {
            $::replace_usage = $val;
        } elsif($flag eq 'U') {
            $UFlag = $val;
        } elsif($flag eq 'y') {		# issue s87
            $::replace_run = $val;	# issue s87
        } elsif($flag eq 'Y') {		# issue s87
            $YFlag = $val;		# issue s87
        } elsif($flag eq 'S') {
            $SFlag = $val;
        } elsif($flag eq 'p') {
            $::import_perllib = $val;
        } elsif($flag eq 'P') {
            $PFlag = $val;
        } elsif($flag eq 'N') {     # issue s132
            $NFlag = $val;          # issue s132
        } elsif($flag eq 'v0') {
            $v0Flag = $val;
        } elsif($flag eq 'v1') {
            $v1Flag = $val;
        } elsif($flag eq 'v2') {
            $v2Flag = $val;
        } elsif($flag eq 'v3') {
            $v3Flag = $val;
        }
    };

    my %option_flags = (traceback=>'T', autodie=>'A', implicit=>'m', trace=>'n', black=>'k',
	    	       author=>'a',		# issue s19
                   pl_to_py=>'y',	# issue s87
                   encoding=>'e',   # issue s70
                   verbose=>'v2', verbosity=>'v2',
                   pythonize=>'s', import=>'p', replace=>'u');
    my %option_no_flags = (implicit=>'M', pythonize=>'S', import=>'P', autovivification=>'N', black=>'K', replace=>'U', # issue s132
	    		   pl_to_py=>'Y',	# issue s87
                   verbose=>'v0', verbosity=>'v0',
    			   convert=>undef,	# issue s64 - use special processing
		   	  );
    my %flag_has_arg = (e=>1);            # issue s70

    # pragma pythonizer -flags -moreflags -e input_encoding,output_encoding
    # pragma pythonizer implicit global my, traceback, no import perllib, trace run, encoding input_encoding, output_encoding

    for(my $i=2; $i <= $#ValClass; $i++) {
        if($ValClass[$i] eq 'i') {
            $vp = $ValPerl[$i];
            if($ValPerl[$i-1] eq '-') { # flags
                for my $flag (keys %flags) {
                    if($vp =~ /$flag/) {
		                #${$flags{$flag}} = 1;
                        my $val = 1;                        # issue s70
                        if(exists $flag_has_arg{$flag}) {   # issue s70
                            $val = get_arg($i);      # Modifies $i
                            say STDERR "Using -$flag $val due to pragma pythonizer -$vp $val" if($say_why);
                            push @implied_options, "-$flag", $val;
                        } else {
                            say STDERR "Using -$flag due to pragma pythonizer -$vp" if($say_why);
                            push @implied_options, "-$flag";
                        }
			            &$set_option_from_flag($flag, $val);    # issue s70
                    }
                }
            } else {
                for my $option (keys %options) {
                    if($vp =~ /^$option$/i) {
                        if($ValPerl[$i-1] eq 'no') {
			                #${$options{$option}} = 0;
                            if(exists $option_no_flags{$option}) {
                                $flag = $option_no_flags{$option};
                                if(defined $flag) {
				                    &$set_option_from_flag($flag, 1);
                                    say STDERR "Using -$flag due to pragma pythonizer no $vp" if($say_why);
                                    push @implied_options, "-$flag";
                                } else {        # issue s64: special processing
                                    $line_no_convert_regex{$. + 1} = 1;
                                    say STDERR "Not converting perl to python regex on line " . ($.+1) . " due to pragma pythonizer" if($say_why)
                                }
                            }
                        } else {
			                #${$options{$option}} = 1;
                            if(exists $option_flags{$option}) {
                                $flag = $option_flags{$option};
                                my $val = 1;                        # issue s70
                                if(exists $flag_has_arg{$flag}) {   # issue s70
                                    $val = get_arg($i);      # Modifies $i
                                    say STDERR "Using -$flag $val due to pragma pythonizer $vp $val" if($say_why);
                                    push @implied_options, "-$flag", $val;
                                } else {
                                    say STDERR "Using -$flag due to pragma pythonizer $vp" if($say_why);
                                    push @implied_options, "-$flag";
                                }
                                &$set_option_from_flag($flag, $val);    # issue s70
                            }
                        }
                    }
                }
            }
        }
    }
    $::pythonize_standard_library = 0 if($SFlag);
    $::import_perllib = 0 if($PFlag);
    $::autovivification = 0 if($NFlag);     # issue s132
    $::replace_usage = 0 if($UFlag);
    $::replace_run = 0 if($YFlag);	# issue s87
    $::black = 0 if($KFlag);
    &Softpano::set_verbosity(0) if($v0Flag);
    &Softpano::set_verbosity(1) if($v1Flag);
    &Softpano::set_verbosity(2) if($v2Flag);
    &Softpano::set_verbosity(3) if($v3Flag);
    return 1 if($mFlag);
    return 0 if($MFlag);
    return $implicit_global_my if(defined $implicit_global_my);
    return undef;
}

sub get_arg         # issue s70
# Get argument from option or flag
# arg: $i = position of flag or option - gets updated to point to the last argument
# returns: the argument as a string value
{
    my $pos = $_[0];
    my $i = $pos+1;
    my $result = '';
    for(; $i <= $#ValClass; $i++) {
        if($ValClass[$i] eq 'i') {
            last if($result && $result !~ /,$/);    # Get out if this is the next option
            $result .= $ValPy[$i];
        } elsif($ValClass[$i] eq '-') {     # e.g. cp-1252 gets split into cp(i), -(-), 1252(d)
            $result .= '-';
        } elsif($ValClass[$i] eq 'd') {
            $result .= $ValPy[$i];
        } elsif($ValClass[$i] eq ',') {
            $result .= ',';
        } else {
            last;
        }
    }

    $_[0] = $i-1;           # Update the loop counter in the caller
    say STDERR "get_arg($pos) = '$result' and updates $pos to $_[0]" if $::debug >= 6;
    return $result;
}

sub contains_colon_colon        # issue s244
# Do these tokens contain a string with '::' in it?
{
    my ($pos, $end_pos) = @_;

    for(; $pos <= $end_pos; $pos++) {
        return 1 if($ValClass[$pos] eq '"' && index($ValPy[$pos], '::') != -1);
    }
    return 0;
}

1;
