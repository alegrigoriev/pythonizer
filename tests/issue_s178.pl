package s178;
# issue s178 - Reference to CORE::print is not translated properly

sub new {
    bless {}, shift;
}

sub print {
    shift;
    CORE::print(@_);
}

my $s178 = new s178;
$s178->print($0, " - test passed!\n");
