# part of issue s269 - naming a package 'yield' should generate an escaped name
package yield;

our $ran_import;

sub import {
    $ran_import = 1;
}
1;
