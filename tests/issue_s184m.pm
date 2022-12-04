package issue_s184m;
# sub-module of issue_s184 to test out parameters from an OO module

sub new {
    my $class = shift;
    bless {}, $class;
}

sub no_outs {
    my $self = shift;
    return 11;
}

sub open_it {
    my $self = shift;
    open($_[0], $_[1], $_[2]);
}

sub read_it {
    my $self = shift;
    read($_[0], $_[1], 100);
}

sub one_out {
    my $self = shift;
    $_[0] = 1;
    return 11;
}

# Make sure out parameters propagate
sub prop_it {
    my $self = shift;
    $self->one_out($_[0]);
    return 12;
}

sub prop_it_var {
    my $self = shift;
    my $i = 0;
    $self->one_out($_[$i]);
    return 13;
}

sub double_shift {
    my $self = shift;
    my $second = shift;
    $_[0] = 2;
    return 11;
}

sub two_in_outs {
    my $self = shift;
    ++$_[0];
    $_[1]--;
    return 11;
}

sub one_multiple_out {
    shift(@_);
    $_[0] = 1;
    $_[0] = 2 if($_[0] == 1);
    return 11;
}

sub var_args {
    shift;
    my $i = 0;
    $_[$i] = 1;
    return 11;
}

sub var_args_pre {
    shift;
    my $i = 0;
    ++$_[$i];
}

sub chop_it {
    my $self = shift;
    chop ( $_[0] );
}

sub chomp_it {
    my $self = shift;
    chomp($_[0]);
}

# from CGI.pm:
sub binmode {
    return unless defined($_[1]) && ref ($_[1]) && defined fileno($_[1]);
    CORE::binmode($_[1]);
}

1;
