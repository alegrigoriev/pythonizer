#!/usr/bin/env python3
# Generated by "pythonizer -M -v0 ./A/A.pm" v1.030 run by joe on Wed Apr 19 09:51:33 2023
import builtins, perllib, types

perllib.init_package("A.A", is_class=True)


def hello(*_args):
    return "Hello from A::A!"


A.A.hello = hello


def new(*_args):
    [class_] = perllib.list_of_n(_args, 1)
    return perllib.bless(perllib.Hash(), class_)


A.A.new = types.MethodType(new, A.A)
builtins.__PACKAGE__ = "A.A"

# SKIPPED: use strict;
perllib.WARNING = 1
