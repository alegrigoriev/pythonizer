# issue s201 - Method call with expanded hash generates bad code
# issue s202 - [arrayfunc] incorrectly generates an array with an array in it
# issue s203 - $self->PACKAGE::subname(...) generates incorrect code
package CGI;
use Carp::Assert;

sub new {
    bless {}, shift;
}

# issue 203 details:
# from ChatGPT (https://chat.openai.com/chat):
# In Perl, $self->subname and $self->MYPACKAGE::subname are not the same. In the first example, subname is a method that is defined in the current package and can be called on the object referenced by $self. In the second example, subname is a method that is defined in the MYPACKAGE package, and it is being called on the object referenced by $self.
#
# In Perl, the -> operator is used to call methods on objects. When you call a method on an object, the method is looked up in the package that the object's class belongs to. If the method is not found in that package, the package's @ISA array is checked to see if the method is defined in a parent package. This continues until the method is found or the search reaches the top of the inheritance tree.
#
# So, in the first example, the subname method will be looked up in the current package and called on the object referenced by $self. In the second example, the subname method will be looked up in the MYPACKAGE package and called on the object referenced by $self. This is different from the first example because the method is being looked up in a different package.
#
# It is worth noting that using fully qualified method names like $self->MYPACKAGE::subname is not very common in Perl, and it is generally considered better style to use the unqualified method name $self->subname and let the inheritance mechanism handle the rest. However, there may be some cases where using a fully qualified method name is necessary, such as when you want to call a method defined in a parent package that has been overridden in the current package.
# 

sub get_fields {
    my($self) = @_;
    return $self->CGI::hidden('-name'=>'.cgifields',
		      '-values'=>[sort keys %{$self->{'.parametersToAdd'}}],
		      '-override'=>1);
}

sub hidden {
    my($self, %h) = self_or_default(@_);
    #print "@p\n";
    #%h = @p;
    assert($h{'-name'} eq '.cgifields');
    assert($h{'-values'}->[0] eq 'p1');
    assert($h{'-override'} == 1);
}

sub self_or_default {
    return @_;
}

my $p = new CGI;
$p->{'.parametersToAdd'} = {p1=>v1};
$p->get_fields();
print "$0 - test passed!\n";
