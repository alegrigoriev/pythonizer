# issue s158: ++ in , expression in or clause generates bad code
use Carp::Assert;

sub false { 0 }

sub bad {
    $bad = 1;
}

false()
        or ++$errors, bad();

assert($errors == 1);
assert($bad == 1);

$bad = 0;

false() or bad(), $errors++;

assert($errors == 2);
assert($bad == 1);

print "$0 - test passed!\n";
