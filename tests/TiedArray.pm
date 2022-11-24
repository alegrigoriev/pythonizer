package TiedArray;
# Tied array implementation for test issue_s154
#
# This implementation ties the array to a file on disk, which is updated
# whenever the array is changed

# mandatory methods
sub TIEARRAY
{
    my $class = shift;
    my $filename = shift;

    my $data = [];
    my $fh;
    if(-f $filename) {
        open($fh, '+<', $filename) or return 0;
        my @lines = <$fh>;
        $data = \@lines;
    } else {
        open($fh, '>', $filename) or return 0;
    }
    bless {filename=>$filename, fh=>$fh, arr=>$data}, $class;
}

sub _upd {
# Update the file to synch with the array
    my $fh = $_[0]->{fh};
    seek $fh, 0, 0;
    truncate $fh, 0;
    foreach my $row (@{$_[0]->{arr}}) {
        print $fh "$row\n";
    }
}

sub FETCH { $_[0]->{arr}->[$_[1]] }
sub FETCHSIZE { scalar @{$_[0]->{arr}} }
sub length { $_[0]->FETCHSIZE() }
sub STORE { $_[0]->{arr}->[$_[1]] = $_[2]; _upd($_[0]); }
sub STORESIZE { $#{$_[0]->{arr}} = $_[1]-1; _upd($_[0]); }
sub EXISTS { exists $_[0]->{arr}->[$_[1]] }
sub DELETE { delete $_[0]->{arr}->[$_[1]] }

# optional methods - for efficiency
sub CLEAR { $_[0]->{arr} = (); _upd($_[0]) }
sub PUSH { my $arr = $_[0]->{arr}; push(@$arr, @_[1..$#_]); _upd($_[0]); }
sub POP { my $res = pop(@{$_[0]->{arr}}); _upd($_[0]); return $res; }
sub SHIFT { my $res = shift(@{$_[0]->{arr}}); _upd($_[0]); return $res;  }
sub UNSHIFT { my $arr = $_[0]->{arr}; unshift(@$arr, @_[1..$#_]); _upd($_[0]); }
# sub EXTEND { ... }
sub DESTROY { }
sub UNTIE { close($_[0]->{fh}) }
sub SPLICE
{
 my $ob  = shift;
 my $ar = $ob->{arr};
 my $sz  = $ob->FETCHSIZE;
 my $off = @_ ? shift : 0;
 $off   += $sz if $off < 0;
 my $len = @_ ? shift : $sz-$off;
 if(wantarray) {
    my @res = splice(@$ar,$off,$len,@_);
    _upd($ob);
    return @res;
 } else {
    my $res = splice(@$ar,$off,$len,@_);
    _upd($ob);
    return $res;
 }
}
1;
