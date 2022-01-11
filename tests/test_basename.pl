# Test for File::Basename, based on perl5/lib/File/Basename.t
use Carp::Assert;
use File::Basename;

#BEGIN {
#chdir 't' if -d 't';
#@INC = '../lib';
#}

#use Test::More;
#

#BEGIN { use_ok 'File::Basename' }

# import correctly?
#can_ok( __PACKAGE__, qw( basename fileparse dirname fileparse_set_fstype ) );

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

sub main
{

    ### Testing Unix
    {
        # We avoid this error in python by calling _str(None):
        #{
        #eval { fileparse(undef); 1 };
        #like($@, qr/need a valid path/,
        #"detect undef first argument to fileparse()");
        #}

        #ok length fileparse_set_fstype('unix'), 'set fstype to unix';
        #is( fileparse_set_fstype(), 'Unix',     'get fstype' );

        my($base,$path,$type) = fileparse('/virgil/aeneid/draft.book7',
                                          qr'\.book\d+');
        is($base, 'draft');
        is($path, '/virgil/aeneid/');
        is($type, '.book7');

        is(basename('/arma/virumque.cano'), 'virumque.cano');
        is(dirname ('/arma/virumque.cano'), '/arma');
        is(dirname('arma/'), '.');
    }



    ### extra tests for a few specific bugs
    {

        #fileparse_set_fstype 'UNIX';
        # perl5.003_18 gives '.'
        is(dirname('/perl/'), '/');
        # perl5.003_18 gives '/perl/lib'
        is(dirname('/perl/lib//'), '/perl');
    }

    ### rt.perl.org 22236
    {
        is(basename('a/'), 'a');
        is(basename('/usr/lib//'), 'lib');

    }


    ### rt.cpan.org 36477
    {
        #fileparse_set_fstype('Unix');
        is(dirname('/'), '/');
        is(basename('/'), '/');
    }


    ### basename(1) sez: "The suffix is not stripped if it is identical to the
    ### remaining characters in string"
    {
        #fileparse_set_fstype('Unix');
        is(basename('.foo'), '.foo');
        is(basename('.foo', '.foo'),     '.foo');
        is(basename('.foo.bar', '.foo'), '.foo.bar');
        is(basename('.foo.bar', '.bar'), '.foo');
    }

    done_testing();
}

main() if !caller;
1;
