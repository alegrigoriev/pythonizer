#!/usr/bin/env python3
# Generated by "pythonizer -M -v0 ./A/B.pm" v1.030 run by joe on Wed Apr 19 10:00:48 2023
import builtins, perllib, sys, types
import A.B.A as _A_B_A

if "A.B" in sys.modules and hasattr(sys.modules["A.B"], "A"):
    delattr(sys.modules["A.B"], "A")

perllib.init_package("A.B", is_class=True)
# SKIPPED: use Carp::Assert;


def new(*_args):
    [class_] = perllib.list_of_n(_args, 1)
    return perllib.bless(perllib.Hash(), class_)


A.B.new = types.MethodType(new, A.B)


def hello(*_args):
    a_b_a = A.B.A.new()
    return a_b_a.hello()


A.B.hello = hello


def hello_b(*_args):
    perllib.import_(
        globals(), "A/B/A.pm"
    )  # to make sure this doesn't replace builtins.A with globals()['A']
    perllib.import_(globals(), "A/B/B.pm")
    a_b_b = A.B.B.new()
    return a_b_b.hello()


A.B.hello_b = hello_b

builtins.__PACKAGE__ = "A.B"

# SKIPPED: use strict;
perllib.WARNING = 1
