#!/usr/bin/perl
# Importer for pythonizer: "require" the file given on the command line
# and write out the $VERSION, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, and @EXPORT_FAIL information
use v5.10;
no warnings;
use strict 'subs';
use File::Basename;
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

$fullfile = shift;

$dir = dirname($fullfile);
my $has_std = 0;
for my $d (@STANDARD_LIBRARY_DIRS) {
    if($dir =~ /$d/) {
        $has_std = 1;
        last;
    }
}
# don't add things like perl5/site_perl/Net/ to the path for Net::FTP
unshift @INC, $dir unless($has_std);

sub gen_tags
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
	require $fullfile;
	open(SRC, '<', $fullfile);
	while(<SRC>) {
	    if(/\bpackage\s+(.*);/) {
		$package = $1;
		last;
	    }
	}
	close(SRC);
	if(!defined $package) {
		say '$package=undef;';
		return 
	}
	my %pkh = %{"${package}::"};
	#say STDERR keys %pkh;
	@export = @{$pkh{EXPORT}} if exists($pkh{EXPORT});
	@export_ok = @{$pkh{EXPORT_OK}} if exists($pkh{EXPORT_OK});
	%export_tags = %{$pkh{EXPORT_TAGS}} if exists($pkh{EXPORT_TAGS});
	$version = ${$pkh{VERSION}} if exists($pkh{VERSION});
	@export_fail = @{$pkh{EXPORT_FAIL}} if exists($pkh{EXPORT_FAIL});
	$has_export_fail_sub = (exists $pkh{export_fail}) ? 1 : 0;

	say '$package=' . "'$package';";
	say '$version=' . (defined $version ? "'$version';" : 'undef;');
	say '@export=' . (@export ? "qw/@export/;" : '();');
	say '@export_ok=' . (@export_ok ? "qw/@export_ok/;" : '();');
	say '%export_tags=' . gen_tags(\%export_tags) . ';';
	say '@export_fail=' . (@export_fail ? "qw/@export_fail/;" : '();');
	say "\$has_export_fail_sub=$has_export_fail_sub;";
	#say STDERR "expand_extras: package=$package, version=$version, export=@export, export_ok=@export_ok, export_tags=@{[%export_tags]}" if($debug);
};
if($@) {
	say '$@=' . "\"Failed: $@\"";
	exit(1);
}
