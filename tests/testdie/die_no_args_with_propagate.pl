#!/usr/bin/env perl
# part of issue_s292: die w/o args with eval_error
# If LIST was empty or made an empty string, and $@ contains an object reference that has a PROPAGATE method, that method will be called with additional file and line number parameters. The return value replaces the value in $@; i.e., as if $@ = eval { $@->PROPAGATE(__FILE__, __LINE__) }; were called.
package Class;
sub new { bless {}, shift }
sub PROPAGATE {
    my $self = shift;
    my ($file, $lno) = @_;
    return "PROPAGATE($file, $lno)";
}

package main;
$obj = new Class;
$@ = $obj;
die;
