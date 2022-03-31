#!/usr/bin/perl
# Importer for pythonizer: "require" the file given on the command line
# and write out the $VERSION, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, and @EXPORT_FAIL information
use v5.10;
no warnings;
#use strict 'subs';
#use Data::Dumper;
#

package Symbol::Get;    # Not a std package, so we include a heavily modified version here

my %_sigil_to_type = qw(
    $   SCALAR
    @   ARRAY
    %   HASH
    &   CODE
);

my $sigils_re_txt = join('|', keys %_sigil_to_type);

sub get {
    my ($var) = @_;

    die 'Need a variable or constant name!' if !length $var;

    my $sigil = substr($var, 0, 1);


    if($sigil =~ /^[A-Za-z_]/) {
        my $table_hr = _get_table_hr( $var );
        #say STDERR "for $var, ref table_hr=".ref $table_hr;
        if('CODE' eq ref $table_hr || 'SCALAR' eq ref $table_hr || 'ARRAY' eq ref $table_hr) {
            return undef;       # Need '&' for subref
        }

        if($table_hr && ref $table_hr eq '' && *{$table_hr}{IO}) {
            return $table_hr && *{$table_hr}{IO};
        }

        goto \&_get_constant;
    }
    #goto \&_get_constant if $sigil =~ tr<A-Za-z_><>;

    my $type = $_sigil_to_type{$sigil} or die "Unrecognized sigil: '$sigil'";

    my $table_hr = _get_table_hr( substr($var, 1) );
    #say STDERR "for $var, ref table_hr=".ref $table_hr;
    if('CODE' eq ref $table_hr || 'SCALAR' eq ref $table_hr) {
        return $table_hr if $sigil eq '&';
        return undef;
    } elsif(ref $table_hr ne '') {
        return undef;
    }
    return $table_hr && *{$table_hr}{$type};
}

sub _get_constant {
    my ($var) = @_;

    my $ref = _get_table_hr($var);

    if ('SCALAR' ne ref($ref) && 'ARRAY' ne ref($ref)) {
        return undef;
    }

    return $ref;
}

sub get_names {
    my ($module) = @_;

    $module ||= (caller 0)[0];

    #Call::Context::must_be_list();

    my $table_hr = _get_module_table_hr($module);

    die "Unknown namespace: '$module'" if !$table_hr;

    return keys %$table_hr;
}

sub _get_module_table_hr {
    my ($module) = @_;

    my @nodes = split m<::>, $module;

    my $table_hr = \%main::;

    my $pkg = q<>;

    for my $n (@nodes) {
        $table_hr = $table_hr->{"$n\::"};
        $pkg .= "$n\::";
    }

    return $table_hr;
}

sub _get_table_hr {
    my ($name) = @_;

    $name =~ m<\A (?: (.+) ::)? ([^:]+ (?: ::)?) \z>x or do {
        #die "Invalid variable name: '$name'";
        return undef;
    };

    my $module = $1 || (caller 1)[0];

    my $table_hr = _get_module_table_hr($module);

    return $table_hr->{$2};
}

package _pythonizer_importer;   # something other than what we're importing

use File::Basename;
use File::Spec::Functions qw(file_name_is_absolute catfile);	# issue bootstrap
BEGIN {
    use Config;
    unshift @INC, dirname(__FILE__);
    if(exists $ENV{PERL5PATH}) {
        my $sep = $Config{path_sep};
        $ENV{PERL5PATH} .= $sep . dirname(__FILE__);
    } else {
        $ENV{PERL5PATH} = dirname(__FILE__);
    }
}
use Pyconfig;

my $fullfile = shift;
my $debug = 0;

# issue bootstrap: we could be sent a relative path because the python version
# doesn't know the proper perl @INC, so check and make it absolute

if(file_name_is_absolute($fullfile)) {
    ;
} else {
    my $file = $fullfile;
    for my $place (@INC) {
        $fullfile = catfile($place, $file);
        if(-f $fullfile) {
	    last;
        } else {
	    $fullfile = $file;
        }
    }
}

my $dir = dirname($fullfile);
my $has_std = 0;
for my $d (@STANDARD_LIBRARY_DIRS) {
    if($dir =~ /$d/) {
        $has_std = 1;
        last;
    }
}
# don't add things like perl5/site_perl/Net/ to the path for Net::FTP
unshift @INC, $dir unless($has_std);

sub _gen_tags
{
	my $tag_ref = shift;
	my %tags = %$tag_ref;
	return '()' if(!%tags);

	my $result = '(';
	for my $key (keys %tags) {
		$result .= "$key => [qw/";
		$value = $tags{$key};
		$result .= "@$value";
		$result .= '/], ';
	}
	$result = substr($result,0,length($result)-2) . ')';
	return $result;
}

eval {
	local $SIG{__WARN__} = sub { };
        #say STDERR "fullfile=$fullfile, INC=@INC";
        package main;
        # NOTE: Be careful not to use any global variables in this code else they will appear to be
        # coming from the user's symbol table if they don't have a package declared.
        my @PREDEFS = qw/stdout STDOUT stderr STDERR stdin STDIN BEGIN INIT UNITCHECK CHECK END SIG ARGV INC _ ENV SRC/;
        my %PREDEFS = map { $_ => 1 } @PREDEFS;
	require $fullfile;
	open(SRC, '<', $fullfile);
        my $package = undef;
	my $in_pod = 0;
	my $CurSub = undef;
	my %wantarrays = ();
	while(<SRC>) {
	    if(substr($_,0,1) eq '=' && substr($_,1,1) =~ /\w/) {	# Skip POD
	        $in_pod = 1;
		next;
	    }
	    if($in_pod) {
	        $in_pod = 0 if(substr($_,0,4) eq '=cut');
		next;
	    }
	    next if(/^\s*#/);		# skip comment lines
	    s/\s+#.*$//;		# eat tail comments
	    last if(/^__DATA__/ || /^__END__/);
	    # FIXME: Eat strings, including '...', "...", q// s/// tr/// qw// qr// multi-line, etc
	    # FIXME: Eat here documents
	    if(/\bpackage\s+(.*);/) {
		$package = $1 unless defined $package;	# we just pick the first one
		#last;
	    } elsif(/\bsub\s+(\w+)/) {
		$CurSub = $1;
	    } elsif(/\bwantarray\b/) {
		$wantarrays{$CurSub} = 1 if defined $CurSub;
	    }
	}
	close(SRC);
	if(!defined $package) {
            #say '$package=undef;';
            #return 
            $package='main';
	}
	my %pkh = %{"${package}::"};
	#say STDERR keys %pkh;
	#say STDERR "Symbol table for $package: " . Dumper(\%pkh);
        #require Symbol::Get;            # Remove this package ref and inline it here!
        my @global_vars = ();
	my @overloads = ();		# issue s3
        for my $k (keys %pkh) {
            next if $k =~ /::$/;
	    if(substr($k,0,1) eq '(') {		# issue s3: key starting with '(' is an overload
		next if $k eq '((';		# not sure what this is
	        push @overloads, substr($k,1);
	    }
            next if $k !~ /^[A-Za-z_]/;
            next if $package eq 'main' && exists $PREDEFS{$k};
            #say STDERR "Checking $k";
            local *_tg = $pkh{$k};
            my $sc = Symbol::Get::get("\$${package}::$k");
            push @global_vars, "\$$k" if defined $_tg && defined $sc;
            my $ar = Symbol::Get::get("\@${package}::$k");
            push @global_vars, "\@$k" if defined $ar;
            my $ha = Symbol::Get::get("\%${package}::$k");
            push @global_vars, "\%$k" if defined $ha;
            my $co = Symbol::Get::get("\&${package}::$k");
            push @global_vars, "\&$k" if defined $co;
            my $fh = Symbol::Get::get("${package}::$k");
            push @global_vars, "$k" if defined $fh;
        }
	my @export = @{$pkh{EXPORT}} if exists($pkh{EXPORT});
	my @export_ok = @{$pkh{EXPORT_OK}} if exists($pkh{EXPORT_OK});
	my %export_tags = %{$pkh{EXPORT_TAGS}} if exists($pkh{EXPORT_TAGS});
	my $version = ${$pkh{VERSION}} if exists($pkh{VERSION});
	my @export_fail = @{$pkh{EXPORT_FAIL}} if exists($pkh{EXPORT_FAIL});
	my $has_export_fail_sub = (exists $pkh{export_fail}) ? 1 : 0;

	say '$package=' . "'$package';";
	say '$version=' . (defined $version ? "'$version';" : 'undef;');
	say '@export=' . (@export ? "qw/@export/;" : '();');
	say '@export_ok=' . (@export_ok ? "qw/@export_ok/;" : '();');
	say '%export_tags=' . &_pythonizer_importer::_gen_tags(\%export_tags) . ';';
	say '@export_fail=' . (@export_fail ? "qw/@export_fail/;" : '();');
	say "\$has_export_fail_sub=$has_export_fail_sub;";
        say '@global_vars=' . (@global_vars ? "qw/@global_vars/;" : '();');
        say '@overloads=' . (@overloads ? "qw'@overloads';" : '();');
	my @wantarrays = keys %wantarrays;
        say '@wantarrays=' . (@wantarrays ? "qw/@wantarrays/;" : '();');

	#say STDERR "expand_extras: package=$package, version=$version, export=@export, export_ok=@export_ok, export_tags=@{[%export_tags]}" if($debug);
};
if($@) {
	say '$@=' . "\"Failed: $@\";";
	exit(1);
}
