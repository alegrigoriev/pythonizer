#!/usr/bin/env python3
# Generated by "pythonizer -M -v0 A/B/B.pm" v1.030 run by joe on Wed Apr 19 10:00:51 2023
import builtins, perllib, types

perllib.init_package("A.B.B", is_class=True)


def hello(*_args):
    return "Hello from A::B::B!"


A.B.B.hello = hello


def new(*_args):
    [class_] = perllib.list_of_n(_args, 1)
    return perllib.bless(perllib.Hash(), class_)


A.B.B.new = types.MethodType(new, A.B.B)
builtins.__PACKAGE__ = "A.B.B"

# SKIPPED: use strict;
perllib.WARNING = 1
