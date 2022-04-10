# issue s41 - Multi-variable split assignment with a bash style and/or generates syntax error code
use Carp::Assert;

sub _croak {
    require Carp;
    goto &Carp::croak;
}

$curdir = '.';

 ( $cur_dev, $cur_inode ) = ( stat $curdir )[ 0, 1 ]
          or _croak(
            "cannot stat prior working directory $data->{cwd}: $!, aborting."
          );

assert($cur_dev and $cur_inode);

$root = '.';
ROOT_DIR:
   for(my $i = 0; $i < 2; $i++) {
        my ( $ldev, $lino, $perm ) = ( lstat $root )[ 0, 1, 2 ]
          or next ROOT_DIR;
	assert($root eq '.');
        assert(defined $ldev);
        $root = 'no good';
   }

print "$0 - test passed!\n";
