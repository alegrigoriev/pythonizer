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
@EXPORT = qw(pass_0);

$say_why = 0;
@implied_options = ();

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

    while(1) {
        $line = &Pythonizer::getline();
        last unless(defined($line));

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
        if($#ValClass >= 3 && $ValClass[0] eq 'i' && $ValPerl[0] eq 'pragma' && $ValPerl[1] eq 'pythonizer') {
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
        say STDERR "Using -M: heuristics are indeterminate (lines in main: $lines_in_main, lines in subs: $lines_in_subs, global init lines: $global_init_lines)";
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
    my $VFlag = undef;
    my $implicit_global_my = undef;

    my %flags = (T=>\$::traceback, A=>\$::autodie, m=>\$mFlag, M=>\$MFlag, s=>\$::pythonize_standard_library,
                 S=>\$SFlag, p=>$::import_perllib, P=>\$PFlag, V=>\$VFlag);
    my %options = (traceback=>\$::traceback, autodie=>\$::autodie, implicit=>\$implicit_global_my,
                   pythonize=>\$::pythonize_standard_library, import=>\$::import_perllib, 
                   autovivification=>\$::autovivification);
    my %option_flags = (traceback=>'T', autodie=>'A', implicit=>'m',
                   pythonize=>'s', import=>'p');
    my %option_no_flags = (implicit=>'M', pythonize=>'S', import=>'P', autovivification=>'V');

    # pragma pythonizer -flags -moreflags
    # pragma pythonizer implicit global my, traceback, no import perllib

    for(my $i=2; $i <= $#ValClass; $i++) {
        if($ValClass[$i] eq 'i') {
            $vp = $ValPerl[$i];
            if($ValPerl[$i-1] eq '-') { # flags
                for my $flag (keys %flags) {
                    if($vp =~ /$flag/) {
                        ${$flags{$flag}} = 1;
                        push @implied_options, "-$flag";
                        say STDERR "Using -$flag due to pragma pythonizer -$vp" if($say_why);
                    }
                }
            } else {
                for my $option (keys %options) {
                    if($vp =~ /^$option$/i) {
                        if($ValPerl[$i-1] eq 'no') {
                            ${$options{$option}} = 0;
                            if(exists $option_no_flags{$option}) {
                                $flag = $option_no_flags{$option};
                                say STDERR "Using -$flag due to pragma pythonizer no $vp" if($say_why);
                                push @implied_options, "-$flag";
                            }
                        } else {
                            ${$options{$option}} = 1;
                            if(exists $option_flags{$option}) {
                                $flag = $option_flags{$option};
                                say STDERR "Using -$flag due to pragma pythonizer $vp" if($say_why);
                                push @implied_options, "-$flag";
                            }
                        }
                    }
                }
            }
        }
    }
    $::pythonize_standard_library = 0 if($SFlag);
    $::import_perllib = 0 if($PFlag);
    $::autovivification = 0 if($VFlag);
    return 1 if($mFlag);
    return 0 if($MFlag);
    return $implicit_global_my if(defined $implicit_global_my);
    return undef;
}

1;
