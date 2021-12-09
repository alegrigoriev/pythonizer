use Carp::Assert;

package Response;
$default_response = 'failed';
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}
sub status_line {
    return $Response::default_response;
}

package main;

@files = ();
#$response = new Response();
$response = {status_line=>"failed"};
$f = 'f.py';
@arr = ('a', 'b', 'c');
$i = 1;
push @files,"myfile.py";
aeq(\@files, ["myfile.py"]);
push @files,$f;
aeq(\@files, ["myfile.py", 'f.py']);
#push @files,$response->status_line;
push @files,$response->{status_line};
aeq(\@files, ["myfile.py", 'f.py', 'failed']);
push @files,@arr;
aeq(\@files, ["myfile.py", 'f.py', 'failed', 'a', 'b', 'c']);
push @files,("file1", "file2");
aeq(\@files, ["myfile.py", 'f.py', 'failed', 'a', 'b', 'c', 'file1', 'file2']);
push @files,2;
aeq(\@files, ["myfile.py", 'f.py', 'failed', 'a', 'b', 'c', 'file1', 'file2', 2]);
push @files,-2;
aeq(\@files, ["myfile.py", 'f.py', 'failed', 'a', 'b', 'c', 'file1', 'file2', 2, -2]);
push @files,-$i;
aeq(\@files, ["myfile.py", 'f.py', 'failed', 'a', 'b', 'c', 'file1', 'file2', 2, -2, -1]);
push @files,myFunc();
aeq(\@files, ["myfile.py", 'f.py', 'failed', 'a', 'b', 'c', 'file1', 'file2', 2, -2, -1, 'fResult']);
push @files,myfile;
aeq(\@files, ["myfile.py", 'f.py', 'failed', 'a', 'b', 'c', 'file1', 'file2', 2, -2, -1, 'fResult', myfile]);
# Now for some more complicated LHS
%h = (a=>[]);
push @{%h{a}},"myfile.py";
aeq(\@{$h{a}}, ["myfile.py"]);
@a = ([]);
push @{$a[0]},"myfile";
aeq(\@{$a[0]}, ["myfile"]);
$href = {a=>[]};
push @{$href->{a}},"myfile.py";
aeq(\@{$href->{a}}, ["myfile.py"]);


# issue 38
@files = ();
unshift @files,"myfile.py";
aeq(\@files, ["myfile.py"]);
unshift @files,$f;
aeq(\@files, rev(["myfile.py", 'f.py']));
#unshift @files,$response->status_line;
unshift @files,$response->{status_line};
aeq(\@files, rev(["myfile.py", 'f.py', 'failed']));
unshift @files,@arr;
aeq(\@files, rev(["myfile.py", 'f.py', 'failed', 'c', 'b', 'a']));
unshift @files,("file1", "file2");
aeq(\@files, rev(["myfile.py", 'f.py', 'failed', 'c', 'b', 'a', 'file2', 'file1']));
unshift @files,2;
aeq(\@files, rev(["myfile.py", 'f.py', 'failed', 'c', 'b', 'a', 'file2', 'file1', 2]));
unshift @files,-2;
aeq(\@files, rev(["myfile.py", 'f.py', 'failed', 'c', 'b', 'a', 'file2', 'file1', 2, -2]));
unshift @files,-$i;
aeq(\@files, rev(["myfile.py", 'f.py', 'failed', 'c', 'b', 'a', 'file2', 'file1', 2, -2, -1]));
unshift @files,myFunc();
aeq(\@files, rev(["myfile.py", 'f.py', 'failed', 'c', 'b', 'a', 'file2', 'file1', 2, -2, -1, 'fResult']));
unshift @files,myfile;
aeq(\@files, rev(["myfile.py", 'f.py', 'failed', 'c', 'b', 'a', 'file2', 'file1', 2, -2, -1, 'fResult', myfile]));

%h = (a=>[]);
unshift @{%h{a}},"myfile.py";
aeq(\@{$h{a}}, ["myfile.py"]);
@a = ([]);
unshift @{$a[0]},"myfile";
aeq(\@{$a[0]}, ["myfile"]);
$href = {a=>[]};
unshift @{$href->{a}},"myfile.py";
aeq(\@{$href->{a}}, ["myfile.py"]);

print "$0 - test passed!\n";

sub myFunc {
    return 'fResult';
}

sub aeq {
    $a_ref1 = shift;
    $a_ref2 = shift;

    my ($package, $filename, $line) = caller;

    eval {
        assert(scalar(@$a_ref1) == scalar(@$a_ref2));
    };
    if($@) {
        say STDERR "scalar(\@\$a_ref1) != scalar(\@\$a_ref2), ".scalar(@$a_ref1)." != ".scalar(@$a_ref2);
        say STDERR "Assertion failed in aeq called from line $line";
        die($@);
    }
    for(my $i = 0; $i < scalar(@$a_ref1); $i++) {
        eval {
            assert($a_ref1->[$i] eq $a_ref2->[$i]);
        };
        if($@) {
            say STDERR "\$a_ref1->[$i] ne \$a_ref2->[$i], $a_ref1->[$i] ne $a_ref2->[$i]";
            say STDERR "Assertion failed in aeq called from line $line";
            die($@);
        }
    }
}

sub rev {
    $a_ref = shift;
    @result = reverse @$a_ref;
    return \@result;
}

