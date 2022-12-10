package issue_s185m;
# sub-module of issue_s185 to test scalar reference out parameters from an OO module

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
    open(${$_[0]}, $_[1], $_[2]);
}

sub read_it {
    my $self = shift;
    my ($fh, $buf) = @_;
    read($fh, $$buf, 100);
}

sub one_out {
    my $self = shift;
    ${$_[0]} = 1;
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
    my $third = $_[0];
    $$third = 2;
    return 11;
}

sub two_in_outs {
    my $self = shift;
    my ($i, $j) = @_;
    ++$$i;
    $$j--;
    return 11;
}

sub one_multiple_out {
    shift(@_);
    my ($i) = @_;
    $$i = 1;
    $$i = 2 if($$i == 1);
    return 11;
}

sub var_args {
    shift;
    my $i = 0;
    ${$_[$i]} = 1;
    return 11;
}

sub var_args_pre {
    shift;
    my $i = 0;
    ++${$_[$i]};
}

sub chop_it {
    my $self = shift;
    my ($item) = @_;
    chop ( $$item );
}

sub chomp_it {
    my $self = shift;
    my $item = shift;
    chomp $$item;
}

# from CGI.pm (modified):
sub binmode {
    #return unless defined($_[1]) && ref ($_[1]) && defined fileno($_[1]);
    CORE::binmode(${$_[1]});
}

1;
