#!/usr/bin/env perl
# part of issue_s292: die with a signal
kill 'TERM', $$;
