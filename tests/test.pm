package test;
use Carp::Assert;
use Exporter 'import';
#use Data::Dumper;

our @EXPORT      = qw(done_testing);
our @EXPORT_OK   = qw(done_testing is like);
#our %EXPORT_TAGS = (all=>[qw(is like done_testing)]);
our %EXPORT_TAGS = (std=>[qw(done_testing)],xtra=>[qw(is like)]);
{               # Add 'all' tag with a summary of the other tags
    my %seen;

    push @{$EXPORT_TAGS{all}},
        grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
#print Dumper(\%EXPORT_TAGS) . "\n";

$VERSION = 1.00;

sub is
{
    assert($_[0] eq $_[1]);
}

sub like
{
    assert($_[0] =~ $_[1]);
}

sub done_testing
{
    print "$0 - test passed!\n";
}

done_testing() if !caller;
1;
