# part of issue s269 - naming a package 'bytes' should generate an escaped name
package bytes;

our $ran_import;

sub import {
    $ran_import = 1;
}
1;
