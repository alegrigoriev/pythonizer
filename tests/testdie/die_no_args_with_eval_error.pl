#!/usr/bin/env perl
# part of issue_s292: die w/o args with eval_error
# If LIST was empty or made an empty string, and $@ already contains an exception value (typically from a previous eval), then that value is reused after appending "\t...propagated". This is useful for propagating exceptions
$@ = 'exception value';
die;
