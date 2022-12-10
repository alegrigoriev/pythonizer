# issue s200 - naming variables the same as python imported packages causes problems
use Carp::Assert;
use Cwd;

#import sys,os,re,fcntl,math,fileinput,subprocess,collections.abc,argparse,glob,warnings,inspect,functools,itertools,signal,traceback,io,tempfile,atexit,calendar,types,pdb,random,stat,dataclasses,builtins,codecs,struct,$PERLLIB,copy,getopt
my ($sys, $os, $re, $fcntl, $math, $fileinput, $subprocess, $collections, $argparse, $glob, $warnings, $inspect, $functools, $itertools, $signal, $traceback, $io, $tempfile, $atexit, $calendar, $types, $pdb, $random, $stat, $dataclasses, $builtins, $codecs, $struct, $perllib, $copy, $getopt);
my ($time, $tm_py);

END {           # uses atexit
    print STDOUT "$0 - test passed!\n"; # uses sys
}

assert(cos(0) == 1);        # uses math
my $cwd = getcwd();         # uses os
sleep(0.1);                 # uses tm_py

my $re = "abc";
assert($re =~ /abc/);       # uses re
