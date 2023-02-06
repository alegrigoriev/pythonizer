# Written by SNOOPYJC for Pythonizer
package Class::Struct;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(struct);

sub import
{
    my $class = $_[0];
    my $callpkg = caller;
    *{"$callpkg\::struct"} = \&struct;
    if(scalar(@_) > 2) {
        shift;
        goto &struct;
    }
}

sub struct
{
    my $base_type = (scalar(@_) >= 2 ? ref $_[1] : '');
    my ($package, @decls);
    if($base_type eq 'HASH') {
        $package = shift;
        @decls = %{$_[0]};
    } elsif($base_type eq 'ARRAY') {
        $package = shift;
        @decls = @{$_[0]};
    } else {
        $base_type = 'ARRAY';
        $package = caller;
        @decls = @_;
    }
    #print STDERR "base_type=$base_type, package=$package, decls=@decls\n";
    if($base_type eq 'HASH') {
        *{"$package\::new"} = sub { 
            my $class = (scalar(@_) ? shift : $package);
            my $self = bless {}, $class;
            my %args = @_;
            for (keys %args) {
                $self->{$_} = $args{$_}
            }
            return $self;
        };
    } else {
        my %ndx_map;
        for(my $i = 0; $i < scalar(@decls); $i+=2) {
            $ndx_map{$decls[$i]} = ($i >> 1);
        }
        %{"$package\::_ndx_map"} = %ndx_map;
        *{"$package\::new"} = sub { 
            my $class = (scalar(@_) ? shift : $package);
            my $self = bless [], $class;
            my %args = @_;
            for (keys %args) {
                $self->[${"$package\::_ndx_map"}{$_}] = $args{$_}
            }
            return $self;
        };
    }
    for(my $i = 0; $i < scalar(@decls); $i+=2) {
        my $key = $decls[$i];
        my $val = $decls[$i+1];
        #print STDERR "Handing $package $key => $val\n";
        if($val eq '$' || $val eq '*$') {
            if($base_type eq 'HASH') {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        if(scalar(@_)) {
                                            $self->{$key} = $_[0];
                                        }
                                        return $self->{$key};
                                        };
            } else {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        my $ndx = ${"$package\::_ndx_map"}{$key};
                                        if(scalar(@_)) {
                                            $self->[$ndx] = $_[0];
                                        }
                                        return $self->[$ndx];
                                        };
            }
        } elsif($val eq '@' || $val eq '*@') {
            if($base_type eq 'HASH') {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        if(scalar(@_)) {
                                            if(ref $_[0] eq 'ARRAY') {
                                                $self->{$key} = $_[0];
                                            } elsif(scalar(@_) == 1) {
                                                return $self->{$key}->[$_[0]];
                                            } else {
                                                $self->{$key}->[$_[0]] = $_[1];
                                                return $_[1];
                                            }
                                        }
                                        return $self->{$key};
                                     };
             } else {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        my $ndx = ${"$package\::_ndx_map"}{$key};
                                        if(scalar(@_)) {
                                            if(ref $_[0] eq 'ARRAY') {
                                                $self->[$ndx] = $_[0];
                                            } elsif(scalar(@_) == 1) {
                                                return $self->[$ndx]->[$_[0]];
                                            } else {
                                                $self->[$ndx]->[$_[0]] = $_[1];
                                                return $_[1];
                                            }
                                        }
                                        return $self->[$ndx];
                                     };
             }
        } elsif($val eq '%' || $val eq '*%') {
            if($base_type eq 'HASH') {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        if(scalar(@_)) {
                                            if(ref $_[0] eq 'HASH') {
                                                $self->{$key} = $_[0];
                                            } elsif(scalar(@_) == 1) {
                                                return $self->{$key}->{$_[0]};
                                            } else {
                                                $self->{$key}->{$_[0]} = $_[1];
                                                return $_[1];
                                            }
                                        }
                                        return $self->{$key};
                                        };
            } else {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        my $ndx = ${"$package\::_ndx_map"}{$key};
                                        if(scalar(@_)) {
                                            if(ref $_[0] eq 'HASH') {
                                                $self->[$ndx] = $_[0];
                                            } elsif(scalar(@_) == 1) {
                                                return $self->[$ndx]->{$_[0]};
                                            } else {
                                                $self->[$ndx]->{$_[0]} = $_[1];
                                                return $_[1];
                                            }
                                        }
                                        return $self->[$ndx];
                                        };
            }
        } else {
            if($base_type eq 'HASH') {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        if(scalar(@_)) {
                                            $self->{$key} = $_[0];
                                        }
                                        return $self->{$key};
                                        };
            } else {
                *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        my $ndx = ${"$package\::_ndx_map"}{$key};
                                        if(scalar(@_)) {
                                            $self->[$ndx] = $_[0];
                                        }
                                        return $self->[$ndx];
                                        };
            }
        }
    }
}
1;
